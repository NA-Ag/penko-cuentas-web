// feedback_screen.dart — "Escríbenos / Write to us", a short survey that has to work for someone who can't type a
// sentence in Spanish. First step: a picture and three questions, all by tapping, each saying its name. Second step:
// anything they'd like to write, which is optional, then send. The whole screen can be read aloud.
// On the website the answers go to our gateway (lib/feedback/). The phone app has no internet of its own, so it opens
// this same form in the phone's browser. Email and copying are always on offer, in case either can't work. Nothing else
// about the student is sent: only what's chosen and typed here and, if left ticked, the version, language and device.
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../art/palette.dart';
import '../art/penko.dart';
import '../audio/speech.dart';
import '../data/settings.dart';
import '../feedback/feedback_config.dart';
import '../feedback/send.dart';
import '../glossary/pictograms.dart';
import '../i18n/lang.dart';
import '../ui/pixel_ui.dart';
import '../wayfinding/wayfinding.dart';

enum _Kind { good, confused, broken, idea, complaint }

Pic _pictureOf(_Kind k) => switch (k) {
  _Kind.good => picSmile,
  _Kind.confused => picConfused,
  _Kind.broken => picBroken,
  _Kind.idea => picIdea,
  _Kind.complaint => picComplaint,
};

String _nameOf(_Kind k) => switch (k) {
  _Kind.good => tr('Me gustó', 'I liked it'),
  _Kind.confused => tr('No entendí', "I didn't understand"),
  _Kind.broken => tr('Algo falló', 'Something broke'),
  _Kind.idea => tr('Tengo una idea', 'I have an idea'),
  _Kind.complaint => tr('Una queja', 'A complaint'),
};

/// The tap-only questions, by the name the gateway knows them by
List<(String, String)> get _questions => [
  ('easy', tr('¿Fue fácil de usar?', 'Was it easy to use?')),
  ('helped', tr('¿Te ayudaron los dibujos y la voz?', 'Did the pictures and the voice help you?')),
  ('again', tr('¿Lo usarías otra vez?', 'Would you use it again?')),
];

List<(String, Pic, String)> get _answerChoices => [
  ('yes', picSmile, tr('Sí', 'Yes')),
  ('some', picConfused, tr('Más o menos', 'Sort of')),
  ('no', picSad, 'No'),
];

/// The privacy notice, on the website
Uri get privacyPage => kIsWeb ? Uri.base.resolve('privacidad.html') : Uri.parse('$siteUrl/privacidad.html');

class FeedbackScreen extends StatefulWidget {
  /// What the phone app passed on, when it opened the website's form
  final Map<String, String>? link;
  const FeedbackScreen({super.key, this.link});

  static String get _askLine => tr('Toca los dibujos que quieras.', 'Tap any pictures you like.');
  static String get _moreLine => tr(
    'Si quieres, cuéntanos más. Si no, ya puedes enviarlo.',
    "Tell us more if you like. If not, you can send it now.",
  );
  static String get _privacyLine => tr(
    'No pongas contraseñas ni datos de tarjetas. Nunca te pediremos dinero.',
    'Please leave out passwords and card details. We will never ask you for money.',
  );

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  _Kind? _kind;
  final _message = TextEditingController();
  final _email = TextEditingController();
  final _answers = <String, String>{};
  int _step = 0;
  bool _withDevice = true;
  String? _captcha;
  int _captchaRun = 0; // a check can only be used once, so a failed send needs a new one
  bool _captchaFailed = false;
  bool _sending = false;
  bool _done = false;
  bool _failed = false; // shows the other ways of sending it

  @override
  void initState() {
    super.initState();
    final link = widget.link;
    if (link == null) return;
    _kind = _Kind.values.asNameMap()[link['k']];
    _message.text = link['m'] ?? '';
    _email.text = link['e'] ?? '';
    for (final (name, _) in _questions) {
      if (link[name]?.isNotEmpty ?? false) _answers[name] = link[name]!;
    }
    if (_something) _step = 1;
  }

  bool get _something => _kind != null || _answers.isNotEmpty || _message.text.trim().isNotEmpty;

  List<String> get _lines => _step == 0
      ? [FeedbackScreen._askLine, for (final k in _Kind.values) _nameOf(k), for (final (_, q) in _questions) q]
      : [FeedbackScreen._moreLine, FeedbackScreen._privacyLine];

  String get _kindName => _kind == null ? '' : _nameOf(_kind!);

  String _details(BuildContext context) =>
      'Penko Cuentas $appVersion · ${Lang.current.value} · ${widget.link?['d'] ?? deviceInfo(MediaQuery.of(context).size)}';

