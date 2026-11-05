// lesson_screen.dart — one lesson: Penko's intro, a worked example she does step by step, then problems the
// student works column by column on a number pad. Right digits go green; a digit that isn't right turns the cell
// soft amber and Penko names the likely slip. Hints come one at a time, and never cost anything.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ai/facts.dart';
import '../ai/tutor.dart';
import '../art/palette.dart';
import '../art/penko.dart';
import '../audio/speech.dart';
import '../data/progress.dart';
import '../data/settings.dart';
import '../glossary/glossary_screen.dart';
import '../glossary/term_text.dart';
import '../i18n/lang.dart';
import '../math/column.dart';
import '../math/explain.dart';
import '../math/lessons.dart';
import '../math/problems.dart';
import '../ui/column_view.dart';
import '../ui/pixel_ui.dart';
import '../ui/thinking.dart';
import '../ui/why_sheet.dart';
import '../wayfinding/wayfinding.dart';
import 'course.dart';

enum _Phase { intro, example, practice, done }

class LessonScreen extends StatefulWidget {
  final Lesson lesson;
  final int? seed; // fixed problems for tests
  const LessonScreen({super.key, required this.lesson, this.seed});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late final Random _rng = Random(widget.seed);
  _Phase _phase = _Phase.intro;
  int _introLine = 0;

  late ColumnProblem _problem;
  int _number = 0; // practice problem index
  int _stepIndex = 0; // index into _problem.writable
  late List<int?> _written;
  final Set<int> _marked = {};
  String _line = '';
  bool _flash = false;
  int _misses = 0; // on this step
  int _hint = 0; // hints shown on this step
  bool _helped = false; // asked "¿por qué?" on this step
  int _steps = 0, _firstRight = 0; // practice digits written, and those right at the first try with no help
  bool _solved = false;
  bool _tutor = false; // the "¿Por qué?" button: only on phones that can run the tutor model
  bool _thinking = false;

  Lesson get _lesson => widget.lesson;
  late final Color _colour = unitOfLesson(_lesson.id)?.color ?? Pk.gold; // its unit's colour, like a Metro line's

