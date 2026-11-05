// welcome_screen.dart — the first time the app opens. It has to work for someone who doesn't read, and for someone who
// speaks neither of our languages, so the pictures carry it and the words only help: the first page is just the
// languages (each in its own words), and that first tap is also what lets a browser speak at all. Then the abacus, the
// maths units and everyday money appear as stations on one line, like the Metro, a hand shows what to tap, and the
// last page picks the person by height. Every line is read aloud; the speaker button says it again.
import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../art/palette.dart';
import '../art/penko.dart';
import '../audio/speech.dart';
import '../data/settings.dart';
import '../data/store.dart';
import '../i18n/lang.dart';
import '../math/explain.dart' show spoken;
import '../glossary/pictograms.dart';
import '../ui/pixel_ui.dart';
import '../wayfinding/wayfinding.dart';
import 'course.dart';
import 'feedback_screen.dart';
import 'home_screen.dart';
import 'test_panels.dart';

/// Each line with its picture: a pictogram of the place it's about (places.dart), or an icon
List<(IconData, String)> get _lines => [
  (Icons.waving_hand, tr('¡Hola! Soy Penko. Te voy a ayudar con las matemáticas, paso a paso.',
      "Hi! I'm Penko. I'm going to help you with math, step by step.")),
  (Icons.storefront_outlined, tr('Aquí aprendes a ver el precio, pagar y contar tu cambio, para que nadie te engañe.',
      'Here you learn to see the price, pay, and count your change, so nobody can cheat you.')),
  (Icons.blur_on, tr('Si los números todavía no te salen, empieza con el ábaco. No hace falta leer: yo te digo todo.',
      "If numbers are still tricky for you, start with the abacus. You don't need to read: I'll tell you everything.")),
  (Icons.calculate_outlined, tr('Luego practicamos sumas, restas, multiplicaciones y divisiones, como en la escuela.',
      'Then we practice adding, subtracting, multiplying and dividing, like at school.')),
  (
    Icons.payments_outlined,
    tr('Y al final usamos las matemáticas para el dinero de todos los días: descuentos, '
        'intereses y ahorro.', 'And at the end we use math for everyday money: discounts, interest and saving.'),
  ),
  (Icons.favorite_border, tr('Aquí nadie te califica. Si algo no sale, lo intentamos otra vez juntos.',
      "Nobody grades you here. If something doesn't work out, we try again together.")),
];

/// The welcome's lines as Penko reads them, for the voice pack
List<String> get welcomeLines => [for (final l in _lines) l.$2];

/// Who can use Penko, for the voice pack
List<String> get whoLabels => [tr('¿Quién va a usar Penko?', 'Who is going to use Penko?'), for (final w in _who) w.$2, tr('Así empiezo donde te sirve. Puedes ir a cualquier parte cuando quieras.', 'That way I start where it helps you. You can go anywhere, whenever you like.')];

/// The three stations of the line, in the order they're walked
List<Pic> get _stations => [picAbacus, picPlusMinus, picMoneyUnit];

/// The pictogram of the lines that aren't about a station (the first keeps its waving hand)
Pic? _picture(int line) => line == _lines.length - 1 ? picHeart : null;

/// The little story with no words: the price, paying, the change, and all is well
List<Pic> get _purchase => [picPrice, picBill, picChange, picHeart];

/// Who's going to use Penko, and the unit each starts at (by its key, Unit.key; they can move to any other)
List<(Pic, String, String)> get _who => [
  (picAbacus, tr('Alguien que todavía no lee bien los números', "Someone who can't read numbers well yet"), 'Ábaco'),
  (picChild, tr('Una niña o un niño de primaria', 'A child in primary school'), 'Sumas y restas'),
  (picTeen, tr('Una persona joven de secundaria', 'A young person in secondary school'), 'Fracciones y porcentajes'),
  (picAdult, tr('Una persona adulta', 'An adult'), 'Dinero'),
];

/// A shop visit told like a comic strip: each picture lights up in turn, again and again
class _Purchase extends StatefulWidget {
  const _Purchase();
  @override
  State<_Purchase> createState() => _PurchaseState();
}