  /// The whole message as plain text, for the email app or the clipboard
  String _plain(BuildContext context) => [
    '${tr('Tipo', 'Type')}: $_kindName',
    for (final (name, question) in _questions)
      if (_answers.containsKey(name)) '$question ${_answerChoices.firstWhere((c) => c.$1 == _answers[name]).$3}',
    '',
    _message.text.trim(),
    if (_email.text.trim().isNotEmpty) ...['', '${tr('Respóndanme a', 'Reply to')}: ${_email.text.trim()}'],
    if (_withDevice) ...['', '— ${_details(context)}'],
  ].join('\n');

  Future<bool> _open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  Future<void> _openEmail() async {
    final opened = await _open(
      Uri(
        scheme: 'mailto',
        path: contactEmail,
        query:
            'subject=${Uri.encodeComponent('Penko Cuentas · ${_kind?.name ?? ''}')}&body=${Uri.encodeComponent(_plain(context))}',
      ),
    );
    if (!opened && mounted) setState(() => _failed = true);
  }

  /// The phone app: the website's form, already filled in. What's after the '#' stays in the phone's browser.
  Future<void> _openWebsite() async {
    final data = {
      'k': _kind?.name ?? '',
      ..._answers,
      'm': _message.text.trim(),
      'e': _email.text.trim(),
      'l': Lang.current.value,
      if (_withDevice) 'd': deviceInfo(MediaQuery.of(context).size),
    };
    final opened = await _open(Uri.parse('$siteUrl/#escribir?${Uri(queryParameters: data).query}'));
    if (!opened && mounted) setState(() => _failed = true);
  }

  bool get _ready => _something && !_sending && (!canSendOnline || _captcha != null);

  Future<void> _send() async {
    if (!kIsWeb) return _openWebsite();
    if (!canSendOnline) return _openEmail();
    setState(() {
      _sending = true;
      _failed = false;
    });
    final ok = await sendFeedback({
      'kind': _kind?.name ?? '',
      ..._answers,
      'message': _message.text.trim(),
      'email': _email.text.trim(),
      'details': _withDevice && mounted ? _details(context) : '',
      'lang': Lang.current.value,
      'token': _captcha ?? '',
    });
    if (!mounted) return;
    setState(() {
      _sending = false;
      _done = ok;
      _failed = !ok;
      _captcha = null;
      _captchaRun++;
    });
    if (ok) _say(_thanks);
  }

  void _say(String line) {
    if (Settings.voice.value) Speech.instance.say(line);
  }

  String get _thanks => tr(
    '¡Gracias! Ya nos llegó tu mensaje. Lo leemos todo, aunque no siempre podamos contestar.',
    "Thank you! Your message reached us. We read everything, even when we can't always reply.",
  );

  @override
  void dispose() {
    _message.dispose();
    _email.dispose();
    super.dispose();
  }

