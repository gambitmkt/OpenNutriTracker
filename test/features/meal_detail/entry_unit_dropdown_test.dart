import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/food_unit_label.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:flutter/material.dart';

/// The household measures say how big they are where the user picks them,
/// and take a plural where an amount stands in front of them.
void main() {
  Future<S> load(String languageCode) => S.delegate.load(Locale(languageCode));

  test('English labels', () async {
    final s = await load('en');
    expect(entryUnitLabel(s, 'kg'), 'kg');
    expect(entryUnitLabel(s, 'lb'), 'lbs');
    expect(entryUnitLabel(s, 'l'), 'l');
    expect(entryUnitLabel(s, 'cup', withSize: true), 'cup (240 ml)');
    expect(entryUnitLabel(s, 'tbsp', withSize: true), 'tablespoon (15 ml)');
    expect(entryUnitLabel(s, 'tsp', withSize: true), 'teaspoon (5 ml)');
    expect(entryUnitLabel(s, 'cup', count: 2), 'cups');
    // A weight has one size everywhere and does not repeat it.
    expect(entryUnitLabel(s, 'kg', withSize: true), 'kg');
  });

  test('Spanish labels', () async {
    final s = await load('es');
    expect(entryUnitLabel(s, 'cup', withSize: true), 'taza (240 ml)');
    expect(entryUnitLabel(s, 'tbsp', count: 2), 'cucharadas');
    expect(entryUnitLabel(s, 'tsp'), 'cucharadita');
  });

  test('the stored units are not this helper\'s to label', () async {
    final s = await load('en');
    for (final unit in ['g', 'ml', 'g/ml', 'oz', 'fl.oz', 'serving']) {
      expect(entryUnitLabel(s, unit), isNull);
    }
  });
}
