// voice_keys.dart — prints every line Penko can say from a recording (a voice pack, docs/VOICE_PACKS.md): its key
// and its text, for the people who translate and record them. Run from the project folder:
//   dart run tool/voice_keys.dart          (Spanish, tab-separated: key, text)
//   dart run tool/voice_keys.dart en       (English)
//   dart run tool/voice_keys.dart es csv   (a CSV file to open in a spreadsheet: key, text, file)
import '../lib/audio/voice_keys.dart';
import '../lib/i18n/tr.dart';

void main(List<String> args) {
  Tr.english = args.isNotEmpty && args.first == 'en';
  final lang = Tr.english ? 'en' : 'es';
  final csv = args.contains('csv');
  String quote(String s) => '"${s.replaceAll('"', '""')}"';
  if (csv) print('key,text,file');
  for (final e in voiceLines().entries) {
    print(csv ? '${e.key},${quote(e.value)},assets/voice/$lang/${e.key}.mp3' : '${e.key}\t${e.value}');
  }
}
