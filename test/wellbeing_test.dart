import 'package:flutter_test/flutter_test.dart';
import 'package:penko_math/money/wellbeing.dart';

void main() {
  test('scores match the official CFPB table', () {
    // Worst answers everywhere: total 0
    expect(wellbeingScore([0, 0, 0, 4, 0], age: 0, mode: 0), 19);
    // Best answers everywhere: total 20
    expect(wellbeingScore([4, 4, 4, 0, 4], age: 0, mode: 0), 82);
    expect(wellbeingScore([4, 4, 4, 0, 4], age: 1, mode: 0), 90);
    expect(wellbeingScore([4, 4, 4, 0, 4], age: 0, mode: 1), 87);
    expect(wellbeingScore([4, 4, 4, 0, 4], age: 1, mode: 1), 84);
    // The middle answer everywhere: total 10
    expect(wellbeingScore([2, 2, 2, 2, 2], age: 0, mode: 0), 50);
    expect(wellbeingScore([2, 2, 2, 2, 2], age: 1, mode: 1), 53);
  });

  test('question 4 counts the other way round', () {
    // "Siempre" me sobra dinero is the best answer (4), "Nunca" the worst (0)
    expect(wellbeingItems[3].values.first, 4);
    expect(wellbeingItems[3].values.last, 0);
  });
}
