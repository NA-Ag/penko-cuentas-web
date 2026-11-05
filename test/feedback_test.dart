// The phone app's way of writing to us: no internet of its own, so it opens the website's form, with email as a way out.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penko_math/screens/feedback_screen.dart';
import 'package:penko_math/wayfinding/wayfinding.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _Launcher extends UrlLauncherPlatform with MockPlatformInterfaceMixin {
  bool works = true;
  final opened = <String>[];
  @override
  LinkDelegate? get linkDelegate => null;
  @override
  Future<bool> canLaunch(String url) async => works;
  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    opened.add(url);
    return works;
  }
}

void main() {
  late _Launcher launcher;
  setUp(() {
    launcher = _Launcher();
    UrlLauncherPlatform.instance = launcher;
    wayfindingVoice = (_, _) async {};
  });

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(480, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: FeedbackScreen()));
  }

  /// Taps [choice], then goes on to the second step
  Future<void> next(WidgetTester tester, String choice) async {
    await tester.tap(find.text(choice).first);
    await tester.pump();
    await tester.tap(find.text('Siguiente'));
    await tester.pump();
  }

  testWidgets('one tapped answer is enough too, and travels with the link', (tester) async {
    await open(tester);
    await next(tester, 'Más o menos');
    await tester.tap(find.text('Seguir en el navegador'));
    await tester.pump();
    expect(Uri.splitQueryString(Uri.parse(launcher.opened.single).fragment.split('?').last)['easy'], 'some');
  });

  testWidgets('a picture is enough: nobody has to write', (tester) async {
    await open(tester);
    await tester.tap(find.text('Siguiente'));
    await tester.pump();
    expect(find.text('Seguir en el navegador'), findsNothing, reason: 'nothing chosen yet');
    await next(tester, 'No entendí');
    await tester.tap(find.text('Seguir en el navegador'));
    await tester.pump();
    expect(launcher.opened.single, startsWith('https://cuentas.penkosoftware.org/#escribir?k=confused'));
  });

  testWidgets('what was written goes after the #, which never leaves the browser', (tester) async {
    await open(tester);
    await next(tester, 'Una queja');
    await tester.enterText(find.byType(TextField).first, 'No carga');
    await tester.pump();
    await tester.tap(find.text('Seguir en el navegador'));
    await tester.pump();
    final url = Uri.parse(launcher.opened.single);
    expect(url.query, isEmpty);
    expect(Uri.splitQueryString(url.fragment.split('?').last)['m'], 'No carga');
  });

  testWidgets('with no browser or email app, the message can still be copied', (tester) async {
    launcher.works = false;
    await open(tester);
    await next(tester, 'Algo falló');
    await tester.tap(find.text('Seguir en el navegador'));
    await tester.pump();
    expect(find.text('Copiar mensaje'), findsOneWidget);
  });
}
