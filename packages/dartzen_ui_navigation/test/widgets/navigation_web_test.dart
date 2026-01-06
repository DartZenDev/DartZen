import 'package:dartzen_localization/dartzen_localization.dart';
import 'package:dartzen_ui_navigation/src/widgets/navigation_web.dart';
import 'package:dartzen_ui_navigation/src/zen_navigation_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('web navigation renders narrow (drawer) layout',
      (WidgetTester tester) async {
    final items = List.generate(
      3,
      (i) => ZenNavigationItem(
        id: 'w$i',
        label: 'Item $i',
        builder: (c) => Text('Content $i'),
      ),
    );

    final localization =
        ZenLocalizationService(config: const ZenLocalizationConfig());

    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(size: Size(360, 800)),
      child: MaterialApp(
        home: Builder(
            builder: (ctx) => buildPlatformNavigation(
                  context: ctx,
                  selectedIndex: 0,
                  onItemSelected: (_) {},
                  items: items,
                  localization: localization,
                  language: 'en',
                )),
      ),
    ));

    // Narrow layout should include a Drawer
    expect(find.byType(Drawer), findsOneWidget);
    // Body should show selected content
    expect(find.text('Content 0'), findsOneWidget);
  });

  testWidgets('web navigation renders wide (top menu) layout and responds',
      (WidgetTester tester) async {
    final items = List.generate(
      3,
      (i) => ZenNavigationItem(
        id: 'w$i',
        label: 'Item $i',
        builder: (c) => Text('Content $i'),
      ),
    );

    final localization =
        ZenLocalizationService(config: const ZenLocalizationConfig());

    var selected = -1;

    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(size: Size(1200, 800)),
      child: MaterialApp(
        home: Builder(
            builder: (ctx) => buildPlatformNavigation(
                  context: ctx,
                  selectedIndex: 1,
                  onItemSelected: (i) => selected = i,
                  items: items,
                  localization: localization,
                  language: 'en',
                )),
      ),
    ));

    // Top menu buttons should be present
    expect(find.byType(TextButton), findsWidgets);
    // Body should show content for selectedIndex (1)
    expect(find.text('Content 1'), findsOneWidget);

    // Tap the first top menu button to change selection
    await tester.tap(find.widgetWithText(TextButton, 'Item 0').first);
    await tester.pumpAndSettle();
    expect(selected, equals(0));
  });
}
