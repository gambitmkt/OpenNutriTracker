import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/util/portion_unit.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/features/meal_detail/util/meal_quantity_converter.dart';

/// The entry-only units — kg, lb, l, cup, tbsp, tsp — are a way to type an
/// amount, not a thing that is stored: they convert to grams or millilitres
/// and are written down as `g` / `ml`, so the published unit vocabulary
/// (docs/export-format.md, the QR share payload) does not grow.
void main() {
  final meal = MealEntity(
    code: 'test',
    name: 'Test',
    url: null,
    mealQuantity: null,
    mealUnit: null,
    servingQuantity: null,
    servingUnit: null,
    servingSize: null,
    source: MealSourceEntity.off,
    nutriments: const MealNutrimentsEntity(
      energyKcal100: 200,
      carbohydrates100: null,
      fat100: null,
      proteins100: null,
      sugars100: null,
      saturatedFat100: null,
      fiber100: null,
    ),
  );

  const entryUnits = {
    'kg': 1000.0,
    'lb': 453.59237,
    'l': 1000.0,
    'cup': 240.0,
    'tbsp': 15.0,
    'tsp': 5.0,
  };

  test('each converts to its number of grams or millilitres', () {
    entryUnits.forEach((unit, perUnit) {
      expect(
        convertQuantityToBaseUnit(2, unit, meal),
        closeTo(2 * perUnit, 1e-9),
        reason: unit,
      );
    });
  });

  test('energy follows the converted amount', () {
    // 200 kcal per 100 g, so half a kilo is 1000 kcal — not the 1 kcal a
    // unit that fell through unconverted would give.
    expect(kcalForQuantity(0.5, 'kg', meal), closeTo(1000, 1e-9));
    expect(kcalForQuantity(1, 'cup', meal), closeTo(480, 1e-9));
  });

  test('weights are stored as g, volumes as ml', () {
    expect(storedUnit('kg'), 'g');
    expect(storedUnit('lb'), 'g');
    expect(storedUnit('l'), 'ml');
    expect(storedUnit('cup'), 'ml');
    expect(storedUnit('tbsp'), 'ml');
    expect(storedUnit('tsp'), 'ml');
  });

  test('the units that were always stored still are, unchanged', () {
    for (final unit in ['g', 'ml', 'g/ml', 'oz', 'fl.oz', 'serving']) {
      expect(storedUnit(unit), unit);
      expect(UnitDropdownItem.storedName(unit), unit);
    }
    expect(storedUnit('serving#2'), 'serving');
    // The bloc leaves a portion suffix alone, as it did before.
    expect(UnitDropdownItem.storedName('serving#2'), 'serving#2');
  });

  test('every enum value round-trips through its name', () {
    for (final item in UnitDropdownItem.values) {
      expect(UnitDropdownItem.g.fromString(item.toString()), item);
    }
  });

  test('every entry-only unit has a factor, and only those do', () {
    for (final item in UnitDropdownItem.values) {
      expect(
        UnitCalc.entryUnitToBaseFactor(item.toString()) != null,
        item.storedAs != null,
        reason: item.toString(),
      );
    }
  });

  test('labels keep the unit the user chose', () {
    expect(unitWithoutPortion('kg'), 'kg');
    expect(unitWithoutPortion('serving#1'), 'serving');
  });
}
