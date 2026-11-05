import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penko_math/art/palette.dart';
import 'package:penko_math/audio/voice_keys.dart';
import 'package:penko_math/data/settings.dart';
import 'package:penko_math/glossary/pictograms.dart';
import 'package:penko_math/i18n/lang.dart';
import 'package:penko_math/screens/calc/calculators.dart';
import 'package:penko_math/screens/course.dart';
import 'package:penko_math/screens/home_screen.dart';
import 'package:penko_math/screens/path_screen.dart';
import 'package:penko_math/ui/money_pile.dart';
import 'package:penko_math/wayfinding/wayfinding.dart';

/// WCAG contrast ratio between two colours
double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

void expectPicture(Pic p, String reason) {
  const colours = 'kwetdyosglGbBrcpmn.';
  expect(p.length, 32, reason: reason);
  for (final row in p) {
    expect(row.length, 32, reason: reason);
    expect(row.split('').every(colours.contains), isTrue, reason: '$reason: $row');
  }
  expect(p.join().replaceAll('.', '').length, greaterThan(20), reason: reason);
}

void main() {
  tearDown(() => Lang.current.value = 'es');

  test('every tab, unit, simulator and resource group has a pictogram and a spoken name and line in es and en', () {
    Lang.current.value = 'es';
    final es = allPlaces;
    Lang.current.value = 'en';
    final en = allPlaces;
    expect(es.length, en.length);
    expect({for (final p in es) p.id}.length, es.length, reason: 'ids are unique');
    for (var i = 0; i < es.length; i++) {
      expect(en[i].id, es[i].id);
      expectPicture(es[i].picture, es[i].id);
      for (final p in [es[i], en[i]]) {
        expect(p.name.trim(), isNotEmpty, reason: p.id);
        expect(p.about.trim(), isNotEmpty, reason: p.id);
        expect(p.lines, [p.name, p.about]);
      }
      expect(RegExp(r'[¿¡ñáéíóú]').hasMatch('${en[i].name} ${en[i].about}'), isFalse, reason: '${es[i].id}: Spanish left in English');
    }
    // The four tabs, every unit and every simulator, each with a picture of its own
    expect(tabPlaces.length, 4);
    for (final group in [tabPlaces, unitPlaces.values.toList(), simPlaces.values.toList()]) {
      expect({for (final p in group) p.picture.join()}.length, group.length, reason: 'pictures differ within a group');
    }
  });

  test('every place and lesson name has a voice key, in both languages', () {
    for (final lang in ['es', 'en']) {
      Lang.current.value = lang;
      final lines = voiceLines();
      for (final p in allPlaces) {
        expect(lines[p.nameKey], p.name, reason: p.id);
        expect(lines[p.aboutKey], p.about, reason: p.id);
      }
      for (final u in course) {
        for (final l in u.lessons) {
          expect(lines[lessonTitleKey(l.id)], l.title, reason: l.id);
        }
      }
      for (final e in navLines.entries) {
        expect(lines[e.key], e.value);
      }
      expect(lines.keys.every(RegExp(r'^[a-z0-9_.-]+$').hasMatch), isTrue);
    }
  });

  test('every unit and lesson on the path has its sign, and each unit its own colour that reads well', () {
    for (final lang in ['es', 'en']) {
      Lang.current.value = lang;
      expect(course.length, unitPlaces.length);
      for (final u in course) {
        expect(u.place.name, u.title);
        expect(u.place.about, u.about);
        final pictures = <String>{};
        for (final l in u.lessons) {
          expect(lessonPictures[l.id], isNotNull, reason: '${l.id} has a picture');
          expectPicture(l.picture, l.id);
          pictures.add(l.picture.join());
        }
        expect(pictures.length, u.lessons.length, reason: '${u.key}: each lesson its own picture');
      }
    }
    expect({for (final u in course) u.color}.length, course.length, reason: 'a colour per unit, like Metro lines');
    for (final u in course) {
      // The banner's dark text on the unit's colour, and the unit's colour as a lesson title on the background
      expect(contrast(u.color, Pk.onGold), greaterThanOrEqualTo(4.5), reason: u.key);
      expect(contrast(u.color, Pk.paper), greaterThanOrEqualTo(4.5), reason: u.key);
    }
  });

  test('every simulator on the tab has a sign, and links to a lesson that exists', () {
    for (final lang in ['es', 'en']) {
      Lang.current.value = lang;
      final lessons = {for (final u in course) for (final l in u.lessons) l.id};
      for (final s in simulators) {
        expect(simPlaces.values.map((p) => p.id), contains(s.place.id));
        expect(lessons, contains(s.lesson));
        expect(contrast(s.color, Pk.card), greaterThanOrEqualTo(3), reason: '${s.place.id}: its frame shows on a card');
      }
      expect(simulators.length + 1, simPlaces.length, reason: 'every simulator, plus the well-being check');
    }
  });

  test('coins and bills: the breakdown adds back up to the amount, with the fewest pieces', () {
    expect(breakdown(0), isEmpty);
    expect(breakdown(-5), isEmpty);
    final values = [for (var v = 1; v <= 5000; v++) v, 9999, 12345, 100000, 987654];
    final r = Random(1);
    values.addAll([for (var i = 0; i < 200; i++) r.nextInt(2000000) + 1]);
    for (final v in values) {
      final parts = breakdown(v);
      expect(parts.fold<int>(0, (t, p) => t + p.$1.value * p.$2), v, reason: '$v');
      // Biggest first, each kind once, and never so many of one that a bigger one would do
      for (var i = 1; i < parts.length; i++) {
        expect(parts[i].$1.value, lessThan(parts[i - 1].$1.value), reason: '$v');
      }
      for (final (d, n) in parts) {
        expect(n, greaterThan(0));
        if (d.value < 1000) expect(n, lessThan(3), reason: '$v: ${d.value} × $n');
      }
      expect(parts.length, lessThanOrEqualTo(10));
    }
    // $1,700: one $1000, one $500 and one $200
    expect([for (final (d, n) in breakdown(1700)) (d.value, d.coin, n)], [(1000, false, 1), (500, false, 1), (200, false, 1)]);
    expect([for (final (d, n) in breakdown(38)) (d.value, d.coin, n)], [(20, false, 1), (10, true, 1), (5, true, 1), (2, true, 1), (1, true, 1)]);
  });

  test('coins and bills are drawn: coins 16 × 16, bills 28 × 14, every value in its own colours', () {
    expect([for (final c in coins) c.value], [1, 2, 5, 10, 20]);
    expect([for (final b in bills) b.value], [20, 50, 100, 200, 500, 1000]);
    for (final d in [...coins, ...bills]) {
      expect(d.grid.length, d.coin ? 16 : 14, reason: d.id);
      for (final row in d.grid) {
        expect(row.length, d.coin ? 16 : 28, reason: d.id);
        for (final c in row.codeUnits) {
          if (c != 0x2E) expect(moneyPalette[c], isNotNull, reason: '${d.id}: ${String.fromCharCode(c)}');
        }
      }
    }
    expect({for (final d in [...coins, ...bills]) d.grid.join()}.length, coins.length + bills.length);
  });

  testWidgets('a big amount shows compactly as a few stacks', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: MoneyPile(3720))));
    expect(find.byType(MoneyPicture), findsNWidgets(3 + 1 + 1 + 1)); // three $1000 (stacked), one $500, one $200, one $20 bill
    expect(find.text('× 3'), findsOneWidget);
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: MoneyPile(100000))));
    expect(find.byType(MoneyPicture), findsNWidgets(MoneyPile.stack));
    expect(find.text('× 100'), findsOneWidget);
  });

  testWidgets('holding a simulator or a tab down makes Penko say its name and what is inside; a tap still opens it', (tester) async {
    Lang.current.value = 'es';
    final heard = <List<String>>[];
    final before = wayfindingVoice;
    wayfindingVoice = (lines, keys) async => heard.add(lines);
    addTearDown(() {
      wayfindingVoice = before;
      Settings.voice.value = false;
    });
    Settings.voice.value = true;
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CalculatorsScreen())));
    final budget = simPlaces['budget']!;
    await tester.scrollUntilVisible(find.text(budget.name), 200);
    await tester.longPress(find.text(budget.name));
    expect(heard.last, [budget.name, budget.about]);
    // With the voice off, holding down says nothing
    Settings.voice.value = false;
    await tester.longPress(find.text(budget.name));
    expect(heard.length, 1);
    // A tap still opens the simulator
    await tester.tap(find.text(budget.name));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('read-screen')), findsOneWidget);
    await tester.scrollUntilVisible(find.byType(MoneyPile), 300);
    expect(find.byType(MoneyPile), findsOneWidget, reason: 'what is left, shown as money');
  });

  testWidgets('the tabs have pictures; holding one down says its name, and the path says where to tap', (tester) async {
    Lang.current.value = 'es';
    final heard = <List<String>>[];
    final before = wayfindingVoice;
    wayfindingVoice = (lines, keys) async => heard.add(lines);
    addTearDown(() {
      wayfindingVoice = before;
      Settings.voice.value = false;
    });
    Settings.voice.value = true;
    PathScreen.toldWhereToTap = false;
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    // The path loads the saved progress (real file work, outside the test's fake time)
    for (var i = 0; i < 5 && heard.isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    // The first time, Penko says to tap the big yellow button and names the next lesson
    expect(heard.first.first, navLines['nav.path_next']);
    expect(find.byKey(const ValueKey('path-next')), findsOneWidget);
    expect(find.byType(PictogramTile), findsWidgets);
    final sims = tabPlaces[1];
    await tester.longPress(find.text(sims.name));
    expect(heard.last, [sims.name, sims.about]);
    // A tap still changes the tab
    await tester.tap(find.text(sims.name));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(simPlaces['loan']!.name), findsOneWidget);
    expect(find.byKey(const ValueKey('read-screen')), findsOneWidget);
  });
}