  /// What the "read this screen" button reads: the lesson, Penko's line, and the sum being worked
  List<String> _readLines() => [
    _lesson.title,
    _line,
    if (_phase == _Phase.example || _phase == _Phase.practice) '${_problem.a} ${_problem.symbol} ${_problem.b}',
  ];
  bool get _guided => _phase == _Phase.example || _number < _lesson.guided;
  ColumnStep get _step => _problem.writable[_stepIndex];

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
    setState(() => _line = line);
    if (Settings.voice.value) Speech.instance.say(spoken(line));
  }

  void _load(ColumnProblem p) {
    _problem = p;
    _stepIndex = 0;
    _written = List.filled(p.columns, null);
    _marked.clear();
    _solved = false;
    _startStep();
  }

  void _startStep() {
    _misses = 0;
    _hint = 0;
    _helped = false;
    _flash = false;
    // Guided: the borrow marks appear as Penko explains them; on their own the student decides
    if (_guided && _problem.op == Op.sub && _step.borrows) _marked.add(_step.place);
    _say(askStep(_problem, _step, guided: _guided));
  }

  void _next() {
    switch (_phase) {
      case _Phase.intro:
        if (_introLine + 1 < _lesson.intro.length) {
          _introLine++;
          _say(_lesson.intro[_introLine]);
        } else {
          _phase = _Phase.example;
          _load(_lesson.example);
        }
      case _Phase.example:
        // Penko writes the digit herself
        if (!_solved) {
          _right(_step.digit);
        } else {
          _phase = _Phase.practice;
          _number = 0;
          _say(tr('¡Ahora tú!', 'Your turn!'));
          Future.delayed(const Duration(milliseconds: 900), () {
            if (mounted && _phase == _Phase.practice) _load(makeProblem(_lesson.spec, _rng));
          });
        }
      case _Phase.practice:
        if (_number + 1 < _lesson.count) {
          _number++;
          _load(makeProblem(_lesson.spec, _rng));
        } else {
          _phase = _Phase.done;
          Progress.finish(_lesson.id, firstTry: _steps > 0 ? _firstRight / _steps : null);
          _say(tr('¡Terminaste la lección! Muy buen trabajo.', 'You finished the lesson! Great work.'));
        }
      case _Phase.done:
        Navigator.of(context).pop(true);
    }
    setState(() {});
  }

  void _type(int digit) {
    if (_phase != _Phase.practice || _solved) return;
    if (digit == _step.digit) {
      _right(digit);
    } else {
      HapticFeedback.selectionClick();
      _misses++;
      _flash = true;
      final slip = _problem.diagnose(_step, digit);
      // After two misses, the slip line comes with the first hint
      final extra = _misses >= 2 && _hint == 0 ? ' ${hints(_problem, _step)[_hint++]}' : '';
      _say(slipLine(_problem, _step, slip) + extra);
    }
  }

  void _right(int digit) {
    final s = _step;
    if (_phase == _Phase.practice) {
      _steps++;
      if (_misses == 0 && _hint == 0 && !_helped) _firstRight++;
    }
    _written[s.place] = digit;
    _marked.add(s.place);
    _flash = false;
    if (_stepIndex + 1 < _problem.writable.length) {
      _say(doneStep(_problem, s));
      final next = _stepIndex + 1;
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (!mounted || _written[s.place] == null || _stepIndex != next - 1) return;
        setState(() {
          _stepIndex = next;
          _startStep();
        });
      });
    } else {
      _solved = true;
      _say('${doneStep(_problem, s)} ${tr('¡Listo!', 'Done!')} ${_problem.a} ${_problem.symbol} ${_problem.b} = ${_problem.answer}.');
    }
    setState(() {});
  }

  /// "¿Por qué?": the student picks a question; the tutor answers with the engine's facts. If its reply doesn't pass
  /// the engine's checks (or takes too long), Penko answers with her own written line instead.
  Future<void> _why() async {
    final p = _problem, s = _step;
    // Shown in the app's language; the tutor model is asked them in Spanish, as it was trained
    List<String> ask() => [
      whyQuestion(p, s),
      tr('¿Cómo sé si mi resultado está bien?', 'How do I know if my answer is right?'),
      tr('Explícamelo de otra forma, por favor.', 'Please explain it another way.'),
    ];
    final questions = ask(), forModel = Lang.spanish(ask);
    final pick = await askWhich(context, questions);
    if (pick == null || !mounted || p != _problem || s != _step) return;
    _helped = true;
    final help = hints(p, s);
    // Her written answer to each question, if the tutor's doesn't pass
    final fallback = [
      '${help[0]} ${help[1]}',
      switch (p.op) {
        Op.add => tr('Cuando termines, comprueba con una resta: el resultado menos uno de los números debe dar el otro.',
            'When you finish, check with a subtraction: the answer minus one of the numbers should give the other one.'),
        Op.sub => tr('Cuando termines, comprueba con una suma: tu resultado más el número de abajo debe dar el de arriba.',
            'When you finish, check with an addition: your answer plus the bottom number should give the top one.'),
        Op.mul => tr('Cuando termines, comprueba dividiendo: el resultado entre el número de abajo debe dar el de arriba.',
            'When you finish, check by dividing: the answer divided by the bottom number should give the top one.'),
      },
      help[0],
    ][pick];
    setState(() => _thinking = true);
    _say(tr('Déjame pensar.', 'Let me think.')); // heard with the voice on; the bubble shows the dots
    final reply = await Tutor.instance
        .explain(
          facts: columnFacts(p),
          question: forModel[pick],
          // Practising: the answer and this column's digit are the student's to find
          forbidden: _phase == _Phase.practice ? {p.answer.toDouble()} : const {},
        )
        .timeout(const Duration(seconds: 60), onTimeout: () {
      Tutor.instance.cancel();
      return null;
    });
    if (!mounted || p != _problem || s != _step) return;
    setState(() => _thinking = false);
    _say(reply ?? fallback);
  }

  void _showHint() {
    final all = hints(_problem, _step);
    if (_hint >= all.length) return;
    // The last hint says the digit: only after a real try
    if (_hint == all.length - 1 && _misses == 0) {
      _say(tr('Primero inténtalo tú. Si no sale, te digo qué número va.', "Try it yourself first. If it doesn't work out, I'll tell you the number."));
      return;
    }
    _say(all[_hint++]);
  }

  @override
  Widget build(BuildContext context) {
    final practising = _phase == _Phase.practice && !_solved;
    final showProblem = _phase == _Phase.example || _phase == _Phase.practice;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close, color: Pk.textSoft),
                    tooltip: tr('Salir', 'Leave'),
                  ),
                  LessonSign(id: _lesson.id, title: _lesson.title, colour: _colour),
                  Expanded(
                    child: Text(
                      _lesson.title,
                      style: TextStyle(fontFamily: pixelFont, fontSize: 18, color: _colour),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_phase == _Phase.practice)
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
              _PenkoSays(line: _line, thinking: _thinking, onReplay: () => Speech.instance.say(spoken(_line))),
              const SizedBox(height: 12),
              Expanded(
                child: Center(
                  child: showProblem
                      ? ColumnView(
                          problem: _problem,
                          written: _written,
                          active: _solved ? null : _step.place,
                          marked: _marked,
                          flash: _flash,
                        )
                      : _phase == _Phase.done
                      ? const Penko(pose: PenkoPose.jump, size: 140)
                      : const Penko(pose: PenkoPose.talk, size: 140),
                ),
              ),
              if (practising) ...[
                _NumberPad(onDigit: (d) => setState(() => _type(d))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: PkButton(
                        tr('Pista', 'Hint'),
                        color: Pk.note,
                        textColor: Pk.gold,
                        leading: const Icon(Icons.lightbulb_outline, color: Pk.gold),
                        onPressed: _hint < hints(_problem, _step).length && !_thinking ? () => setState(_showHint) : null,
                      ),
                    ),
                    if (_tutor) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: PkButton(
                          tr('¿Por qué?', 'Why?'),
                          color: Pk.note,
                          textColor: Pk.gold,
                          leading: const Icon(Icons.psychology_alt_outlined, color: Pk.gold),
                          onPressed: _thinking ? null : _why,
                        ),
                      ),
                    ],
                  ],
                ),
              ] else
                PkButton(
                  switch (_phase) {
                    _Phase.example when !_solved => tr('Siguiente paso', 'Next step'),
                    _Phase.done => tr('Volver', 'Back'),
                    _ => tr('Continuar', 'Continue'),
                  },
                  onPressed: _next,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PenkoSays extends StatelessWidget {
  final String line;
  final bool thinking; // the tutor is working: dots instead of words
  final VoidCallback onReplay;
  const _PenkoSays({required this.line, required this.onReplay, this.thinking = false});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _bubble(),
      if (!thinking) LinePictures(line),
    ],
  );

  Widget _bubble() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Penko(pose: PenkoPose.idle, size: 64),
      const SizedBox(width: 8),
      Expanded(
        child: GestureDetector(
          onTap: onReplay,
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            decoration: BoxDecoration(
              color: Pk.dialog,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: thinking
                      ? const ThinkingLine()
                      : TermText(
                          line,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Pk.onDialog, height: 1.3),
                        ),
                ),
                const Icon(Icons.volume_up, size: 20, color: Pk.onDialog),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

class _NumberPad extends StatelessWidget {
  final void Function(int) onDigit;
  const _NumberPad({required this.onDigit});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final row in const [
        [1, 2, 3, 4, 5],
        [6, 7, 8, 9, 0],
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              for (final d in row)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Semantics(
                      button: true,
                      label: '$d',
                      child: Material(
                        color: Pk.cardHi,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Pk.rim.withValues(alpha: 0.6)),
                        ),
                        child: InkWell(
                          key: ValueKey('digit-$d'),
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => onDigit(d),
                          child: SizedBox(
                            height: 56,
                            child: Center(
                              child: Text(
                                '$d',
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Pk.text),
                              ),
                            ),
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
