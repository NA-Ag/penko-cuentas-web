// tr.dart — the plain-Dart core of lang.dart: tr() itself, with no Flutter in it, so the engines that use it (column,
// explain, the lessons) still run under plain `dart run` (tool/make_data.dart). Lang (lang.dart) keeps it in step with
// the app's language; screens import lang.dart, engines import this file.

/// The line in the current language: [es] (Mexican Spanish, the original) or [en]
String tr(String es, String en) => Tr.english && Tr._spanishOnly == 0 ? en : es;

/// Like tr(), for things that aren't one string: word lists picked together, so their words agree with each other
T trOf<T>(T es, T en) => Tr.english && Tr._spanishOnly == 0 ? en : es;

class Tr {
  Tr._();

  /// Set by Lang whenever the app's language changes
  static bool english = false;

  static int _spanishOnly = 0;

  /// Runs [build] with every tr() giving the Spanish line, whatever the app's language: the tutor model's facts and
  /// questions stay in the Spanish it was trained on (lib/ai), even when the student sees English.
  static T spanish<T>(T Function() build) {
    _spanishOnly++;
    try {
      return build();
    } finally {
      _spanishOnly--;
    }
  }
}
