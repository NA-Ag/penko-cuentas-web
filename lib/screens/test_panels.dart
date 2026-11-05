// test_panels.dart — the website's two side panels, for the testers. On a wide screen they sit beside the app (main.dart):
// on the left what this test is and what happens with their things, on the right a notebook. On a narrow screen there's
// no room, so the same two open as pages from Ajustes, and the welcome links to the first.
import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../art/palette.dart';
import '../data/store.dart';
import '../glossary/pictograms.dart';
import '../i18n/lang.dart';
import '../ui/pixel_ui.dart';
import '../wayfinding/wayfinding.dart';
import 'feedback_screen.dart';

/// The browser's width above which the app stops stretching and keeps a phone's width
const double phoneWidth = 560;

/// The browser's width from which the panels fit beside the app
const double sidesWidth = 1100;

/// True when the panels are beside the app (so Ajustes doesn't need to offer them)
bool get sidesShown {
  if (!kIsWeb) return false;
  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  return view.physicalSize.width / view.devicePixelRatio >= sidesWidth;
}

/// One thing a tester should know: its picture, heading and text
List<(Pic, String, String)> get _sections => [
  (
    picCheckFirst,
    tr('Esto es una prueba', 'This is a test version'),
    tr('Gracias por ayudarnos a probarla. Todavía estamos trabajando en ella: algo puede fallar o cambiar, y lo que nos cuentes nos ayuda a arreglarlo.',
        "Thank you for helping us try it. We're still working on it: things may break or change, and what you tell us helps us fix them."),
  ),
  (
    picBook,
    tr('Lo tuyo se queda aquí', 'Your things stay here'),
    tr('No hay cuentas. Tu avance y tus notas se guardan solo en este navegador, y nosotros no podemos verlos. Si borras los datos del navegador, se borran también. No hay anuncios ni rastreadores, y solo nos llega lo que tú nos mandes. Penko nunca te pedirá contraseñas, datos de tarjetas ni dinero.',
        "There are no accounts. Your progress and notes are kept only in this browser, and we can't see them. If you clear your browser's data, they go too. There are no ads or trackers, and we only receive what you send us. Penko will never ask you for passwords, card details or money."),
  ),
  (
    picGlobe,
    tr('La voz de esta página', 'The voice on this page'),
    tr('Lo que dice Penko está hecho con una voz sintética, por piezas, y por eso los números se oyen un poco cortados. Si tu navegador no puede reproducirla, usa su propia voz, que puede sonar robótica. La app para teléfono usa la voz del teléfono.',
        "What Penko says is made with a synthetic voice, in pieces, so numbers can sound a little choppy. If your browser can't play it, it uses its own voice, which can sound robotic. The phone app uses the phone's voice."),
  ),
  (
    picPhone,
    tr('Aquí no está la inteligencia artificial', 'No AI assistant here'),
    tr('En esta versión web, Penko no responde con inteligencia artificial: en el navegador habría que descargar un modelo muy pesado, o pagar un servidor que lo corra. La app, por ahora solo para Android, trae el modelo completo y funciona en tu teléfono, sin internet.',
        "On this web version, Penko doesn't answer with AI: in a browser it would need a very large download, or a paid server to run it. The app, for now only on Android, has the full model and runs on your phone, with no internet."),
  ),
  (
    picHeart,
    tr('Qué es Penko Cuentas Claras', 'What Penko Cuentas Claras is'),
    tr('Una ayuda gratuita y de código abierto para aprender matemáticas y el dinero de todos los días. Queremos que sirva a quien casi no lee y a quien no habla español, sobre todo a las comunidades indígenas. Por eso guían los dibujos y la voz, como en el Metro de la Ciudad de México. Las lenguas indígenas vendrán con traductores de esas comunidades.',
        "A free, open-source help for learning math and everyday money. We want it to work for people who barely read and people who don't speak Spanish, above all Indigenous communities. That's why pictures and voice lead the way, like the Mexico City Metro. Indigenous languages will come with translators from those communities."),
  ),
];

