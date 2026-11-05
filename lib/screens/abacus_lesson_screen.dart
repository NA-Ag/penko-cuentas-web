// abacus_lesson_screen.dart — an Ábaco lesson. Made to work without reading: Penko says every instruction aloud
// (tap her bubble to hear it again), the number to show appears as a big digit and as dots in fives, the abacus is
// the answer, and buttons carry icons. Right answers move on by themselves.
import 'package:flutter/material.dart';

import '../abacus/abacus.dart';
import '../abacus/abacus_lessons.dart';
import '../abacus/abacus_view.dart';
import '../abacus/tracker.dart';
import '../art/palette.dart';
import '../art/penko.dart';
import '../audio/speech.dart';
import '../data/progress.dart';
import '../data/settings.dart';
import '../glossary/glossary_screen.dart';
import '../glossary/term_text.dart';
import '../i18n/lang.dart';
import '../math/explain.dart' show spoken;
import '../ui/pixel_ui.dart';
import '../wayfinding/wayfinding.dart';
import 'course.dart';

class AbacusLessonScreen extends StatefulWidget {
  final AbacusLesson lesson;
  const AbacusLessonScreen({super.key, required this.lesson});

  @override
  State<AbacusLessonScreen> createState() => _AbacusLessonScreenState();
}

class _AbacusLessonScreenState extends State<AbacusLessonScreen> {
  int _activity = 0;
  int _item = 0; // which number / problem within the activity
  Board _board = emptyBoard(1);
  Tracker? _tracker;
  Move? _hint;
  Bead? _glow;
  bool _solved = false;
  bool _offTrack = false;
  bool _finished = false;
  String _line = '';

  AbacusActivity get _current => widget.lesson.activities[_activity];
  late final Color _colour = unitOfLesson(widget.lesson.id)?.color ?? Pk.gold; // its unit's colour, like a Metro line's

