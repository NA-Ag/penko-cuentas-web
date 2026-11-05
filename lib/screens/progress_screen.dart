// progress_screen.dart — "Mi avance": what has been learned, unit by unit (lessons finished, how they went at the first
// try, the challenge's best score) and the well-being score over time. All of it is on the phone only. Useful for the
// student, and for a tutor or a pilot session to see progress at a glance.
import 'package:flutter/material.dart';

import '../art/palette.dart';
import '../art/penko.dart';
import '../data/progress.dart';
import '../data/store.dart';
import '../i18n/lang.dart';
import '../ui/pixel_ui.dart';
import 'course.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  Future<(Set<String>, Map<String, double>, Map<String, int>, List)> _load() async =>
      (await Progress.done(), await Progress.firstTry(), await Progress.checks(), await Store.get<List>('wellbeing') ?? []);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(tr('Mi avance', 'My progress'))),
    body: FutureBuilder(
      future: _load(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();
        final (done, firstTry, checks, wellbeing) = snap.data!;
        final total = course.fold<int>(0, (t, u) => t + u.lessons.length);
        final finished = course.fold<int>(0, (t, u) => t + u.lessons.where((l) => done.contains(l.id)).length);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Row(
              children: [
                Penko(pose: finished > 0 ? PenkoPose.jump : PenkoPose.idle, size: 64),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    finished == 0
                        ? tr('Todavía no terminas ninguna lección. ¡Empieza cuando quieras!',
                            "You haven't finished a lesson yet. Start whenever you like!")
                        : tr('Llevas $finished de $total lecciones.', "You've done $finished of $total lessons."),
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final u in course) ...[
              (() {
                final mine = u.lessons.where((l) => done.contains(l.id)).toList();
                final shares = [for (final l in mine) ?firstTry[l.id]];
                final avg = shares.isEmpty ? null : shares.reduce((a, b) => a + b) / shares.length;
                final review = [for (final l in mine) if (Progress.needsReview(firstTry[l.id])) l.title];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PkPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(u.icon, color: u.color),
                            const SizedBox(width: 10),
                            Expanded(child: Text(u.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                            Text('${mine.length}/${u.lessons.length}', style: const TextStyle(color: Pk.textSoft, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: mine.length / u.lessons.length,
                            minHeight: 8,
                            color: u.color,
                          ),
                        ),
                        if (avg != null) ...[
                          const SizedBox(height: 8),
                          Text(tr('Al primer intento: ${(avg * 100).round()}%', 'Right at the first try: ${(avg * 100).round()}%'), style: const TextStyle(color: Pk.textSoft)),
                        ],
                        if (checks[u.key] != null)
                          Text(tr('Reto de la unidad: ${checks[u.key]} de ${Progress.unitCheckSize}',
                                  'Unit challenge: ${checks[u.key]} out of ${Progress.unitCheckSize}'),
                              style: const TextStyle(color: Pk.gold, fontWeight: FontWeight.w700)),
                        if (review.isNotEmpty)
                          Text(tr('Para repasar: ', 'To review: ') + review.join(', '), style: const TextStyle(color: Pk.wrongText)),
                      ],
                    ),
                  ),
                );
              })(),
            ],
            if (wellbeing.isNotEmpty)
              PkPanel(
                child: Text(
                  tr('¿Cómo estoy con mi dinero?: ${wellbeing.length == 1 ? '${(wellbeing.last as Map)['s']} de 100' : 'de ${(wellbeing.first as Map)['s']} a ${(wellbeing.last as Map)['s']}'}',
                      'How am I doing with money?: ${wellbeing.length == 1 ? '${(wellbeing.last as Map)['s']} out of 100' : 'from ${(wellbeing.first as Map)['s']} to ${(wellbeing.last as Map)['s']}'}'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
          ],
        );
      },
    ),
  );
}
