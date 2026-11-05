// wellbeing_screen.dart — "¿Cómo estoy con mi dinero?": the CFPB Financial Well-Being Scale (abbreviated, official
// Spanish wording), one question per screen with big answers, read aloud if the voice is on. The score and the day
// stay on this phone only, so a person can answer again later and see if it changed. For adults.
import 'package:flutter/material.dart';

import '../art/palette.dart';
import '../art/penko.dart';
import '../audio/speech.dart';
import '../data/settings.dart';
import '../data/store.dart';
import '../glossary/term_text.dart';
import '../i18n/lang.dart';
import '../money/wellbeing.dart';
import '../ui/pixel_ui.dart';

const _key = 'wellbeing'; // [{"d": "2026-10-22", "s": 55}, …]

class WellbeingScreen extends StatefulWidget {
  const WellbeingScreen({super.key});

  @override
  State<WellbeingScreen> createState() => _WellbeingScreenState();
}

class _WellbeingScreenState extends State<WellbeingScreen> {
  List<Map<String, dynamic>> _past = [];
  int _page = -1; // -1: the introduction; 0–6: the questions; 7: the result
  final _answers = List<int?>.filled(7, null);
  int? _score;

  @override
  void initState() {
    super.initState();
    Store.get<List>(_key).then((v) {
      if (mounted) setState(() => _past = [...?v?.cast<Map>().map((m) => m.cast<String, dynamic>())]);
    });
  }

  @override
  void dispose() {
    Speech.instance.stop();
    super.dispose();
  }

  (String, String, List<String>) _question(int i) => switch (i) {
    < 3 => (describesHeading, wellbeingItems[i].question, wellbeingItems[i].answers),
    < 5 => (oftenHeading, wellbeingItems[i].question, wellbeingItems[i].answers),
    5 => (aboutYouHeading, ageQuestion, ageAnswers),
    _ => (aboutYouHeading, modeQuestion, modeAnswers),
  };

  void _read() {
    if (_page < 0 || _page > 6 || !Settings.voice.value) return;
    final (_, q, answers) = _question(_page);
    Speech.instance.say('$q. ${answers.join('. ')}.');
  }

  void _go(int page) {
    setState(() => _page = page);
    _read();
  }

  Future<void> _choose(int answer) async {
    setState(() => _answers[_page] = answer);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (_page < 6) {
      _go(_page + 1);
      return;
    }
    final score = wellbeingScore([for (var i = 0; i < 5; i++) _answers[i]!], age: _answers[5]!, mode: _answers[6]!);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final past = [..._past, {'d': today, 's': score}];
    await Store.set(_key, past);
    Speech.instance.stop();
    setState(() {
      _past = past;
      _score = score;
      _page = 7;
    });
    if (Settings.voice.value) Speech.instance.say(tr('Tu puntuación es $score de 100.', 'Your score is $score out of 100.'));
  }

