// work_lesson_screen.dart — a lesson worked in steps (money, the tables, division): Penko tells a short story, then
// the student works it out step by step, typing each number on a number pad. A division is drawn as "la casita". Solved steps stay on a little "cuenta" card so the reasoning
// is visible. A wrong amount gets a soft amber "casi"; hints come one at a time and never cost anything.
import 'dart:math';

import 'package:flutter/material.dart';

import '../ai/tutor.dart';
import '../art/palette.dart';
import '../art/penko.dart';
import '../audio/speech.dart';
import '../data/progress.dart';
import '../data/settings.dart';
import '../glossary/glossary_screen.dart';
import '../glossary/term_text.dart';
import '../i18n/lang.dart';
import '../math/explain.dart' show spoken;
import '../money/money.dart';
import '../money/money_lessons.dart';
import '../ui/casita_view.dart';
import '../ui/pixel_ui.dart';
import '../ui/thinking.dart';
import '../ui/money_pile.dart';
import '../ui/why_sheet.dart';
import '../wayfinding/wayfinding.dart';
import 'course.dart';

class WorkLessonScreen extends StatefulWidget {
  final WorkLesson lesson;
  final int? seed;
  const WorkLessonScreen({super.key, required this.lesson, this.seed});

  @override
  State<WorkLessonScreen> createState() => _WorkLessonScreenState();
}

class _WorkLessonScreenState extends State<WorkLessonScreen> {
  late final Random _rng = Random(widget.seed);
  int _intro = 0;
  bool _inIntro = true;
  int _number = 0;
  late WorkProblem _problem;
  int _step = 0;
  String _typed = '';
  int _misses = 0;
  int _hint = 0;
  bool _helped = false; // asked "¿por qué?" on this step
  int _steps = 0, _firstRight = 0; // steps done, and those right at the first try with no help
  bool _amber = false;
  bool _solved = false; // the whole problem
  bool _finished = false;
  String _line = '';
  bool _tutor = false; // the "¿Por qué?" button: only on phones that can run the tutor model
  bool _thinking = false;

  WorkLesson get _lesson => widget.lesson;
  late final Color _colour = unitOfLesson(_lesson.id)?.color ?? Pk.gold; // its unit's colour, like a Metro line's

  /// What the "read this screen" button reads: the lesson, Penko's line, the story, the steps solved so far and the
  /// number being typed
  List<String> _readLines() => [
    _lesson.title,
    if (!_thinking) _line,
    if (!_inIntro && !_finished) ...[
      _problem.story,
      for (var i = 0; i < _step + (_solved ? 1 : 0); i++) _problem.steps[i].done,
      if (_typed.isNotEmpty) _lesson.pesos ? pesos(double.parse(_typed)) : _typed,
    ],
  ];

