import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mianara_mobile/ui/app_language.dart';

void main() {
  testWidgets('renders the selected Malagasy translation', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppLanguageScope(
          language: AppLanguage.malagasy,
          child: Scaffold(
            body: Builder(
              builder: (context) =>
                  Text(appText(context, 'Apprendre', 'Mianatra')),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Mianatra'), findsOneWidget);
    expect(find.text('Apprendre'), findsNothing);
  });
}