  Future<void> _forget() async {
    await Store.set(_key, null);
    setState(() => _past = []);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(tr('¿Cómo estoy con mi dinero?', 'How am I doing with money?')),
      actions: [
        if (_page >= 0 && _page <= 6)
          IconButton(onPressed: _read, icon: const Icon(Icons.volume_up), tooltip: tr('Escuchar la pregunta', 'Listen to the question')),
      ],
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: switch (_page) {
          -1 => _intro(),
          7 => _result(),
          _ => _questionPage(),
        },
      ),
    ),
  );

  Widget _intro() => ListView(
    children: [
      const Center(child: Penko(pose: PenkoPose.talk, size: 96)),
      const SizedBox(height: 16),
      TermText(
        tr('Son 7 preguntas cortas sobre cómo te sientes con tu dinero. No hay respuestas buenas ni malas: contesta lo '
            'que de verdad te pasa.', 'These are 7 short questions about how you feel about your money. There are no good '
            'or bad answers: answer with what really happens to you.'),
        style: const TextStyle(fontSize: 18, height: 1.4, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 12),
      TermText(
        tr('Es para personas de 18 años o más. Tu resultado se queda solo en este teléfono. Puedes contestarlo otra vez en '
            'unas semanas para ver si cambió.', "It's for people aged 18 or over. Your score stays only on this device. You "
            'can answer it again in a few weeks to see if it changed.'),
        style: const TextStyle(color: Pk.textSoft, fontSize: 15, height: 1.4),
      ),
      if (_past.isNotEmpty) ...[const SizedBox(height: 20), _history()],
      const SizedBox(height: 24),
      PkButton(_past.isEmpty ? tr('Empezar', 'Start') : tr('Contestar otra vez', 'Answer again'),
          leading: const Icon(Icons.play_arrow, color: Pk.onGold), onPressed: () => _go(0)),
      const SizedBox(height: 20),
      const _Source(),
    ],
  );

  Widget _questionPage() {
    final (heading, question, answers) = _question(_page);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Progress, as a bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(value: (_page + 1) / 7, minHeight: 8),
        ),
        const SizedBox(height: 6),
        Text(tr('Pregunta ${_page + 1} de 7', 'Question ${_page + 1} of 7'), style: const TextStyle(color: Pk.textSoft, fontSize: 14)),
        const SizedBox(height: 16),
        Text(heading, style: const TextStyle(color: Pk.gold, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(question, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.3)),
        const SizedBox(height: 20),
        Expanded(
          child: ListView(
            children: [
              for (final (i, a) in answers.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: PkChoice(
                    text: a,
                    state: _answers[_page] == i ? ChoiceState.selected : ChoiceState.idle,
                    onTap: () => _choose(i),
                  ),
                ),
            ],
          ),
        ),
        if (_page > 0)
          TextButton.icon(
            onPressed: () => _go(_page - 1),
            icon: const Icon(Icons.arrow_back, color: Pk.textSoft),
            label: Text(tr('Pregunta anterior', 'Previous question'), style: const TextStyle(color: Pk.textSoft)),
          ),
      ],
    );
  }

  Widget _result() {
    final before = _past.length >= 2 ? _past[_past.length - 2]['s'] as int : null;
    return ListView(
      children: [
        const SizedBox(height: 8),
        const Center(child: Penko(pose: PenkoPose.jump, size: 80)),
        const SizedBox(height: 12),
        Center(child: Text(tr('Tu puntuación', 'Your score'), style: const TextStyle(color: Pk.textSoft, fontSize: 16))),
        Center(
          child: Text('$_score', style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w800, color: Pk.gold)),
        ),
        Center(child: Text(tr('de 100', 'out of 100'), style: const TextStyle(color: Pk.textSoft, fontSize: 16))),
        const SizedBox(height: 16),
        _Gauge(score: _score!),
        const SizedBox(height: 16),
        Text(
            tr('Mientras más alta, más bienestar financiero: sentir que tienes el control de tu dinero hoy y para '
                'después.', 'The higher it is, the more financial well-being: feeling in control of your money, today and '
                'for later.'),
            style: const TextStyle(fontSize: 16, height: 1.4)),
        if (before != null) ...[
          const SizedBox(height: 12),
          Text(
            tr('La vez anterior: $before. ${_score! > before ? '¡Subió ${_score! - before}!' : _score! < before ? 'Bajó ${before - _score!}. Pasa, y está bien: lo importante es seguir aprendiendo.' : 'Quedó igual.'}',
                'Last time: $before. ${_score! > before ? 'It went up ${_score! - before}!' : _score! < before ? "It went down ${before - _score!}. That happens, and it's OK: what matters is to keep learning." : 'It stayed the same.'}'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Pk.rightText),
          ),
        ],
        const SizedBox(height: 24),
        PkButton(tr('Listo', 'Done'), leading: const Icon(Icons.check, color: Pk.onGold), onPressed: () => Navigator.of(context).pop()),
        const SizedBox(height: 20),
        _history(),
        const SizedBox(height: 16),
        const _Source(),
      ],
    );
  }

  Widget _history() => PkPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('Tus resultados', 'Your scores'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        for (final r in _past.reversed.take(6))
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              Expanded(child: Text('${r['d']}', style: const TextStyle(color: Pk.textSoft))),
              Text('${r['s']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ]),
          ),
        TextButton(onPressed: _forget, child: Text(tr('Borrar mis resultados', 'Delete my scores'), style: const TextStyle(color: Pk.textSoft))),
      ],
    ),
  );
}

/// The score on a line from 0 to 100
class _Gauge extends StatelessWidget {
  final int score;
  const _Gauge({required this.score});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => SizedBox(
      height: 36,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 10,
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                gradient: const LinearGradient(colors: [Pk.wrong, Pk.sun, Pk.right]),
              ),
            ),
          ),
          Positioned(
            left: (box.maxWidth - 28) * score / 100,
            top: 3,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: Pk.dialog, shape: BoxShape.circle, border: Border.all(color: Pk.ink, width: 3)),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Source extends StatelessWidget {
  const _Source();

  @override
  Widget build(BuildContext context) => Text(
    tr(
      'Escala de Bienestar Financiero del CFPB (Oficina para la Protección Financiera del Consumidor de EE. UU.), '
          'versión abreviada en español, consumerfinance.gov/financial-well-being. El CFPB no está afiliado con Penko.',
      'CFPB Financial Well-Being Scale (US Consumer Financial Protection Bureau), abbreviated version, '
          'consumerfinance.gov/financial-well-being. The CFPB is not affiliated with Penko.',
    ),
    style: const TextStyle(color: Pk.textSoft, fontSize: 12, height: 1.35),
  );
}