  InputDecoration _field(String label, {String? hint, String? help}) => InputDecoration(
    labelText: label,
    hintText: hint,
    helperText: help,
    helperMaxLines: 3,
    helperStyle: const TextStyle(color: Pk.textSoft, fontSize: 13),
    labelStyle: const TextStyle(color: Pk.textSoft),
    hintStyle: const TextStyle(color: Pk.textSoft),
    floatingLabelBehavior: FloatingLabelBehavior.always,
    filled: true,
    fillColor: Pk.field,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Pk.rim),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Pk.rim),
    ),
  );

  Widget _tile(_Kind k) {
    final on = _kind == k;
    return Semantics(
      button: true,
      selected: on,
      label: _nameOf(k),
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() => _kind = k);
          hear([_nameOf(k)]);
        },
        child: Container(
          width: 96,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: on ? Pk.note : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: on ? Pk.gold : Colors.transparent, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PictogramTile(_pictureOf(k), size: 72, frame: on ? Pk.gold : Pk.rim),
              const SizedBox(height: 6),
              Text(
                _nameOf(k),
                textAlign: TextAlign.center,
                style: TextStyle(color: on ? Pk.gold : Pk.text, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// One question and its three answers. Tapping a chosen answer again takes it back.
  Widget _question(String name, String question) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: tr('Escuchar', 'Listen'),
              icon: const Icon(Icons.volume_up, color: Pk.gold),
              onPressed: () => Speech.instance.say(question),
            ),
            Expanded(
              child: Text(
                question,
                style: const TextStyle(color: Pk.text, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (value, picture, label) in _answerChoices)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: _answers[name] == value,
                  label: '$question $label',
                  excludeSemantics: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      setState(() => _answers[name] == value ? _answers.remove(name) : _answers[name] = value);
                      hear([label]);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _answers[name] == value ? Pk.note : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _answers[name] == value ? Pk.gold : Colors.transparent, width: 2),
                      ),
                      child: Column(
                        children: [
                          PictogramTile(picture, size: 44, frame: _answers[name] == value ? Pk.gold : Pk.rim),
                          const SizedBox(height: 2),
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                            softWrap: false,
                            style: TextStyle(
                              color: _answers[name] == value ? Pk.gold : Pk.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );

  Widget get _otherWays => PkPanel(
    color: Pk.note,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(
            'No se pudo enviar por aquí. Puedes mandarlo desde tu correo a $contactEmail:',
            "It couldn't be sent from here. You can send it from your email to $contactEmail:",
          ),
          style: const TextStyle(color: Pk.gold, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            PkButton(tr('Abrir mi correo', 'Open my email'), expand: false, onPressed: _openEmail),
            PkButton(
              tr('Copiar mensaje', 'Copy message'),
              expand: false,
              color: Pk.cardHi,
              textColor: Pk.text,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: '$contactEmail\n\n${_plain(context)}'));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Copiado', 'Copied'))));
              },
            ),
          ],
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final blocked = _failed || _captchaFailed;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Escríbenos', 'Write to us')),
        actions: [
          ReadScreenButton(lines: () => _done ? [_thanks] : _lines),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Penko(pose: _done ? PenkoPose.jump : PenkoPose.talk, size: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: PkPanel(
                    color: Pk.dialog,
                    child: Text(
                      _done
                          ? _thanks
                          : _step == 0
                          ? FeedbackScreen._askLine
                          : FeedbackScreen._moreLine,
                      style: const TextStyle(color: Pk.onDialog, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
            if (!_done && _step == 0) ...[
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                runSpacing: 4,
                children: [for (final k in _Kind.values) _tile(k)],
              ),
              for (final (name, question) in _questions) _question(name, question),
              const SizedBox(height: 16),
              PkButton(
                tr('Siguiente', 'Next'),
                leading: const Icon(Icons.arrow_forward, color: Pk.onGold),
                onPressed: _something ? () => setState(() => _step = 1) : null,
              ),
            ],
            if (!_done && _step == 1) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _step = 0),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: Text(tr('Volver a los dibujos', 'Back to the pictures')),
                ),
              ),
              TextField(
                controller: _message,
                minLines: 2,
                maxLines: 10,
                maxLength: 3000,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: Pk.text),
                decoration: _field(
                  tr('Cuéntanos más (opcional)', 'Tell us more (optional)'),
                  hint: tr(
                    'Si algo falló, dinos en qué pantalla y qué hiciste antes.',
                    'If something failed, tell us which screen and what you did just before.',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                style: const TextStyle(color: Pk.text),
                decoration: _field(
                  tr('Tu correo (opcional)', 'Your email (optional)'),
                  help: tr(
                    'Solo si quieres respuesta. Si eres menor de edad, déjalo vacío o pide ayuda a un adulto.',
                    "Only if you'd like a reply. If you're a child, leave it empty or ask an adult to help.",
                  ),
                ),
              ),
              if (canSendOnline && !_captchaFailed) ...[
                const SizedBox(height: 4),
                Center(
                  child: CaptchaBox(
                    key: ValueKey(_captchaRun),
                    onToken: (t) => setState(() => _captcha = t),
                    onFailed: () => setState(() => _captchaFailed = true),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (blocked) ...[_otherWays, const SizedBox(height: 12)],
              if (!_captchaFailed)
                PkButton(
                  _sending
                      ? tr('Enviando…', 'Sending…')
                      : !kIsWeb
                      ? tr('Seguir en el navegador', 'Continue in the browser')
                      : canSendOnline
                      ? tr('Enviar', 'Send')
                      : tr('Abrir mi correo para enviarlo', 'Open my email app to send it'),
                  onPressed: _ready ? _send : null,
                ),
              if (!blocked && canSendOnline)
                TextButton(
                  onPressed: () => setState(() => _failed = true),
                  child: Text(tr('Prefiero usar mi correo', "I'd rather use my email")),
                ),
              const SizedBox(height: 4),
              CheckboxListTile(
                value: _withDevice,
                onChanged: (v) => setState(() => _withDevice = v ?? true),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  tr('Incluir datos técnicos', 'Include technical details'),
                  style: const TextStyle(color: Pk.text),
                ),
                subtitle: Text(_details(context), style: const TextStyle(color: Pk.textSoft, fontSize: 12)),
              ),
              const SizedBox(height: 4),
              Text(
                '${FeedbackScreen._privacyLine} ${tr('Solo el equipo de Penko lee lo que mandas.', 'Only the Penko team reads what you send.')}',
                style: const TextStyle(color: Pk.textSoft, fontSize: 13),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => _open(privacyPage),
                  child: Text(tr('Aviso de privacidad', 'Privacy notice')),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
