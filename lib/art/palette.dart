// palette.dart — the app's colours: the Steam game's dark navy windows and gold buttons around a bright pixel island.
import 'package:flutter/painting.dart';

abstract final class Pk {
  // Windows (same values as Penko Vox on Steam: .rpg-ground, .rpg-window, .rpg-btn in its index.css)
  static const ink = Color(0xFF0A0F1E); // outlines and hard shadows
  static const paper = Color(0xFF121A2E); // the background behind everything
  static const card = Color(0xFF1C2541); // panels
  static const cardHi = Color(0xFF2A3457); // raised things on a panel: the learner's bubbles, used tiles
  static const rim = Color(0xFF33406A); // the inner rim of a panel, dividers
  static const field = Color(0xFF111830); // text fields
  static const note = Color(0xFF262F4D); // tips and prompts (gold text on it)

  // Text
  static const text = Color(0xFFE8ECF8);
  static const textSoft = Color(0xFF9AA6C8);

  // Gold: the main buttons, tags and highlights
  static const gold = Color(0xFFF2C94C);
  static const goldEdge = Color(0xFF283048); // a gold button's outline and shadow
  static const onGold = Color(0xFF1B2440); // text on gold

  // Penko's dialogue box (light, like the game's message box)
  static const dialog = Color(0xFFF8F8F0);
  static const onDialog = Color(0xFF1B2440);

  // Island
  static const sky = Color(0xFF8FD8FF);
  static const sea = Color(0xFF3FB6F2);
  static const seaDeep = Color(0xFF1E88C8);
  static const sand = Color(0xFFFFE3A3);
  static const grass = Color(0xFF7ED957);
  static const grassDark = Color(0xFF4CAF3A);
  static const leaf = Color(0xFF2F8F46);
  static const wood = Color(0xFFB9763A);
  static const roof = Color(0xFFE8574B);

  // Accents
  static const orange = Color(0xFFF97316); // Penko's beak and feet
  static const sun = Color(0xFFFBBF24);
  static const coral = Color(0xFFFF7A8A);
  static const plum = Color(0xFFA78BFA); // Penko's helper (light enough to read on navy)

  // Feedback: gentle, never red (as in the game): green when right, soft amber "almost" when not yet
  static const right = Color(0xFF22C55E);
  static const rightSoft = Color(0xFF1D3B35);
  static const rightText = Color(0xFF86EFAC);
  static const wrong = Color(0xFFF59E0B);
  static const wrongSoft = Color(0xFF3A3120);
  static const wrongText = Color(0xFFFCD34D);
}

/// Penko's colours (same values as the Steam game's PenkoIcon)
const penkoPalette = <int, Color>{
  1: Color(0xFF111111), // outline
  2: Color(0xFFFFFFFF), // belly and eyes
  3: Color(0xFF64748B), // body
  4: Color(0xFFF97316), // beak and feet
  5: Color(0xFFEF4444), // red (headband dot)
  6: Color(0xFFFBBF24), // yellow
  7: Color(0xFF3B82F6), // blue
  8: Color(0xFF22C55E), // green (costumes)
  9: Color(0xFFA855F7), // purple (costumes)
  10: Color(0xFFEC4899), // pink (costumes)
};
