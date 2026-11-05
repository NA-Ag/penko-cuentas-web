import 'package:flutter_test/flutter_test.dart';
import 'package:penko_math/money/receipt.dart';

void main() {
  // What Gemma 4 E2B wrote for the test receipt on the Redmi (2026-10-22), shop name and date line included
  const read = '''ABARROTES DOÑA LUPE | 1 | 22/10/2026 | 13:45
LECHE 1L | 2 | 2 | 29.00 | 58.00
TORTILLA 1KG | 1 | 1 | 24.00 | 24.00
HUEVO 12 PZ | 1 | 1 | 52.00 | 52.00
JABON ROPA | 1 | 1 | 38.50 | 38.50
REFRESCO 2L | 1 | 1 | 42.00 | 42.00
TOTAL | | | | 214.50''';

  test('a good reading: the shop name is left out, the items add up to the total', () {
    final r = parseReceipt(read);
    expect(r.items.map((i) => i.name), ['LECHE 1L', 'TORTILLA 1KG', 'HUEVO 12 PZ', 'JABON ROPA', 'REFRESCO 2L']);
    expect(r.total, 214.50);
    expect(r.addsUp, isTrue);
    expect(r.items.every((i) => i.lineChecks), isTrue);
    expect(r.byGroup[Spend.food], 176.0);
    expect(r.byGroup[Spend.home], 38.5);
  });

  test("a bad reading doesn't add up, so Penko asks the person to check", () {
    // The first reading on the phone put the payment where the total goes
    const bad = 'LECHE 1L | 2 | 29.00\nTORTILLA 1KG | 1 | 24.00\nTOTAL | 1 | 300.00\nEFECTIVO | 1 | 300.00\nCAMBIO | 1 | 85.50';
    final r = parseReceipt(bad);
    expect(r.items.length, 2);
    expect(r.addsUp, isFalse);
  });

  test('a line whose quantity × price is not its amount is marked', () {
    final r = parseReceipt('LECHE 1L | 2 | 29.00 | 48.00\nTOTAL | 48.00');
    expect(r.items.single.lineChecks, isFalse);
  });

  test('groups by name, with or without accents', () {
    expect(groupOf('JABÓN EN POLVO'), Spend.home);
    expect(groupOf('Gasolina Magna'), Spend.transport);
    expect(groupOf('RECARGA TELCEL 100'), Spend.bills);
    expect(groupOf('Pilas AA'), Spend.other);
  });
}
