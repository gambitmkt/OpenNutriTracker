import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/edit_meal/presentation/edit_meal_screen.dart';
import 'package:opennutritracker/features/scanner/data/product_not_found_exception.dart';
import 'package:opennutritracker/features/scanner/domain/usecase/search_product_by_barcode_usecase.dart';
import 'package:opennutritracker/features/scanner/presentation/scanner_bloc.dart';
import 'package:opennutritracker/features/scanner/scanner_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// A barcode Open Food Facts does not have ends in a dead end unless the
/// scanner offers the way out: save the product as a custom food under the
/// code that was just scanned, so the next scan of it resolves locally.
void main() {
  final getIt = GetIt.instance;
  const barcode = '7501055300075';

  setUp(() async {
    await getIt.reset();
    getIt.registerFactory<ScannerBloc>(
      () => ScannerBloc(_NotFoundSearchUseCase(), _FakeGetConfigUsecase()),
    );
    getIt.registerLazySingleton<GetConfigUsecase>(_FakeGetConfigUsecase.new);
  });

  tearDown(() => getIt.reset());

  Future<List<Object?>> openScanner(
    WidgetTester tester,
    ScannerScreenArguments arguments,
  ) async {
    final pushedArgs = <Object?>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        onGenerateRoute: (settings) {
          if (settings.name == NavigationOptions.editMealRoute) {
            pushedArgs.add(settings.arguments);
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const Scaffold(body: Text('edit-meal')),
            );
          }
          return null;
        },
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  settings: RouteSettings(arguments: arguments),
                  builder: (_) => const ScannerScreen(),
                ),
              ),
              child: const Text('open scanner'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open scanner'));
    await tester.pumpAndSettle();
    return pushedArgs;
  }

  testWidgets('a product that is not found can be saved under its barcode', (
    tester,
  ) async {
    final pushedArgs = await openScanner(
      tester,
      ScannerScreenArguments(
        DateTime(2026, 5, 21),
        IntakeTypeEntity.breakfast,
        initialBarcode: barcode,
      ),
    );

    expect(find.text('Product not found'), findsOneWidget);
    await tester.tap(find.text('New Custom Food'));
    await tester.pumpAndSettle();

    expect(find.text('edit-meal'), findsOneWidget);
    final args = pushedArgs.single as EditMealScreenArguments;
    expect(args.mealEntity.code, barcode);
    expect(args.mealEntity.source, MealSourceEntity.custom);
    expect(args.day, DateTime(2026, 5, 21));
    expect(args.intakeTypeEntity, IntakeTypeEntity.breakfast);
  });

  testWidgets('pick mode does not offer it', (tester) async {
    await openScanner(
      tester,
      ScannerScreenArguments.pick(initialBarcode: barcode),
    );

    expect(find.text('Product not found'), findsOneWidget);
    expect(find.text('New Custom Food'), findsNothing);
  });
}

class _NotFoundSearchUseCase implements SearchProductByBarcodeUseCase {
  @override
  Future<MealEntity> searchProductByBarcode(String barcode) async =>
      throw ProductNotFoundException();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeGetConfigUsecase implements GetConfigUsecase {
  @override
  Future<ConfigEntity> getConfig() async =>
      const ConfigEntity(true, true, false, AppThemeEntity.system);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}