class _PurchaseState extends State<_Purchase> {
  Timer? _timer;
  int _at = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      if (mounted && !MediaQuery.of(context).disableAnimations) setState(() => _at = (_at + 1) % _purchase.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      for (var i = 0; i < _purchase.length; i++) ...[
        if (i > 0) Icon(Icons.chevron_right, color: i <= _at ? Pk.gold : Pk.cardHi, size: 22),
        AnimatedScale(
          scale: i == _at ? 1.2 : 1,
          duration: const Duration(milliseconds: 250),
          child: PictogramTile(_purchase[i], size: 64, frame: i <= _at ? Pk.gold : Pk.cardHi, moves: i == _at),
        ),
      ],
    ],
  );
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  /// True once the welcome is finished in this run: a language change (which builds the app again) then opens Home
  static bool done = false;

  /// True once a language is tapped: a language change builds the app again, and the welcome has to carry on from there
  static bool languagePicked = false;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  // The hand that shows where to tap
  late final _hand = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);
  // The language is picked. Nothing is said before: a browser stays silent until the first tap
  bool get _chosen => WelcomeScreen.languagePicked;
  bool _silent = false; // no voice for this language here, so the pictures have to do it alone
  int _line = 0;
  bool _asking = false; // the last page: who's going to use Penko

  @override
  void dispose() {
    _hand.dispose();
    Speech.instance.stop();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // After the language change: the old screen stops all speech as it goes, so wait for it to be gone
    if (_chosen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _begin();
      });
    }
  }

  Future<void> _choose(String code) async {
    final same = Lang.current.value == code; // otherwise the app is built again, and the new screen takes over
    WelcomeScreen.languagePicked = true;
    await Lang.set(code);
    if (!same || !mounted) return;
    setState(() {});
    _begin();
  }

  /// The language is set: Penko says hello, and we find out whether she can be heard here
  Future<void> _begin() async {
    _say();
    final voice = await Speech.instance.hasVoice();
    if (mounted) setState(() => _silent = !voice);
  }

  /// Back to the languages, for a wrong tap
  void _languages() {
    Speech.instance.stop();
    setState(() {
      WelcomeScreen.languagePicked = false;
      _line = 0;
    });
  }

  void _sayWho() {
    if (!Settings.voice.value) return;
    Speech.instance.sayAll(['${tr('¿Quién va a usar Penko?', 'Who is going to use Penko?')} ${_who.map((w) => w.$2).join('. ')}.', navLines['nav.who']!],
        keys: [null, 'nav.who']);
  }

  void _say() {
    if (!Settings.voice.value) return;
    // On the first page Penko also says what to tap
    if (_line == 0) {
      Speech.instance.sayAll([spoken(_lines[0].$2), navLines['nav.welcome_next']!], keys: [null, 'nav.welcome_next']);
    } else {
      Speech.instance.say(spoken(_lines[_line].$2));
    }
  }

  Future<void> _next() async {
    if (_line + 1 < _lines.length) {
      setState(() => _line++);
      _say();
      return;
    }
    setState(() => _asking = true);
    _sayWho();
  }

  /// Starts at the unit that fits; every unit stays open
  Future<void> _start(String unit) async {
    await Store.set('unit', course.indexWhere((u) => u.key == unit).clamp(0, course.length - 1));
    await Store.set('welcomed', true);
    WelcomeScreen.done = true;
    Speech.instance.stop();
    if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  /// The first page: no sentences to read, only each language written in its own words
  Widget _languagePage() => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        const Spacer(),
        const Penko(pose: PenkoPose.jump, size: 160),
        const SizedBox(height: 16),
        const ExcludeSemantics(child: Icon(Icons.waving_hand, color: Pk.gold, size: 56)),
        const Spacer(),
        for (final (code, name) in const [('es', 'Español'), ('en', 'English')])
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PkButton(
              name,
              key: ValueKey('lang-$code'),
              leading: const Icon(Icons.record_voice_over, color: Pk.onGold, size: 34),
              onPressed: () => _choose(code),
            ),
          ),
        // A phone's browser has no side panel, so what this test is has to be offered here
        if (kIsWeb && !sidesShown)
          TextButton.icon(
            icon: const Icon(Icons.info_outline, color: Pk.textSoft),
            label: Text(testInfoTitle, style: const TextStyle(color: Pk.textSoft)),
            onPressed: () => Navigator.of(context).push(panelPage(
              testInfoTitle,
              TestInfo(onWrite: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FeedbackScreen()))),
            )),
          ),
      ],
    ),
  );

  /// Says the page again: big, and only a picture
  Widget _speaker(VoidCallback say) => !Settings.voice.value
      ? const SizedBox.shrink()
      : IconButton.filled(
          iconSize: 34,
          style: IconButton.styleFrom(backgroundColor: Pk.card, foregroundColor: Pk.gold),
          tooltip: tr('Escuchar otra vez', 'Listen again'),
          icon: const Icon(Icons.volume_up),
          onPressed: say,
        );

  /// Told gently, in case the speaker button does nothing: the pictures still lead the way
  Widget get _silentNote => !_silent || !Settings.voice.value
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.volume_off, color: Pk.gold, size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  tr('Aquí no hay voz en español. Los dibujos te guían igual.', "There's no English voice here. The pictures will still guide you."),
                  style: const TextStyle(color: Pk.textSoft, fontSize: 15),
                ),
              ),
            ],
          ),
        );

  Widget _languageButton() => Align(
    alignment: Alignment.centerLeft,
    child: IconButton(
      iconSize: 30,
      color: Pk.textSoft,
      tooltip: tr('Cambiar el idioma', 'Change the language'),
      icon: const Icon(Icons.translate),
      onPressed: _languages,
    ),
  );

  /// The stations on one line, like a Metro map: the one we're talking about is big, the ones walked are joined in gold
  Widget _line3(int active) => Row(
    children: [
      for (var i = 0; i < _stations.length; i++) ...[
        if (i > 0) Expanded(child: Container(height: 8, color: i <= active ? Pk.gold : Pk.cardHi)),
        Opacity(
          opacity: i == active ? 1 : 0.6,
          child: PictogramTile(_stations[i], size: i == active ? 88 : 56, frame: i <= active ? Pk.gold : Pk.cardHi),
        ),
      ],
    ],
  );

  Widget _whoPage() => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const SizedBox(height: 12),
      const Center(child: Penko(pose: PenkoPose.talk, size: 96)),
      Center(child: _speaker(_sayWho)),
      const SizedBox(height: 8),
      Text(
        tr('¿Quién va a usar Penko?', 'Who is going to use Penko?'),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 6),
      Text(
        tr('Así empiezo donde te sirve. Puedes ir a cualquier parte cuando quieras.',
            'That way I start where it helps you. You can go anywhere, whenever you like.'),
        textAlign: TextAlign.center,
        style: const TextStyle(color: Pk.textSoft, fontSize: 15),
      ),
      const SizedBox(height: 20),
      // Each one with the picture and colour of the unit it starts at, as on the path
      for (final (picture, label, unit) in _who)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PkButton(
            label,
            color: Pk.card,
            textColor: Pk.text,
            leading: PictogramTile(picture, size: 56, frame: course.firstWhere((u) => u.key == unit).color),
            onPressed: () => _start(unit),
          ),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    if (!_chosen) return Scaffold(body: SafeArea(child: _languagePage()));
    if (_asking) return Scaffold(body: SafeArea(child: _whoPage()));
    final (icon, text) = _lines[_line];
    final picture = _picture(_line);
    final station = _line >= 2 && _line < 2 + _stations.length ? _line - 2 : null;
    final still = MediaQuery.of(context).disableAnimations;
    final last = _line + 1 == _lines.length;
    return Scaffold(
      body: SafeArea(
        // Scrolls only when it must (big text on a small phone); otherwise fills the screen as designed
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight - 48),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    _languageButton(),
                    const Spacer(),
                    Penko(pose: last ? PenkoPose.jump : PenkoPose.talk, size: 120),
                    const SizedBox(height: 20),
                    if (_line == 1)
                      const _Purchase()
                    else if (station != null)
                      _line3(station)
                    else if (picture != null)
                      PictogramTile(picture, size: 72, frame: Pk.gold)
                    else
                      Icon(icon, color: Pk.gold, size: 56),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _say,
                      child: Semantics(
                        button: true,
                        hint: tr('Escuchar otra vez', 'Listen again'),
                        child: Text(
                          text,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22, height: 1.35),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _speaker(_say),
                    _silentNote,
                    const Spacer(),
                    // Where we are, as dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _lines.length; i++)
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: i <= _line ? Pk.gold : Pk.cardHi, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // The hand, showing what to tap without a word
                    ExcludeSemantics(
                      child: AnimatedBuilder(
                        animation: _hand,
                        builder: (context, child) => Transform.translate(offset: Offset(0, still ? 0 : _hand.value * 10), child: child),
                        child: const Icon(Icons.touch_app, color: Pk.gold, size: 44),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // The one thing to tap: big, yellow, with an arrow (Penko says so on the first page)
                    PkButton(
                      tr('Siguiente', 'Next'),
                      key: const ValueKey('welcome-next'),
                      leading: const Icon(Icons.arrow_forward_rounded, color: Pk.onGold, size: 34),
                      onPressed: _next,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
