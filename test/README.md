# Testing Documentation

## Test Structure

```
test/
├── README.md                           # This file
├── widget_test.dart                    # Widget tests
└── integration/
    ├── firebase_e2e_test.dart         # Firebase E2E test suite (requires mocks or real device)
    └── phase1_integration_test.dart   # Legacy Supabase tests (deprecated)

integration_test/
└── app_test.dart                      # Real device/emulator integration tests
```

## Running Tests

### Run All Tests
```bash
flutter test
```

### Run Integration Tests Only
```bash
flutter test test/integration/
```

### Run Firebase E2E Tests (Unit Test Suite)
```bash
flutter test test/integration/firebase_e2e_test.dart
```

### Run Integration Tests on Real Device/Emulator
```bash
# Start Chrome or a device/emulator, then run:
flutter test integration_test/app_test.dart
```

### Run with Verbose Output
```bash
flutter test --verbose
```

### Run with Coverage Report
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Firebase E2E Integration Tests

### Test Coverage

The `firebase_e2e_test.dart` file contains comprehensive end-to-end tests covering:

#### 🔐 Authentication Flow (5 tests)
- Sign up new user
- Get current user
- Update user profile
- Sign out
- Sign in with credentials

#### 📝 Todo CRUD Operations (15 tests)
- Create personal task
- Create all 5 todo types (appointment, work, shopping, personal, other)
- Create all 5 priority levels (P1-P5)
- Read todo by ID
- Get all todos
- Get todos by date
- Get todos by date range
- Get todos by type
- Get todos by status
- Search todos
- Update todo
- Toggle todo status (pending ↔ completed)
- Get completed todos
- Delete todo

#### 🔄 Retry Mechanism Tests (5 tests)
- Successful operation (no retry needed)
- Retry after failures then success
- Exhausted retry attempts
- Non-retryable error handling
- Todo operations with retry support

#### 📊 Data Validation Tests (5 tests)
- Todo overdue logic
- Completed tasks override overdue
- Todo with specific time
- Todo with location coordinates
- Todo with notification settings

#### 🔥 Firebase Sync Tests (2 tests)
- Real-time Firestore synchronization
- Batch operations with multiple todos

### Total Test Cases: **32 comprehensive tests**

## Test Data Management

### Setup
- Each test run creates a unique test user with timestamp-based email
- All test todos are tracked in `createdTodoIds` list

### Cleanup
- Automatic cleanup in `tearDownAll()`
- Deletes all created todos
- Signs out test user
- Note: Firebase Auth users require manual cleanup or Admin SDK

## Test Requirements

### Prerequisites
1. **Firebase Project**: Valid Firebase project configured
2. **Firebase Auth**: Email/Password authentication enabled
3. **Firestore**: Database created with proper security rules
4. **Network**: Internet connection required for Firebase

### Configuration
Tests use the Firebase configuration from `firebase_options.dart`:
- Project ID: `family-planner-86edd`
- API Key: Configured in test file
- Auth Domain: `family-planner-86edd.firebaseapp.com`

## Test Output Example

```
🚀 Setting up Firebase E2E Integration Tests...

📧 Test email: test_e2e_1699564823456@example.com
✅ Firebase initialized

🔐 Authentication Flow
  📝 Test 1.1: User Sign Up
  ✅ Sign up successful
     User ID: abc123def456
     Email: test_e2e_1699564823456@example.com
     Name: E2E Test User

  👤 Test 1.2: Get Current User
  ✅ Current user retrieved
     User ID: abc123def456

... (more tests)

🧹 Cleaning up test data...
   🗑️  Deleted todo: todo-id-1
   🗑️  Deleted todo: todo-id-2
   ✅ Signed out
✅ Cleanup complete
```

## Continuous Integration

### GitHub Actions Example

```yaml
name: Run Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      - run: flutter pub get
      - run: flutter test
```

## Best Practices

1. **Unique Test Data**: Always use unique emails/IDs to avoid conflicts
2. **Cleanup**: Ensure proper cleanup in `tearDownAll()`
3. **Timeouts**: Add reasonable timeouts for network operations
4. **Assertions**: Use descriptive expect statements
5. **Logging**: Add print statements for debugging
6. **Isolation**: Each test should be independent
7. **Error Handling**: Expect and handle potential failures

## Troubleshooting

### Common Issues

#### Firebase Not Initialized
```
Error: Firebase has not been initialized
```
**Solution**: Ensure `Firebase.initializeApp()` is called in `setUpAll()`

#### Authentication Errors
```
Error: [firebase_auth/network-request-failed]
```
**Solution**: Check internet connection and Firebase configuration

#### Firestore Permission Denied
```
Error: Missing or insufficient permissions
```
**Solution**: Update Firestore security rules to allow test operations

#### Test Timeout
```
Error: Test timed out after 30 seconds
```
**Solution**: Increase timeout or check network connection

### Debug Mode

Run tests with debug output:
```bash
flutter test --verbose test/integration/firebase_e2e_test.dart 2>&1 | tee test_output.log
```

## Future Enhancements

- [ ] Add widget integration tests
- [ ] Add performance benchmarks
- [ ] Add visual regression tests
- [ ] Add accessibility tests
- [ ] Mock Firebase for faster unit tests
- [ ] Add test data factories
- [ ] Add CI/CD pipeline integration
- [ ] Add code coverage reporting
- [ ] Add mutation testing

## Contributing

When adding new tests:
1. Follow the existing naming convention
2. Add descriptive print statements
3. Update this README with new test coverage
4. Ensure proper cleanup
5. Add assertions for all expected behaviors
6. Test both success and failure cases
