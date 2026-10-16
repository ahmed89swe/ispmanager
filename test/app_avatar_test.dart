import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isp_user_manager/core/widgets/app_avatar.dart';

void main() {
  group('AppAvatar', () {
    testWidgets('renders initials when photoUrl is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppAvatar(
              photoUrl: null,
              name: 'Ahmed',
              radius: 24,
            ),
          ),
        ),
      );

      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('renders ? when name is empty and photoUrl is null',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppAvatar(
              photoUrl: '',
              name: '  ',
              radius: 24,
            ),
          ),
        ),
      );

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('renders Image.memory when photoUrl is valid base64 data URL',
        (tester) async {
      // clean 1x1 png base64
      final validBytes = base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAZ');
      final validDataUrl = 'data:image/png;base64,${base64Encode(validBytes)}';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppAvatar(
              photoUrl: validDataUrl,
              name: 'Zaid',
              radius: 24,
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('falls back to initials when base64 is corrupt', (tester) async {
      const corruptDataUrl = 'data:image/png;base64,not_valid_base64!!!';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppAvatar(
              photoUrl: corruptDataUrl,
              name: 'Omar',
              radius: 24,
            ),
          ),
        ),
      );

      expect(find.text('O'), findsOneWidget);
    });
  });
}

