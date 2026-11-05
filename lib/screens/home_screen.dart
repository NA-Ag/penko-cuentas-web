// home_screen.dart — the app's frame: Penko's name at the top and tabs at the bottom, like the apps people already
// know: "Aprender" (the path of lessons), "Simuladores" (money to play with), "Recursos" (official sites) and
// "Ajustes" (voice, text size, privacy). Each tab has its own picture and colour, like a Metro station.
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../ai/tutor.dart';
import '../art/palette.dart';
import '../art/penko.dart';
import '../data/progress.dart';
import '../data/reminders.dart';
import '../data/settings.dart';
import '../i18n/lang.dart';
import '../ui/pixel_ui.dart';
import '../wayfinding/wayfinding.dart';
import 'calc/calculators.dart';
import 'feedback_screen.dart';
import 'path_screen.dart';
import 'progress_screen.dart';
import 'resources_screen.dart';
import 'test_panels.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  /// The tab to open on next time (the language selector in Ajustes sets it: a new language builds the app again)
  static int startTab = 0;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = HomeScreen.startTab;
  final _path = ReadSlot(); // the path tells the "read this screen" button what it shows

  @override
  void initState() {
    super.initState();
    HomeScreen.startTab = 0;
  }

  /// What the "read this screen" button reads: the tab being shown
  List<String> _read() => switch (_tab) {
    0 => _path.lines(),
    1 => CalculatorsScreen.readLines(),
    2 => ResourcesScreen.readLines(),
    _ => _SettingsPage.readLines(),
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
              children: [
                const Penko(pose: PenkoPose.idle, size: 40),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Penko Cuentas Claras', style: TextStyle(fontFamily: pixelFont, fontSize: 20, color: Pk.gold)),
                ),
                IconButton(
                  tooltip: tr('Mi avance', 'My progress'),
                  icon: const Icon(Icons.insights, color: Pk.gold),
                  onPressed: () async {
                    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProgressScreen()));
                    setState(() {}); // the path rebuilds with the latest progress
                  },
                ),
                ReadScreenButton(lines: _read),
              ],
            ),
          ),
          // Each tab is built fresh when opened, so the path always shows the latest progress
          Expanded(
            child: switch (_tab) {
              0 => PathScreen(reader: _path),
              1 => const CalculatorsScreen(),
              2 => const ResourcesScreen(),
              _ => const _SettingsPage(),
            },
          ),
        ],
      ),
    ),
    // Each tab has its own picture and colour; held down, Penko says its name and what's inside
    bottomNavigationBar: NavigationBar(
      selectedIndex: _tab,
      onDestinationSelected: (i) => setState(() => _tab = i),
      height: 84,
      indicatorColor: Colors.transparent, // the open tab's picture gets its colour frame instead
      destinations: [
        for (final p in tabPlaces)
          Hear.place(
            p,
            key: ValueKey('tab-${p.id}'),
            child: NavigationDestination(
              icon: _TabPicture(p, selected: false),
              selectedIcon: _TabPicture(p, selected: true),
              label: p.name,
              tooltip: '', // holding it down speaks instead
            ),
          ),
      ],
    ),
  );
}

/// A tab's pictogram: framed in its colour when it's the one open
class _TabPicture extends StatelessWidget {
  final Place place;
  final bool selected;
  const _TabPicture(this.place, {required this.selected});