  /// What the "read this screen" button reads: the lesson, Penko's line and the number to show
  List<String> _readLines() => [
    widget.lesson.title,
    _line,
    if (!_finished)
      switch (_current) {
        SetNumbers(:final values) => '${values[_item]}',
        _ => '',
      },
  ];

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    Speech.instance.stop();
    super.dispose();
  }

  void _say(String line) {
    _line = line;
    if (Settings.voice.value) Speech.instance.say(spoken(line));
  }

  /// Sets up the current item of the current activity
  void _start() {
    _solved = false;
    _offTrack = false;
    _hint = null;
    _glow = null;
    _tracker = null;
    switch (_current) {
      case Say(:final line, :final value, :final rods, :final glow):
        _board = fromNumber(value, rods);
        _glow = glow;
        _say(line);
      case SetNumbers(:final values, :final rods):
        _board = emptyBoard(rods);
        _say(_item == 0
            ? tr('Muestra el ${values[_item]} en el ábaco.', 'Show ${values[_item]} on the abacus.')
            : tr('Ahora muestra el ${values[_item]}.', 'Now show ${values[_item]}.'));
      case AddOn(:final problems, :final rods, :final guided):
        final (start, amount) = problems[_item];
        _board = fromNumber(start, rods);
        final moves = [for (final s in planOperation(_board, true, amount)) ...s.moves];
        _tracker = Tracker(_board, moves);
        if (guided) _hint = _tracker!.track(_board).next;
        _say(tr('Tenemos $start. Súmale $amount.', 'We have $start. Add $amount.'));
    }
    setState(() {});
  }

  void _advance() {
    final count = switch (_current) {
      Say() => 1,
      SetNumbers(:final values) => values.length,
      AddOn(:final problems) => problems.length,
    };
    if (_item + 1 < count) {
      _item++;
    } else if (_activity + 1 < widget.lesson.activities.length) {
      _activity++;
      _item = 0;
    } else {
      _finished = true;
      Progress.finish(widget.lesson.id);
      _say(tr('¡Terminaste la lección! Muy buen trabajo.', 'You finished the lesson! Great work.'));
      setState(() {});
      return;
    }
    _start();
  }

  void _changed(Board next, Move move) {
    if (_solved) return;
    _board = next;
    switch (_current) {
      case SetNumbers(:final values, :final rods):
        _hint = null;
        if (sameBoard(next, fromNumber(values[_item], rods))) _right(tr('¡Muy bien! Eso es ${values[_item]}.', "Well done! That's ${values[_item]}."));
      case AddOn(:final problems, :final guided):
        final state = _tracker!.track(next);
        switch (state.status) {
          case TrackStatus.done:
            final (a, b) = problems[_item];
            _right('${tr('¡Muy bien!', 'Well done!')} $a + $b = ${a + b}.');
          case TrackStatus.onTrack:
            _offTrack = false;
            _hint = guided ? state.next : null;
          case TrackStatus.offTrack:
            if (!_offTrack) _say(tr('Mmm, esa cuenta no. Toca la flecha para empezar otra vez.', 'Hmm, not that bead. Tap the arrow to start again.'));
            _offTrack = true;
            _hint = null;
        }
      case Say():
        break;
    }
    setState(() {});
  }

  void _right(String line) {
    _solved = true;
    _hint = null;
    _say(line);
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted && _solved) _advance();
    });
  }

  void _showHint() {
    switch (_current) {
      case SetNumbers(:final values, :final rods):
        final moves = movesToSet(_board, fromNumber(values[_item], rods));
        _hint = moves.isEmpty ? null : moves.first;
      case AddOn():
        _hint = _tracker!.track(_board).next;
        if (_hint == null) _say(tr('Toca la flecha para empezar otra vez.', 'Tap the arrow to start again.'));
      case Say():
        break;
    }
    setState(() {});
  }

  /// The number to show, as a digit and as dots in fives (readable without knowing digits yet)
  Widget? _target() {
    final n = switch (_current) {
      SetNumbers(:final values) => values[_item],
      _ => null,
    };
    if (n == null || n > 9) {
      return n == null
          ? null
          : Text('$n', style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w700, color: Pk.gold));
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$n', style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w700, color: Pk.gold)),
        const SizedBox(width: 16),
        Wrap(
          spacing: 6,
          children: [
            for (var i = 0; i < n; i++)
              Container(
                width: 18,
                height: 18,
                margin: EdgeInsets.only(left: i == 5 ? 10 : 0),
                decoration: BoxDecoration(color: i < 5 ? Pk.orange : Pk.sun, shape: BoxShape.circle),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSay = _current is Say;
    final interactive = !isSay && !_solved && !_finished;
    final target = _finished ? null : _target();
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
                  LessonSign(id: widget.lesson.id, title: widget.lesson.title, colour: _colour),
                  Expanded(
                    child: Text(widget.lesson.title,
                        style: TextStyle(fontFamily: pixelFont, fontSize: 18, color: _colour)),
                  ),
                  IconButton(
                    onPressed: () => openGlossary(context),
                    icon: const Icon(Icons.menu_book_outlined, color: Pk.gold),
                    tooltip: tr('Palabras', 'Words'),
                  ),
                  // Progress as dots: no reading needed
                  for (var i = 0; i < widget.lesson.activities.length; i++)
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: i < _activity || _finished ? Pk.gold : (i == _activity ? Pk.text : Pk.cardHi),
                        shape: BoxShape.circle,
                      ),
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
                        constraints: const BoxConstraints(minHeight: 72),
                        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                        decoration: BoxDecoration(
                          color: _offTrack ? Pk.wrongSoft : Pk.dialog,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _offTrack ? Pk.wrong : Colors.transparent, width: 2.5),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TermText(_line,
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3,
                                      color: _offTrack ? Pk.wrongText : Pk.onDialog)),
                            ),
                            Icon(Icons.volume_up, size: 26, color: _offTrack ? Pk.wrongText : Pk.onDialog),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (target != null) Padding(padding: const EdgeInsets.only(top: 12), child: target),
              const SizedBox(height: 12),
              Expanded(
                child: _finished
                    ? const Center(child: Penko(pose: PenkoPose.jump, size: 140))
                    : AbacusView(board: _board, hint: _hint, glow: _glow, onChange: interactive ? _changed : null),
              ),
              const SizedBox(height: 12),
              if (interactive)
                Row(
                  children: [
                    if (_current is AddOn) ...[
                      Expanded(
                        child: PkButton(tr('Otra vez', 'Again'), color: Pk.note, textColor: Pk.gold, leading: const Icon(Icons.replay, color: Pk.gold),
                            onPressed: _start),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: PkButton(tr('Pista', 'Hint'), color: Pk.note, textColor: Pk.gold,
                          leading: const Icon(Icons.lightbulb_outline, color: Pk.gold), onPressed: _showHint),
                    ),
                  ],
                )
              else if (isSay || _finished)
                PkButton(_finished ? tr('Volver', 'Back') : tr('Continuar', 'Continue'),
                    leading: Icon(_finished ? Icons.home : Icons.arrow_forward, color: Pk.onGold),
                    onPressed: _finished ? () => Navigator.of(context).pop() : _advance),
            ],
          ),
        ),
      ),
    );
  }
}
