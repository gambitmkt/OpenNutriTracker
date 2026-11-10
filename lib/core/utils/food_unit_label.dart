import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// The label for one of the entry-only food units (`kg`, `lb`, `l`, `cup`,
/// `tbsp`, `tsp`), or null for any other unit.
///
/// [count] picks the plural of the household measures ("2 cups"). With
/// [withSize] those also say how big they are — "cup (240 ml)" — because a
/// cup is not the same size everywhere and the dropdown is where the user
/// decides whether this one is theirs.
String? entryUnitLabel(
  S s,
  String unit, {
  num count = 1,
  bool withSize = false,
}) {
  final String? word = switch (unit) {
    'kg' => s.kgLabel,
    'lb' => s.lbsLabel,
    'l' => s.literUnit,
    'cup' => s.measureUnitCup(count),
    'tbsp' => s.measureUnitTablespoon(count),
    'tsp' => s.measureUnitTeaspoon(count),
    _ => null,
  };
  if (word == null) return null;
  final isHousehold = unit == 'cup' || unit == 'tbsp' || unit == 'tsp';
  if (!withSize || !isHousehold) return word;
  final ml = UnitCalc.entryUnitToBaseFactor(unit)!.round();
  return '$word ($ml ${s.milliliterUnit})';
}
