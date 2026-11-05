// A line with numbers is built from clips: each sentence part once, and each number from its parts.
import 'package:flutter_test/flutter_test.dart';
import 'package:penko_math/audio/stitch.dart';

List<String> said(String line, {bool es = true}) => clipsOf(line, es)!.map((c) => c.text).toList();

void main() {
  test('Spanish numbers and amounts come apart into the clips that say them', () {
    expect(said('Tienes 34.'), ['Tienes', '34']);
    expect(said(r'Son $1,250.'), ['Son', 'mil', 'doscientos', '50', 'pesos']);
    expect(said('100 y 2000'), ['cien', 'y', '2', 'mil']);
    expect(said(r'Cuesta $7.50'), ['Cuesta', '7', 'pesos con', '50', 'centavos']);
    expect(said('El 16%'), ['El', '16', 'por ciento']);
  });

  test('English numbers too, and sentences split so they can follow any other', () {
    expect(said('It is 2500 pesos.', es: false), ['It is', '2', 'thousand', '5', 'hundred', 'pesos.']);
    expect(said('Almost. Check it.', es: false), ['Almost.', 'Check it.']);
  });

  test('a clip keeps its name: the voice files on the website are named with it', () {
    expect(clipsOf('Hola.', true)!.single.id, 'x4a3186e');
  });

  test('the same text always gets the same clip, and punctuation alone gets none', () {
    expect(clipsOf('Hola.', true)!.single.id, clipsOf('Hola.', true)!.single.id);
    expect(clipsOf('1 = 1', true)!.length, 2);
    expect(clipsOf('5000000', true), isNull);
  });
}
