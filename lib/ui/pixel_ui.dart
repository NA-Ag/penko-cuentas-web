// pixel_ui.dart — the app's building blocks: Penko Vox's navy and gold, made softer and more modern for a phone app
// (rounded cards with a soft shadow, buttons that press down), Quicksand for reading and DotGothic16 for the logo.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../art/palette.dart';
import '../wayfinding/wayfinding.dart' show hear;

const pixelFont = 'DotGothic16';
const textFont = 'Quicksand';

/// Letters DotGothic16 doesn't have come from PixelifySans
const pixelFallback = ['PixelifySans'];
const textFallback = <String>[];

ThemeData penkoTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Pk.gold,
      brightness: Brightness.dark,
      primary: Pk.gold,
      onPrimary: Pk.onGold,
      surface: Pk.paper,
      onSurface: Pk.text,
    ),
    scaffoldBackgroundColor: Pk.paper,
    fontFamily: textFont,
  );
  OutlineInputBorder edge(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: c, width: 2),
  );
  return base.copyWith(
    textTheme: base.textTheme
        .apply(bodyColor: Pk.text, displayColor: Pk.text, fontFamilyFallback: textFallback)
        .copyWith(
          // As in the game: titles in bold Quicksand, small labels ("YOU ARE IN") in the pixel font
          headlineMedium: const TextStyle(
            fontFamily: textFont,
            fontFamilyFallback: textFallback,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Pk.text,
          ),
          titleLarge: const TextStyle(
            fontFamily: textFont,
            fontFamilyFallback: textFallback,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Pk.text,
          ),
          labelLarge: const TextStyle(
            fontFamily: pixelFont,
            fontFamilyFallback: pixelFallback,
            fontSize: 14,
            letterSpacing: 1.2,
            color: Pk.textSoft,
          ),
          bodyLarge: const TextStyle(
            fontFamily: textFont,
            fontFamilyFallback: textFallback,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Pk.text,
          ),
        ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Pk.field,
      hintStyle: const TextStyle(color: Pk.textSoft),
      border: edge(Pk.rim),
      enabledBorder: edge(Pk.rim),
      focusedBorder: edge(Pk.gold),
    ),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: Pk.gold, selectionHandleColor: Pk.gold),
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Pk.card, surfaceTintColor: Colors.transparent),
    dialogTheme: const DialogThemeData(backgroundColor: Pk.card, surfaceTintColor: Colors.transparent),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Pk.cardHi,
      contentTextStyle: TextStyle(fontFamily: textFont, color: Pk.text, fontWeight: FontWeight.w600),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: Pk.gold, linearTrackColor: Pk.cardHi),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Pk.onGold : Pk.textSoft),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Pk.gold : Pk.cardHi),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Pk.paper,
      foregroundColor: Pk.text,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(fontFamily: textFont, fontSize: 20, fontWeight: FontWeight.w700, color: Pk.text),
    ),
    dividerTheme: const DividerThemeData(color: Pk.rim),
    chipTheme: const ChipThemeData(
      labelStyle: TextStyle(fontFamily: textFont, fontSize: 14, fontWeight: FontWeight.w700, color: Pk.gold),
      backgroundColor: Pk.note,
      side: BorderSide.none,
    ),
    // Text buttons read in Quicksand, not the pixel font the theme gives small labels
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(textStyle: const TextStyle(fontFamily: textFont, fontSize: 15, fontWeight: FontWeight.w700)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Pk.card,
      indicatorColor: Pk.gold.withValues(alpha: 0.16),
      surfaceTintColor: Colors.transparent,
      height: 70,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontFamily: textFont,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: s.contains(WidgetState.selected) ? Pk.gold : Pk.textSoft,
        ),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: Pk.gold,
      inactiveTrackColor: Pk.cardHi,
      thumbColor: Pk.gold,
      overlayColor: Pk.gold.withValues(alpha: 0.15),
      trackHeight: 6,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
    ),
    iconTheme: const IconThemeData(color: Pk.textSoft),
  );
}

/// A card: navy, rounded, with a faint rim and a soft shadow
class PkPanel extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  final double shadow;
  const PkPanel({
    super.key,
    required this.child,
    this.color = Pk.card,
    this.padding = const EdgeInsets.all(16),
    this.shadow = 4,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Pk.rim.withValues(alpha: 0.5)),
      boxShadow: [
        if (shadow > 0)
          BoxShadow(color: Colors.black.withValues(alpha: 0.28), blurRadius: 16, offset: Offset(0, shadow + 2)),
      ],
    ),
    child: child,
  );
}

/// A rounded button with a darker lower edge that it sinks into when pressed. Held down, Penko says its label.
class PkButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final Widget? leading;
  final bool expand;
  const PkButton(
    this.label, {
    super.key,
    this.onPressed,
    this.color = Pk.gold,
    this.textColor = Pk.onGold,
    this.leading,
    this.expand = true,
  });

  @override
  State<PkButton> createState() => _PkButtonState();
}

class _PkButtonState extends State<PkButton> {
  bool _down = false;
  static const _depth = 5.0;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final color = enabled ? widget.color : Pk.cardHi;
    final edge = Color.lerp(color, Colors.black, 0.35)!;
    final sink = _down ? _depth - 1 : 0.0;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        // Held down, Penko says what the button does (wayfinding.dart); a tap still presses it
        onLongPress: () => hear([widget.label]),
        onTapUp: enabled
            ? (_) {
                setState(() => _down = false);
                HapticFeedback.lightImpact();
                widget.onPressed!();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 60),
          margin: EdgeInsets.only(top: sink, bottom: _depth - sink),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          width: widget.expand ? double.infinity : null,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: edge, offset: Offset(0, _depth - sink))],
          ),
          child: Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.leading != null) ...[widget.leading!, const SizedBox(width: 10)],
              Flexible(
                child: Builder(builder: (context) {
                  final text = Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: textFont,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: enabled ? widget.textColor : Pk.textSoft,
                    ),
                  );
                  // A one-word label shrinks rather than breaking mid-word ("Pis-ta"); longer ones wrap between words
                  return widget.label.contains(' ') ? text : FittedBox(fit: BoxFit.scaleDown, child: text);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// How an answer option looks: not chosen yet, right, or not yet (soft amber, never red)
enum ChoiceState { idle, selected, right, wrong }

/// An answer option: readable text (not the pixel font), outlined, turning green or soft amber
class PkChoice extends StatelessWidget {
  final String text;
  final ChoiceState state;
  final VoidCallback onTap;
  const PkChoice({super.key, required this.text, required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (state) {
      ChoiceState.idle => (Pk.card, Pk.text),
      ChoiceState.selected => (Pk.rim, Pk.text), // picked, not marked yet (practice exams)
      ChoiceState.right => (Pk.rightSoft, Pk.rightText),
      ChoiceState.wrong => (Pk.wrongSoft, Pk.wrongText),
    };
    return Semantics(
      button: true,
      label: text,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: switch (state) {
                ChoiceState.right => Pk.right,
                ChoiceState.wrong => Pk.wrong,
                ChoiceState.selected => Pk.gold,
                ChoiceState.idle => Pk.rim,
              },
              width: 2.5,
            ),
          ),
          child: Text(
            text,
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: fg),
          ),
        ),
      ),
    );
  }
}