  @override
  Widget build(BuildContext context) =>
      PictogramTile(place.picture, size: 40, frame: selected ? placeColour(place.id) : Pk.rim);
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  /// What the "read this screen" button reads on this tab: each setting and how it's set now
  static List<String> readLines() {
    String onOff(bool on) => on ? tr('encendido', 'on') : tr('apagado', 'off');
    return [
      tabPlaces[3].name,
      '${tr('Idioma', 'Language')}: ${Lang.en ? 'English' : 'Español'}',
      '${tr('Penko lee en voz alta', 'Penko reads aloud')}: ${onOff(Settings.voice.value)}',
      '${tr('Letra más grande', 'Bigger text')}: ${onOff(Settings.bigText.value)}',
      tr('Escríbenos', 'Write to us'),
      tr('Borrar mi avance', 'Delete my progress'),
    ];
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
    children: [
      PlaceHeading(tabPlaces[3], colour: placeColour('tab.settings')),
      const SizedBox(height: 8),
      // The language: the whole app is built again in it (and opens back here)
      ListTile(
        leading: const Icon(Icons.translate, color: Pk.gold),
        title: Text(tr('Idioma', 'Language')),
        // Under the title, not beside it: two buttons side by side fit even with big text
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'es', label: Text('Español')),
              ButtonSegment(value: 'en', label: Text('English')),
            ],
            selected: {Lang.current.value},
            onSelectionChanged: (s) async {
              HomeScreen.startTab = 3;
              await Lang.set(s.first);
              Reminders.instance.reschedule(); // the week's reminders, in the new language
            },
          ),
        ),
      ),
      ValueListenableBuilder(
        valueListenable: Settings.voice,
        builder: (_, on, _) =>
            SwitchListTile(title: Text(tr('Penko lee en voz alta', 'Penko reads aloud')), value: on, onChanged: Settings.setVoice),
      ),
      ValueListenableBuilder(
        valueListenable: Settings.bigText,
        builder: (_, on, _) =>
            SwitchListTile(title: Text(tr('Letra más grande', 'Bigger text')), value: on, onChanged: Settings.setBigText),
      ),
      if (!kIsWeb) const _ReminderTile(), // phone notifications; the web version has none
      // A problem, a complaint or an idea: the form here on the web; on the phone it continues in the browser
      ListTile(
        leading: const Icon(Icons.mail_outline, color: Pk.gold),
        title: Text(tr('Escríbenos', 'Write to us')),
        subtitle: Text(tr('¿Algo no funciona o tienes una idea? Cuéntanos.', 'Something broken, or an idea? Tell us.'),
            style: const TextStyle(color: Pk.textSoft)),
        trailing: const Icon(Icons.chevron_right, color: Pk.textSoft),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FeedbackScreen())),
      ),
      // Beside the app on a wide screen; here when there's no room for them
      if (kIsWeb && !sidesShown) ...[
        ListTile(
          leading: const Icon(Icons.info_outline, color: Pk.gold),
          title: Text(testInfoTitle),
          trailing: const Icon(Icons.chevron_right, color: Pk.textSoft),
          onTap: () => Navigator.of(context).push(panelPage(
            testInfoTitle,
            TestInfo(onWrite: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FeedbackScreen()))),
          )),
        ),
        ListTile(
          leading: const Icon(Icons.edit_note, color: Pk.gold),
          title: Text(notesTitle),
          trailing: const Icon(Icons.chevron_right, color: Pk.textSoft),
          onTap: () => Navigator.of(context).push(panelPage(notesTitle, const NotesPad())),
        ),
      ],
      // Whether Penko's tutor model is on this phone
      ListTile(
        leading: const Icon(Icons.psychology_alt_outlined, color: Pk.gold),
        title: Text(tr('Las respuestas de Penko (¿Por qué?, tickets)', "Penko's answers (Why?, receipts)")),
        subtitle: FutureBuilder(
          future: Tutor.instance.status(),
          builder: (_, s) => Text(s.data ?? '…', style: const TextStyle(color: Pk.textSoft)),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          // The web version loads from the internet once, but saves nothing online either
          tr(
            '${kIsWeb ? 'Esta página no usa cuentas, anuncios ni rastreadores, y solo nos llega lo que tú nos mandes. Solo guarda' : 'Esta app no usa internet ni cuentas. Solo guarda'} qué lecciones terminaste y cómo te fue al primer intento, '
            'estos ajustes, ${kIsWeb ? 'tus notas, ' : ''}el día de tu última práctica${kIsWeb ? '' : ' (para no recordarte ese día)'} y, si lo contestas, tu resultado de '
            '"¿Cómo estoy con mi dinero?" con su fecha. ${kIsWeb ? 'Todo se queda en este navegador.' : 'Todo se queda en este teléfono.'}\n\nPenko Cuentas Claras es software libre (GPL-3.0) y gratuito. '
            'Escríbenos: contact@penkosoftware.org',
            '${kIsWeb ? "This page has no accounts, ads or trackers, and we only receive what you send us. It only keeps" : "This app uses no internet and no accounts. It only keeps"} which lessons you finished and how they went at the first try, '
            'these settings, ${kIsWeb ? 'your notes, ' : ''}the day you last practiced${kIsWeb ? '' : ' (so it doesn\'t remind you that day)'} and, if you answer it, your '
            '"How am I doing with money?" score with its date. ${kIsWeb ? 'Everything stays in this browser.' : 'Everything stays on this phone.'}\n\nPenko Cuentas Claras is free and open-source software (GPL-3.0). '
            'Write to us: contact@penkosoftware.org',
          ),
          style: const TextStyle(color: Pk.textSoft, fontSize: 14),
        ),
      ),
      TextButton(
        onPressed: () async {
          final sure = await showDialog<bool>(
            context: context,
            builder: (d) => AlertDialog(
              backgroundColor: Pk.card,
              title: Text(tr('¿Borrar tu avance?', 'Delete your progress?')),
              content: Text(tr('Las lecciones terminadas vuelven a empezar. No se puede deshacer.',
                  'Finished lessons start over. This cannot be undone.')),
              actions: [
                TextButton(onPressed: () => Navigator.of(d).pop(false), child: const Text('No')),
                TextButton(onPressed: () => Navigator.of(d).pop(true), child: Text(tr('Sí, borrar', 'Yes, delete'))),
              ],
            ),
          );
          if (sure == true) await Progress.reset();
        },
        child: Text(tr('Borrar mi avance', 'Delete my progress'), style: const TextStyle(color: Pk.textSoft)),
      ),
    ],
  );
}

/// An optional daily reminder, off until turned on (asks for the time, and Android's permission the first time)
class _ReminderTile extends StatefulWidget {
  const _ReminderTile();

  @override
  State<_ReminderTile> createState() => _ReminderTileState();
}

class _ReminderTileState extends State<_ReminderTile> {
  TimeOfDay? _time;

  @override
  void initState() {
    super.initState();
    Reminders.instance.time().then((t) {
      if (mounted) setState(() => _time = t);
    });
  }

  Future<void> _switch(bool on) async {
    final t = on ? await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 19, minute: 0)) : null;
    if (on && t == null) return;
    if (await Reminders.instance.set(t) && mounted) setState(() => _time = t);
  }

  @override
  Widget build(BuildContext context) => SwitchListTile(
    title: Text(tr('Recordatorio diario', 'Daily reminder')),
    subtitle: Text(
      _time == null
          ? tr('Apagado', 'Off')
          : tr('A las ${_time!.format(context)} (no llega si ya practicaste ese día)',
              "At ${_time!.format(context)} (it doesn't come if you already practiced that day)"),
      style: const TextStyle(color: Pk.textSoft),
    ),
    value: _time != null,
    onChanged: _switch,
  );
}
