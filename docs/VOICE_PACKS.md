# Voice packs: recording Penko's words

Penko Cuentas Claras is for everyone who handles money, including people who read little or who don't speak
Spanish well. Every important word in the app has a **picture**, a **short plain sentence** and an **example**,
and Penko says them out loud (the "Palabras / Words" screen, and every underlined word in the lessons, simulators
and resources).

On the phone, Penko speaks with the phone's synthetic voice (text-to-speech). The website ships a synthetic pack in
Spanish and English, made once with the open Kokoro voice, because browser voices vary so much; its lines with
changing numbers are stitched from short clips (`lib/audio/stitch.dart`). A **voice pack** of real people replaces it, line by line. This is how the app will speak languages that phones have no voice for, such as
Náhuatl, Maya, Mixteco, Zapoteco or Otomí: **audio first, text optional.**

## What can be recorded

Every line that never changes has a **key**, a short name made of letters, numbers, dots and dashes. Print the full
list, with the Spanish (or English) text of each line:

```sh
dart run tool/voice_keys.dart            # Spanish: key <tab> text
dart run tool/voice_keys.dart en         # English
dart run tool/voice_keys.dart es csv     # a CSV for a spreadsheet: key, text, suggested file name
```

The list (about 250 lines) has three parts:

| Keys | What they are |
| --- | --- |
| `term.<id>.word` | A glossary word, e.g. `term.iva.word` = "IVA" |
| `term.<id>.explain` | Its one-sentence explanation, e.g. `term.iva.explain` |
| `term.<id>.example` | Its example with small numbers, e.g. `term.iva.example` |
| `lesson.<lesson>.intro.<n>` | Penko's opening lines for each lesson, e.g. `lesson.mo-1.intro.0` |
| `lesson.<lesson>.say.<n>` | Her explanations in the abacus lessons, e.g. `lesson.ab-1.say.0` |
| `penko.<name>` | Her short fixed lines: `penko.your_turn` ("¡Ahora tú!"), `penko.well_done` ("¡Muy bien!")… |

The keys come from the code (`lib/glossary/terms.dart`, `lib/audio/voice_keys.dart`) and never change, even if
the Spanish wording is improved later. Lines with numbers that change every time (the practice problems) are not
in the list: those stay with text-to-speech for now.

**Where to start:** the glossary (`term.*`) matters most. The words and explanations (`.word`, `.explain`) are
what a learner hears when they tap a word; the examples come next.

## How to record

- **One file per key**, named exactly like the key: `term.iva.explain.mp3`.
- **Short and clean:** mono, 44.1 or 48 kHz, quiet room, no music, about a quarter of a second of silence at each
  end. Normalise the volume so all files sound equally loud.
- **Format:** MP3 (about 64–96 kbps) or Ogg Vorbis/Opus. MP3 plays everywhere; Ogg may not play on some older iPhones and Macs.
  (`.m4a` and `.wav` also work; `.wav` makes the app much bigger.)
- **Say it naturally, the way people speak in the community**, not word for word from the Spanish. A sentence
  that explains the idea well is better than an exact translation. Keep the numbers of the example (\$100, 16%…)
  so the picture and the sound match.

## Where the files go

```
assets/voice/<language>/<key>.mp3
assets/voice/es/term.iva.word.mp3
assets/voice/nah/term.iva.explain.mp3
```

`<language>` is a short code: `es`, `en`, or the ISO 639 code of the language (`nah` Náhuatl, `yua` Maya
yucateco, `mix` Mixteco, `zap` Zapoteco, `oto` Otomí…; a more precise code such as `nhe` for Huasteca Náhuatl is
fine too, if the community prefers it).

If the files have other names, add a `manifest.json` in the same folder that maps keys to files:

```json
{ "term.iva.word": "iva_palabra.mp3", "term.iva.explain": "iva_explica.mp3" }
```

Then list the folder in `pubspec.yaml`, under `flutter:` (Flutter only bundles folders that are listed):

```yaml
flutter:
  assets:
    - assets/voice/es/
```

Nothing else is needed: when Penko is about to say a line and the pack for the current language has its
recording, she plays the recording; if not, she uses text-to-speech as before. A pack can be partial: record the
glossary words first and add the rest over time.

## How it works in the app

- `lib/audio/voice_pack.dart` finds the recording for a key in the current language (from the app's asset list
  and the optional `manifest.json`). Fixed lines are also recognised by their text, so the lesson screens didn't
  need changing.
- `lib/audio/speech.dart` asks it first, every time Penko speaks (`Speech.say(text, key: …)`), and falls back to
  text-to-speech. The "listen slowly" button and the different voices for listening practice always use
  text-to-speech.
- `lib/audio/voice_player.dart` plays the file. **On the web** it uses the browser's own audio player (no extra
  package). **On Android there is no player yet**: the app doesn't include an audio package, so the hook answers
  "can't play" and Penko keeps using text-to-speech. When the first real pack arrives, add one package
  (`audioplayers` or `just_audio`) and fill in the two methods in `voice_player_stub.dart`
  (`play(asset, until:)` and `stop()`), then set `supported = true`. Nothing else changes.

## Adding a new language (for example Náhuatl, `nah`)

Audio comes first; written text is optional and can come later.

1. **Record** the glossary with a native speaker (the CSV from `tool/voice_keys.dart` is the script; the Spanish
   text and the picture show what each line means). Put the files in `assets/voice/nah/` and list the folder in
   `pubspec.yaml`.
2. **Add the language to the app** (code change, small): `Lang` in `lib/i18n/lang.dart` gets a third choice,
   `nah`, shown in Ajustes with its own name ("Nāhuatlahtōlli" or whatever the community uses). With no written
   text yet, `tr()` shows Spanish for `nah` (the screen stays readable for helpers and family) while
   `VoicePack.language` returns `nah`, so Penko speaks from the recordings. The pictures do the rest.
3. **Lines with no recording** in `nah` fall back to Spanish text-to-speech; it's better to record the whole
   glossary before offering the language, so a learner never hits a gap in the words that matter most.
4. **Written text later (optional):** when the community wants written Náhuatl, `tr()` grows a third argument
   (or a per-language table keyed by the same keys) and the translators fill it in, line by line, from the same
   key list.
5. **Check with the community** that the words and pictures make sense to them (some ideas, like CAT or Afore,
   may be better explained with an everyday comparison than translated).

## For developers

- New glossary words: add a `Term` to `lib/glossary/terms.dart` (an id that never changes, word, other forms,
  explanation, example, picture from `lib/glossary/pictograms.dart`). Its three keys appear in the list by
  themselves. `test/glossary_test.dart` checks that every term has Spanish, English and a picture.
- New fixed Penko lines: add them to `penkoLines` in `lib/audio/voice_keys.dart` with exactly the same text as on
  screen, so the recording is found by its text.
- Keys must stay stable: recordings are named after them. Rename a key only together with its files.
