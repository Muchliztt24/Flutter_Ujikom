import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ujikom/src/app.dart';

void main() {
  testWidgets('shows app shell', (WidgetTester tester) async {
    await tester.pumpWidget(const UjikomApp());

    expect(find.text('Nokomi'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
