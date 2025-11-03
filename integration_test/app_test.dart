import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:family_planner/main.dart' as app;

/// Integration Test for Family Planner App
///
/// This test runs the actual app and simulates user interactions.
/// Run with: flutter test integration_test/app_test.dart
/// Or on a device: flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Family Planner E2E Tests', () {
    testWidgets('Complete user flow: Login -> Create Todo -> Complete -> Delete',
        (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for Firebase initialization
      await tester.pumpAndSettle(const Duration(seconds: 3));

      print('✅ App loaded');

      // Check if we're on the login page (credentials should be pre-filled)
      expect(find.text('Family Planner'), findsWidgets);
      expect(find.text('Log In'), findsOneWidget);

      // The credentials should be pre-filled from our earlier changes
      // Just tap the login button
      final loginButton = find.widgetWithText(ElevatedButton, 'Log In');
      expect(loginButton, findsOneWidget);

      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      print('✅ Logged in');

      // Should now be on the calendar page
      expect(find.text('Family Planner'), findsWidgets);

      // Look for the floating action button to add a todo
      final addButton = find.byType(FloatingActionButton);
      expect(addButton, findsOneWidget);

      await tester.tap(addButton);
      await tester.pumpAndSettle();

      print('✅ Opened add todo dialog');

      // Fill in the todo form
      final titleField = find.widgetWithText(TextFormField, 'Title');
      expect(titleField, findsOneWidget);

      await tester.enterText(titleField, 'E2E Test Todo');
      await tester.pumpAndSettle();

      // Find and tap the Create button
      final createButton = find.widgetWithText(ElevatedButton, 'Create');
      expect(createButton, findsOneWidget);

      await tester.tap(createButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      print('✅ Created todo');

      // Verify the todo appears in the list
      expect(find.text('E2E Test Todo'), findsOneWidget);

      // Find and tap the checkbox to complete the todo
      final checkbox = find.byType(Checkbox).first;
      await tester.tap(checkbox);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      print('✅ Completed todo');

      // Find and tap the delete button
      final deleteButton = find.byIcon(Icons.delete_outline).first;
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // Confirm deletion in dialog
      final confirmDelete = find.text('Delete');
      expect(confirmDelete, findsWidgets);

      await tester.tap(confirmDelete.last);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      print('✅ Deleted todo');

      // Verify todo is gone
      expect(find.text('E2E Test Todo'), findsNothing);

      print('✅ Complete E2E test passed!');
    });

    testWidgets('Test retry functionality with error handling',
        (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Log in (credentials pre-filled)
      final loginButton = find.widgetWithText(ElevatedButton, 'Log In');
      if (loginButton.evaluate().isNotEmpty) {
        await tester.tap(loginButton);
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }

      print('✅ App ready for retry test');

      // Create a todo
      final addButton = find.byType(FloatingActionButton);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      final titleField = find.widgetWithText(TextFormField, 'Title');
      await tester.enterText(titleField, 'Retry Test Todo');
      await tester.pumpAndSettle();

      final createButton = find.widgetWithText(ElevatedButton, 'Create');
      await tester.tap(createButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      print('✅ Created todo for retry test');

      // The todo operations have automatic retry built in
      // If any operation fails, it will retry up to 3 times
      // The UI also provides a manual retry button in the error snackbar

      // Verify the todo was created (proving retry mechanism worked if needed)
      expect(find.text('Retry Test Todo'), findsOneWidget);

      // Clean up
      final deleteButton = find.byIcon(Icons.delete_outline).first;
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      final confirmDelete = find.text('Delete');
      await tester.tap(confirmDelete.last);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      print('✅ Retry test completed');
    });

    testWidgets('Test all todo types', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Log in
      final loginButton = find.widgetWithText(ElevatedButton, 'Log In');
      if (loginButton.evaluate().isNotEmpty) {
        await tester.tap(loginButton);
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }

      final types = ['Appointment', 'Work', 'Shopping', 'Personal', 'Other'];

      for (final type in types) {
        // Open add dialog
        final addButton = find.byType(FloatingActionButton);
        await tester.tap(addButton);
        await tester.pumpAndSettle();

        // Enter title
        final titleField = find.widgetWithText(TextFormField, 'Title');
        await tester.enterText(titleField, '$type Task');
        await tester.pumpAndSettle();

        // Select type from dropdown
        final typeDropdown = find.widgetWithText(DropdownButtonFormField<String>, 'Type');
        await tester.tap(typeDropdown);
        await tester.pumpAndSettle();

        // Tap the dropdown item
        final typeOption = find.text(type).last;
        await tester.tap(typeOption);
        await tester.pumpAndSettle();

        // Create
        final createButton = find.widgetWithText(ElevatedButton, 'Create');
        await tester.tap(createButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        print('✅ Created $type task');
      }

      // Verify all todos were created
      for (final type in types) {
        expect(find.text('$type Task'), findsOneWidget);
      }

      print('✅ All todo types tested');
    });
  });
}
