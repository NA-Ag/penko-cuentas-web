// send_web.dart — the website sends a message to our gateway (feedback-worker/) after a Cloudflare Turnstile check that
// the sender is a person. It normally asks nothing of them: no picture puzzles. Turnstile's script is only loaded when
// the form is opened, so nobody else hears of a visit otherwise.
import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import '../i18n/lang.dart';
import 'feedback_config.dart';

const canSendOnline = feedbackUrl != '';

String deviceInfo(Size screen) =>
    'Web · ${web.window.navigator.userAgent} · ${screen.width.round()}×${screen.height.round()}';

/// True when the gateway accepted the message
Future<bool> sendFeedback(Map<String, String> fields) async {
  try {
    final headers = web.Headers()..append('Content-Type', 'application/json');
    final res = await web.window
        .fetch(feedbackUrl.toJS, web.RequestInit(method: 'POST', headers: headers, body: jsonEncode(fields).toJS))
        .toDart
        .timeout(const Duration(seconds: 20));
    final body = (await res.json().toDart).dartify();
    return res.ok && body is Map && body['ok'] == true;
  } catch (_) {
    return false;
  }
}

/// The phone app opens the form as …/#escribir?m=…, keeping the message after the '#', which never leaves the browser.
/// It's taken out of the address at once, so it isn't left in the page's address.
Map<String, String>? takeFeedbackLink() {
  final hash = web.window.location.hash;
  if (!hash.startsWith('#escribir')) return null;
  web.window.history.replaceState(null, '', web.window.location.pathname);
  final at = hash.indexOf('?');
  return at < 0 ? {} : Uri.splitQueryString(hash.substring(at + 1));
}

/// Tells screen readers which language the page is in
void setPageLang(String lang) => web.document.documentElement?.setAttribute('lang', lang);

@JS('turnstile')
external _Turnstile? get _turnstile;

extension type _Turnstile._(JSObject _) implements JSObject {
  external JSAny render(web.HTMLElement container, JSObject options);
  external void remove(JSAny widget);
}

Future<void>? _loading;

/// Turnstile's script, loaded once, the first time a form is opened
Future<void> _loadScript() => _loading ??= () async {
  if (_turnstile != null) return;
  final done = Completer<void>();
  final script = web.HTMLScriptElement()
    ..src = 'https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit'
    ..async = true;
  script.onload = ((web.Event _) => done.complete()).toJS;
  script.onerror = ((web.Event _) => done.completeError('Turnstile script')).toJS;
  web.document.head!.append(script);
  await done.future.timeout(const Duration(seconds: 20));
  for (var i = 0; i < 50 && _turnstile == null; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}();

var _views = 0;

/// Turnstile's small box. [onToken] gets its answer (null when it expires); [onFailed] says it can't work here, for
/// example behind a blocker, so the form can offer another way.
class CaptchaBox extends StatefulWidget {
  final ValueChanged<String?> onToken;
  final VoidCallback onFailed;
  const CaptchaBox({super.key, required this.onToken, required this.onFailed});
  @override
  State<CaptchaBox> createState() => _CaptchaBoxState();
}

class _CaptchaBoxState extends State<CaptchaBox> {
  late final String _type = 'penko-turnstile-${_views++}';
  bool _failed = false;
  bool _narrow = false;
  JSAny? _widget; // Turnstile's, removed with this box: it would otherwise keep calling back

  void _token(String? token) {
    if (mounted) widget.onToken(token);
  }

  void _fail() {
    if (!mounted) return;
    widget.onToken(null);
    widget.onFailed();
    setState(() => _failed = true);
  }

  @override
  void dispose() {
    if (_widget != null) _turnstile?.remove(_widget!);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _narrow = MediaQuery.of(context).size.width < 340;
  }

  @override
  void initState() {
    super.initState();
    final box = web.HTMLDivElement()
      ..style.width = '100%'
      ..style.height = '100%';
    ui_web.platformViewRegistry.registerViewFactory(_type, (int _) => box);
    _loadScript().then((_) {
      final t = _turnstile;
      if (t == null) throw StateError('no Turnstile');
      final options = JSObject()
        ..setProperty('sitekey'.toJS, turnstileSiteKey.toJS)
        ..setProperty('action'.toJS, 'feedback'.toJS)
        ..setProperty('theme'.toJS, 'dark'.toJS)
        ..setProperty('language'.toJS, (Lang.en ? 'en' : 'es').toJS)
        ..setProperty('size'.toJS, (_narrow ? 'compact' : 'normal').toJS)
        ..setProperty('callback'.toJS, ((JSString token) => _token(token.toDart)).toJS)
        ..setProperty('expired-callback'.toJS, (() => _token(null)).toJS)
        ..setProperty('error-callback'.toJS, _fail.toJS);
      // The element is in the page once Flutter has laid it out
      Future<void>.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _widget = t.render(box, options);
      });
    }).catchError((Object _) => _fail());
  }

  @override
  Widget build(BuildContext context) => _failed
      ? const SizedBox.shrink()
      : SizedBox(width: _narrow ? 150 : 300, height: _narrow ? 140 : 65, child: HtmlElementView(viewType: _type));
}
