// why_sheet.dart — what the student can ask Penko's tutor: a few questions to pick from, big and readable (and read
// aloud by screen readers), instead of one fixed "¿por qué?".
import 'package:flutter/material.dart';

import '../art/palette.dart';
import '../i18n/lang.dart';
import 'pixel_ui.dart';

/// Shows [questions] and returns the index of the one picked (null if closed)
Future<int?> askWhich(BuildContext context, List<String> questions) => showModalBottomSheet<int>(
  context: context,
  backgroundColor: Pk.card,
  builder: (sheet) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(tr('¿Qué quieres preguntarle a Penko?', 'What do you want to ask Penko?'),
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          for (final (i, q) in questions.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PkChoice(text: q, state: ChoiceState.idle, onTap: () => Navigator.of(sheet).pop(i)),
            ),
        ],
      ),
    ),
  ),
);