  /// The story's main amount, in whole pesos (the first one without centavos), to show it as money
  double? get _storyAmount {
    for (final m in RegExp(r'\$(\d[\d,]*)(\.\d+)?').allMatches(_problem.story)) {
      if (m[2] == null) return double.parse(m[1]!.replaceAll(',', ''));
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _say(_lesson.intro.first);
    Tutor.instance.available().then((v) {
      if (mounted) setState(() => _tutor = v);
      if (v) Tutor.instance.warmUp(); // so "¿Por qué?" answers sooner
    });
  }

  @override
  void dispose() {
    Tutor.instance.cancel();
    Speech.instance.stop();
    super.dispose();
  }

  void _say(String line) {
    _line = line;
    if (Settings.voice.value) Speech.instance.say(spoken(line));
  }

  void _newProblem() {
    _problem = _lesson.make(_rng);
    _step = 0;
    _solved = false;
    _startStep(withStory: true);
  }

  void _startStep({bool withStory = false}) {
    _typed = '';
    _misses = 0;
    _hint = 0;
    _helped = false;
    _amber = false;
    final ask = _problem.steps[_step].ask;
    _say(withStory ? '${_problem.story} $ask' : ask);
  }

  void _continue() {
    if (_finished) {
      Navigator.of(context).pop();
    } else if (_inIntro) {
      if (_intro + 1 < _lesson.intro.length) {
        _intro++;
        _say(_lesson.intro[_intro]);
      } else {
        _inIntro = false;
        _newProblem();
      }
    } else if (_solved) {
      if (_number + 1 < _lesson.count) {
        _number++;
        _newProblem();
      } else {
        _finished = true;
        Progress.finish(_lesson.id, firstTry: _steps > 0 ? _firstRight / _steps : null);
        _say(tr('¡Terminaste la lección! Ahora ya sabes sacar estas cuentas.', 'You finished the lesson! Now you know how to work these out.'));
      }
    }
    setState(() {});
  }

  void _key(String k) {
    if (_solved) return;
    setState(() {
      _amber = false;
      if (k == '⌫') {
        if (_typed.isNotEmpty) _typed = _typed.substring(0, _typed.length - 1);
      } else if (_typed.length < 7) {
        _typed = _typed == '0' ? k : _typed + k;
      }
    });
  }

  void _check() {
    if (_typed.isEmpty || _solved) return;
    final step = _problem.steps[_step];
    final value = int.parse(_typed);
    if (value == step.answer) {
      _steps++;
      if (_misses == 0 && _hint == 0 && !_helped) _firstRight++;
      if (_step + 1 < _problem.steps.length) {
        _step++;
        _startStep();
      } else {
        _solved = true;
        _say('${tr('¡Muy bien!', 'Well done!')} ${_problem.lesson}');
      }
    } else {
      _misses++;
      _amber = true;
      final tens = value * 10 == step.answer || value == step.answer * 10;
      var line = tens ? tr('Casi: revisa los ceros.', 'Almost: check the zeros.') : tr('Casi. Revísalo otra vez.', 'Almost. Check it once more.');
      if (_misses >= 2 && _hint < step.hints.length) line += ' ${step.hints[_hint++]}';
      _say(line);
    }
    setState(() {});
  }

  /// "¿Por qué?": the student picks a question; the tutor answers with the story, the steps already solved and the
  /// first hint as facts. It must not give the answer away; if its reply doesn't pass, Penko answers in her own words.
  Future<void> _why() async {
    final problem = _problem, step = _problem.steps[_step];
    // Shown in the app's language; the tutor model is asked them in Spanish, as it was trained
    List<String> ask() => [
      tr('¿Por qué se calcula así?', 'Why is it worked out this way?'),
      tr('¿Para qué me sirve saber esto?', 'What is this useful for?'),
      tr('Dame un ejemplo más fácil, por favor.', 'Please give me an easier example.'),
    ];
    final questions = ask(), forModel = Lang.spanish(ask);
    final pick = await askWhich(context, questions);
    if (pick == null || !mounted || problem != _problem || step != _problem.steps[_step]) return;
    _helped = true;
    final facts = [
      _problem.story,
      for (var i = 0; i < _step; i++) _problem.steps[i].done,
      'Cómo se piensa este paso: ${step.hints.first}', // for the model, in Spanish (the story is in the app's language)
    ].join('\n');
    final fallback = [step.hints.first, _lesson.intro.last, step.hints.first][pick];
    setState(() => _thinking = true);
    _say(tr('Déjame pensar.', 'Let me think.')); // heard with the voice on; the bubble shows the dots
    final reply = await Tutor.instance
        .explain(facts: facts, question: '${step.ask} ${forModel[pick]}', forbidden: {step.answer.toDouble()})
        .timeout(const Duration(seconds: 60), onTimeout: () {
      Tutor.instance.cancel();
      return null;
    });
    if (!mounted || problem != _problem || step != _problem.steps[_step]) return;
    setState(() {
      _thinking = false;
      _say(reply ?? fallback);
    });
  }

  void _showHint() {
    final hints = _problem.steps[_step].hints;
    // The last hint gives the answer away: only after a real try
    if (_hint == hints.length - 1 && _misses == 0) {
      setState(() => _say(tr('Primero inténtalo tú. Si no sale, te ayudo con la cuenta.', "Try it yourself first. If it doesn't work out, I'll help you with the sum.")));
      return;
    }
    if (_hint < hints.length) setState(() => _say(hints[_hint++]));
  }

  @override
  Widget build(BuildContext context) {
    final working = !_inIntro && !_finished && !_solved;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Pk.textSoft),
                    tooltip: tr('Salir', 'Leave'),
                  ),
                  LessonSign(id: _lesson.id, title: _lesson.title, colour: _colour),
                  Expanded(
                    child: Text(_lesson.title,
                        style: TextStyle(fontFamily: pixelFont, fontSize: 18, color: _colour)),
                  ),
                  if (!_inIntro && !_finished)
                    Text('${_number + 1} / ${_lesson.count}', style: const TextStyle(color: Pk.textSoft, fontSize: 16)),
                  IconButton(
                    onPressed: () => openGlossary(context),
                    icon: const Icon(Icons.menu_book_outlined, color: Pk.gold),
                    tooltip: tr('Palabras', 'Words'),
                  ),
                  ReadScreenButton(lines: _readLines),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Speech.instance.say(spoken(_line)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Penko(pose: _solved || _finished ? PenkoPose.jump : PenkoPose.idle, size: 64),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                        decoration: BoxDecoration(
                          color: _amber ? Pk.wrongSoft : Pk.dialog,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _amber ? Pk.wrong : Colors.transparent, width: 2.5),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _thinking
                                  ? const ThinkingLine()
                                  : TermText(_line,
                                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.3,
                                          color: _amber ? Pk.wrongText : Pk.onDialog)),
                            ),
                            Icon(Icons.volume_up, size: 22, color: _amber ? Pk.wrongText : Pk.onDialog),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!_thinking) LinePictures(_line),
              const SizedBox(height: 12),
              // The worked steps so far: the reasoning stays on screen
              Expanded(
                child: _inIntro || _finished
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // What this lesson is about, in a picture, for anyone who can't follow the words
                            if (_inIntro && lessonPictures[_lesson.id] != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: PictogramTile(lessonPictures[_lesson.id]!, size: 128, frame: _colour, moves: true),
                              ),
                            Penko(pose: _finished ? PenkoPose.jump : PenkoPose.talk, size: _inIntro ? 88 : 120),
                          ],
                        ),
                      )
                    : ListView(
                        children: [
                          if (_problem.division != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: CasitaView(division: _problem.division!, solved: _step + (_solved ? 1 : 0)),
                            ),
                          PkPanel(
                            color: Pk.note,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // The story stays in view while Penko asks each step
                                TermText(_problem.story, style: const TextStyle(fontSize: 15, color: Pk.textSoft, height: 1.3)),
                                // In the money lessons, the story's amount as coins and bills
                                if (_lesson.pesos && _storyAmount != null)
                                  Padding(padding: const EdgeInsets.only(top: 8), child: MoneyPile(_storyAmount!, height: 30)),
                                const SizedBox(height: 10),
                                Text(tr('Tu cuenta', 'Your working'), style: const TextStyle(color: Pk.gold, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                for (var i = 0; i < _step + (_solved ? 1 : 0); i++)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: Pk.right, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TermText(_problem.steps[i].done,
                                              style: const TextStyle(fontSize: 17, color: Pk.text)),
                                        ),
                                      ],
                                    ),
                                  ),
                                // Solved: the answer as money too
                                if (_lesson.pesos && _solved)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10, left: 28),
                                    child: MoneyPile(_problem.steps.last.answer.toDouble(), height: 30),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 8),
              if (working) ...[
                // What the student is typing: always in view, just above the pad
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    _lesson.pesos ? (_typed.isEmpty ? '\$ …' : pesos(double.parse(_typed))) : (_typed.isEmpty ? '…' : _typed),
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: _amber ? Pk.wrongText : Pk.text),
                  ),
                ),
                _Pad(onKey: _key),
                const SizedBox(height: 8),
                // Help on one row, Listo on its own: three buttons side by side don't fit with big text
                Row(
                  children: [
                    Expanded(
                      child: PkButton(tr('Pista', 'Hint'), color: Pk.note, textColor: Pk.gold,
                          leading: const Icon(Icons.lightbulb_outline, color: Pk.gold),
                          onPressed: _hint < _problem.steps[_step].hints.length && !_thinking ? _showHint : null),
                    ),
                    if (_tutor) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: PkButton(tr('¿Por qué?', 'Why?'), color: Pk.note, textColor: Pk.gold,
                            leading: const Icon(Icons.psychology_alt_outlined, color: Pk.gold),
                            onPressed: _thinking ? null : _why),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                PkButton(tr('Listo', 'Done'), leading: const Icon(Icons.check, color: Pk.onGold), onPressed: _typed.isEmpty ? null : _check),
              ] else
                PkButton(_finished ? tr('Volver', 'Back') : tr('Continuar', 'Continue'),
                    leading: Icon(_finished ? Icons.home : Icons.arrow_forward, color: Pk.onGold), onPressed: _continue),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pad extends StatelessWidget {
  final void Function(String) onKey;
  const _Pad({required this.onKey});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final row in const [
        ['1', '2', '3', '4', '5', '6'],
        ['7', '8', '9', '0', '00', '⌫'],
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              for (final k in row)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Material(
                      color: Pk.cardHi,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Pk.rim.withValues(alpha: 0.6)),
                      ),
                      child: InkWell(
                        key: ValueKey('key-$k'),
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          for (final c in k == '00' ? ['0', '0'] : [k]) {
                            onKey(c);
                          }
                        },
                        child: SizedBox(
                          height: 52,
                          child: Center(
                            child: k == '⌫'
                                ? Icon(Icons.backspace_outlined, color: Pk.text, semanticLabel: tr('Borrar', 'Delete'))
                                : Text(k, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Pk.text)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
    ],
  );
}