/// What the panel reads aloud, for the voice pack
List<String> get testPanelLines => [for (final (_, title, body) in _sections) ...[title, body]];

/// What this test is. [onWrite] opens the feedback form.
class TestInfo extends StatelessWidget {
  final VoidCallback onWrite;
  const TestInfo({super.key, required this.onWrite});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Row(
        children: [
          const Expanded(child: SizedBox()),
          ReadScreenButton(lines: () => testPanelLines),
        ],
      ),
      for (final (picture, title, body) in _sections) ...[
        Row(
          children: [
            PictogramTile(picture, size: 44),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
          ],
        ),
        const SizedBox(height: 8),
        Text(body, style: const TextStyle(color: Pk.textSoft, fontSize: 15, height: 1.4)),
        const SizedBox(height: 22),
      ],
      PkButton(tr('Escríbenos', 'Write to us'), leading: const Icon(Icons.mail_outline, color: Pk.onGold), onPressed: onWrite),
      TextButton(onPressed: () => launchUrl(privacyPage), child: Text(tr('Aviso de privacidad', 'Privacy notice'))),
    ],
  );
}

/// A notebook: what's written is saved as it's written, in this browser only
class NotesPad extends StatefulWidget {
  const NotesPad({super.key});
  @override
  State<NotesPad> createState() => _NotesPadState();
}

class _NotesPadState extends State<NotesPad> {
  static const _key = 'notes';
  final _text = TextEditingController();
  Timer? _save;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    Store.get<String>(_key).then((saved) {
      if (mounted && saved != null) _text.text = saved;
    });
  }

  @override
  void dispose() {
    if (_save?.isActive ?? false) {
      _save!.cancel();
      Store.set(_key, _text.text);
    }
    _text.dispose();
    super.dispose();
  }

  void _changed(String value) {
    _save?.cancel();
    _save = Timer(const Duration(milliseconds: 400), () => Store.set(_key, value));
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _text.text));
    if (!mounted) return;
    setState(() => _copied = true);
    Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _erase() async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('¿Borrar tus notas?', 'Erase your notes?')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr('No', 'No'))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(tr('Sí, borrar', 'Yes, erase'))),
        ],
      ),
    );
    if (sure != true) return;
    _save?.cancel();
    _text.clear();
    await Store.set(_key, null);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            PictogramTile(picBook, size: 44),
            const SizedBox(width: 12),
            Expanded(child: Text(tr('Mis notas', 'My notes'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
            IconButton(
              tooltip: _copied ? tr('Copiado', 'Copied') : tr('Copiar', 'Copy'),
              color: Pk.textSoft,
              icon: Icon(_copied ? Icons.check : Icons.copy),
              onPressed: _copy,
            ),
            IconButton(tooltip: tr('Borrar', 'Erase'), color: Pk.textSoft, icon: const Icon(Icons.delete_outline), onPressed: _erase),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: TextField(
            controller: _text,
            onChanged: _changed,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            keyboardType: TextInputType.multiline,
            style: const TextStyle(fontSize: 16, height: 1.45),
            decoration: InputDecoration(
              hintText: tr('Escribe aquí lo que quieras: cuentas, dudas, ideas…', 'Write anything here: sums, questions, ideas…'),
              hintStyle: const TextStyle(color: Pk.textSoft),
              filled: true,
              fillColor: Pk.field,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(tr('Se guardan solas, solo en este navegador.', 'Saved as you write, only in this browser.'),
            style: const TextStyle(color: Pk.textSoft, fontSize: 13)),
      ],
    ),
  );
}

/// One of the panels as a page of its own, for narrow screens
Route<void> panelPage(String title, Widget child) => MaterialPageRoute(
  builder: (_) => Scaffold(appBar: AppBar(title: Text(title)), body: SafeArea(child: child)),
);

String get testInfoTitle => tr('Sobre esta prueba', 'About this test');
String get notesTitle => tr('Mis notas', 'My notes');
