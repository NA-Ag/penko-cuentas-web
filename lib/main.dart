// Penko Cuentas Claras — maths and everyday money with Penko, offline ("cuentas claras, amistades largas"). Free and
// open source (GPL-3.0).
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/reminders.dart';
import 'data/settings.dart';
import 'data/store.dart';
import 'feedback/send.dart';
import 'i18n/lang.dart';
import 'screens/feedback_screen.dart';
import 'screens/home_screen.dart';
import 'screens/test_panels.dart';
import 'screens/welcome_screen.dart';
import 'ui/pixel_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Settings.load();
  await Lang.load();
  final link = takeFeedbackLink(); // the phone app sends people to the form here
  if (link != null && (link['l'] == 'es' || link['l'] == 'en')) Lang.current.value = link['l']!;
  Lang.current.addListener(() => setPageLang(Lang.current.value));
  setPageLang(Lang.current.value);
  // On the web a screen reader would otherwise have to find and press a hidden button first
  if (kIsWeb) SemanticsBinding.instance.ensureSemantics();
  Reminders.instance.reschedule(); // plans the coming week again, if reminders are on
  runApp(PenkoMathApp(welcomed: await Store.get<bool>('welcomed') ?? false, link: link));
}

class PenkoMathApp extends StatelessWidget {
  final bool welcomed; // false the first time: Penko says hello first
  final Map<String, String>? link; // set when opened straight on the feedback form
  const PenkoMathApp({super.key, this.welcomed = true, this.link});

  // Flutter's own words (the back button's name, "characters remaining") in the app's language
  static const _material = GlobalMaterialLocalizations.delegates;
  static const _languages = [Locale('es'), Locale('en')];

  // One per language, because a key kept across languages would carry the old screens over. The panels beside the app
  // sit outside its navigator and open the feedback form through this.
  static final _navigators = <String, GlobalKey<NavigatorState>>{};

  // The whole app is built again when the language changes (Ajustes, or the welcome screen's first page)
  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: Lang.current,
    builder: (context, lang, _) => kIsWeb ? _layout(lang) : _app(lang),
  );

  /// The website: on a computer the app keeps a phone's width, centred, and with room to spare the testers' panels
  /// fill the bare sides (test_panels.dart). Each panel is a small app of its own, for its text field and dialog.
  Widget _layout(String lang) => LayoutBuilder(
    builder: (context, box) {
      final width = box.maxWidth;
      final sides = width >= sidesWidth;
      Widget side(String name, Widget child) => Flexible(
        key: ValueKey(name),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          // Its own semantics node: otherwise each app's screen hides the app before it from screen readers
          child: Semantics(
            container: true,
            child: MaterialApp(
              key: ValueKey('$name-$lang'),
              title: 'Penko Cuentas Claras',
              locale: Locale(lang),
              localizationsDelegates: _material,
              supportedLocales: _languages,
              debugShowCheckedModeBanner: false,
              theme: penkoTheme(),
              home: Scaffold(backgroundColor: const Color(0xFF0E1426), body: child),
            ),
          ),
        ),
      );
      return Directionality(
        textDirection: TextDirection.ltr,
        child: ColoredBox(
          color: const Color(0xFF0E1426),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (sides)
                side('info', TestInfo(onWrite: () => _navigators[lang]?.currentState?.push(MaterialPageRoute(builder: (_) => const FeedbackScreen())))),
              // Keyed so the app keeps its place when a resized window gains or loses the panels
              SizedBox(key: const ValueKey('app'), width: width > phoneWidth ? 480 : width, child: Semantics(container: true, child: _app(lang))),
              if (sides) side('notes', const NotesPad()),
            ],
          ),
        ),
      );
    },
  );

  Widget _app(String lang) => MaterialApp(
    // A new key per language: every screen is built again in the new language (the app starts again from its first
    // screen; Ajustes asks HomeScreen to open on its own tab)
    key: ValueKey(lang),
    navigatorKey: _navigators[lang] ??= GlobalKey<NavigatorState>(),
    title: 'Penko Cuentas Claras',
    locale: Locale(lang),
    localizationsDelegates: _material,
    supportedLocales: _languages,
    initialRoute: '/', // never the address's '#' part
    // A changed '#' in an open page arrives as a route: a link to the form opens it, anything else goes home
    onUnknownRoute: (route) => MaterialPageRoute(
      builder: (_) => route.name?.contains('escribir') ?? false ? const FeedbackScreen() : const HomeScreen(),
    ),
    debugShowCheckedModeBanner: false,
    theme: penkoTheme(),
    // WelcomeScreen.done: the welcome was finished in this run, so a language change doesn't show it again
    home: link != null
        ? FeedbackScreen(link: link)
        : welcomed || WelcomeScreen.done
        ? const HomeScreen()
        : const WelcomeScreen(),
    // Bigger text multiplies whatever size the phone already uses
    builder: (context, child) => ValueListenableBuilder(
      valueListenable: Settings.bigText,
      builder: (context, big, _) {
        final media = MediaQuery.of(context);
        // On a computer's browser the app keeps a phone's width (see _layout)
        final wide = kIsWeb && media.size.width > phoneWidth;
        final app = MediaQuery(
          data: media.copyWith(
            textScaler: big ? _Scaled(media.textScaler, 1.25) : media.textScaler,
            size: wide ? Size(480, media.size.height) : media.size,
          ),
          child: child!,
        );
        return app;
      },
    ),
  );
}

class _Scaled extends TextScaler {
  final TextScaler base;
  final double factor;
  const _Scaled(this.base, this.factor);
  @override
  double scale(double fontSize) => base.scale(fontSize) * factor;
  @override
  double get textScaleFactor => base.scale(14) / 14 * factor;
}
