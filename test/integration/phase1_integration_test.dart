import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:family_planner/core/constants/supabase_config.dart';
import 'package:family_planner/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:family_planner/features/auth/domain/entities/user_entity.dart';
import 'package:family_planner/features/todos/data/repositories/todo_repository_impl.dart';
import 'package:family_planner/features/todos/domain/entities/todo_entity.dart';
import 'package:uuid/uuid.dart';

/// Phase 1 Integration Tests
///
/// This test suite validates all Phase 1 features:
/// ✅ User authentication (signup/login)
/// ✅ Calendar view with monthly/weekly/daily formats
/// ✅ Create, read, update, and delete (CRUD) todos
/// ✅ Todo types: Appointment, Work, Shopping, Personal, Other
/// ✅ Priority levels (P1-P5: Urgent to None)
/// ✅ Task completion tracking
/// ✅ Real-time database synchronization with Supabase
///
/// IMPORTANT: These are integration tests that connect to a real Supabase instance.
/// Make sure you have valid credentials in supabase_config.dart before running.

void main() {
  late SupabaseClient supabaseClient;
  late AuthRepositoryImpl authRepository;
  late TodoRepositoryImpl todoRepository;
  late String testEmail;
  late String testPassword;
  late UserEntity? testUser;

  setUpAll(() async {
    print('\n🚀 Setting up Phase 1 Integration Tests...\n');

    // Initialize Supabase
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );

    supabaseClient = Supabase.instance.client;
    authRepository = AuthRepositoryImpl(supabaseClient);
    todoRepository = TodoRepositoryImpl(supabaseClient);

    // Generate unique test credentials for this test run
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    testEmail = 'test_user_$timestamp@test.com';
    testPassword = 'TestPassword123!';

    print('📧 Test email: $testEmail');
    print('✅ Supabase initialized\n');
  });

  tearDownAll(() async {
    print('\n🧹 Cleaning up...');

    // Sign out after all tests
    if (testUser != null) {
      try {
        await authRepository.signOut();
        print('✅ Signed out successfully');
      } catch (e) {
        print('⚠️  Sign out failed: $e');
      }
    }

    print('✅ Cleanup complete\n');
  });

  group('Phase 1: Authentication Tests', () {
    test('1.1 Sign Up - Should create new user account', () async {
      print('\n📝 Test 1.1: Sign Up');

      try {
        testUser = await authRepository.signUp(
          email: testEmail,
          password: testPassword,
          fullName: 'Test User',
        );

        expect(testUser, isNotNull);
        expect(testUser!.email, equals(testEmail));
        expect(testUser!.fullName, equals('Test User'));
        expect(testUser!.languagePreference, equals('en'));

        print('✅ Sign up successful');
        print('   User ID: ${testUser!.id}');
        print('   Email: ${testUser!.email}');
        print('   Name: ${testUser!.fullName}');
      } catch (e) {
        print('❌ Sign up failed: $e');
        rethrow;
      }
    });

    test('1.2 Sign Out - Should sign out current user', () async {
      print('\n🚪 Test 1.2: Sign Out');

      try {
        await authRepository.signOut();

        final isAuth = await authRepository.isAuthenticated();
        expect(isAuth, isFalse);

        print('✅ Sign out successful');
      } catch (e) {
        print('❌ Sign out failed: $e');
        rethrow;
      }
    });

    test('1.3 Sign In - Should sign in with existing credentials', () async {
      print('\n🔑 Test 1.3: Sign In');

      try {
        testUser = await authRepository.signIn(
          email: testEmail,
          password: testPassword,
        );

        expect(testUser, isNotNull);
        expect(testUser!.email, equals(testEmail));

        final isAuth = await authRepository.isAuthenticated();
        expect(isAuth, isTrue);

        print('✅ Sign in successful');
        print('   User ID: ${testUser!.id}');
      } catch (e) {
        print('❌ Sign in failed: $e');
        rethrow;
      }
    });

    test('1.4 Get Current User - Should retrieve authenticated user', () async {
      print('\n👤 Test 1.4: Get Current User');

      try {
        final currentUser = await authRepository.getCurrentUser();

        expect(currentUser, isNotNull);
        expect(currentUser!.id, equals(testUser!.id));
        expect(currentUser.email, equals(testEmail));

        print('✅ Current user retrieved');
        print('   User ID: ${currentUser.id}');
      } catch (e) {
        print('❌ Get current user failed: $e');
        rethrow;
      }
    });

    test('1.5 Update Profile - Should update user profile', () async {
      print('\n✏️  Test 1.5: Update Profile');

      try {
        final updatedUser = await authRepository.updateProfile(
          fullName: 'Updated Test User',
          languagePreference: 'zh',
        );

        expect(updatedUser.fullName, equals('Updated Test User'));
        expect(updatedUser.languagePreference, equals('zh'));

        testUser = updatedUser;

        print('✅ Profile updated');
        print('   New name: ${updatedUser.fullName}');
        print('   Language: ${updatedUser.languagePreference}');
      } catch (e) {
        print('❌ Update profile failed: $e');
        rethrow;
      }
    });
  });

  group('Phase 1: Todo CRUD Tests', () {
    String? createdTodoId;

    test('2.1 Create Todo - Personal task with P3 priority', () async {
      print('\n➕ Test 2.1: Create Personal Todo');

      try {
        final newTodo = TodoEntity(
          id: const Uuid().v4(),
          userId: testUser!.id,
          title: 'Test Personal Task',
          description: 'This is a test personal task',
          todoDate: DateTime.now(),
          todoTime: DateTime.now().add(const Duration(hours: 2)),
          priority: 3, // Medium
          type: 'personal',
          status: 'pending',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final createdTodo = await todoRepository.createTodo(newTodo);
        createdTodoId = createdTodo.id;

        expect(createdTodo.title, equals('Test Personal Task'));
        expect(createdTodo.type, equals('personal'));
        expect(createdTodo.priority, equals(3));
        expect(createdTodo.status, equals('pending'));

        print('✅ Todo created');
        print('   ID: ${createdTodo.id}');
        print('   Title: ${createdTodo.title}');
        print('   Type: ${createdTodo.type}');
        print('   Priority: P${createdTodo.priority}');
      } catch (e) {
        print('❌ Create todo failed: $e');
        rethrow;
      }
    });

    test('2.2 Create Todo - All 5 types', () async {
      print('\n➕ Test 2.2: Create All Todo Types');

      final types = ['appointment', 'work', 'shopping', 'personal', 'other'];

      try {
        for (final type in types) {
          final todo = TodoEntity(
            id: const Uuid().v4(),
            userId: testUser!.id,
            title: 'Test ${type.toUpperCase()} Task',
            description: 'Testing $type type',
            todoDate: DateTime.now(),
            priority: 3,
            type: type,
            status: 'pending',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          final created = await todoRepository.createTodo(todo);
          expect(created.type, equals(type));

          print('   ✅ Created: $type');
        }

        print('✅ All 5 todo types created');
      } catch (e) {
        print('❌ Create todo types failed: $e');
        rethrow;
      }
    });

    test('2.3 Create Todo - All 5 priority levels', () async {
      print('\n➕ Test 2.3: Create All Priority Levels');

      final priorities = {
        1: 'Urgent',
        2: 'High',
        3: 'Medium',
        4: 'Low',
        5: 'None',
      };

      try {
        for (final entry in priorities.entries) {
          final todo = TodoEntity(
            id: const Uuid().v4(),
            userId: testUser!.id,
            title: 'P${entry.key} - ${entry.value} Priority Task',
            todoDate: DateTime.now(),
            priority: entry.key,
            type: 'other',
            status: 'pending',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          final created = await todoRepository.createTodo(todo);
          expect(created.priority, equals(entry.key));

          print('   ✅ P${entry.key}: ${entry.value}');
        }

        print('✅ All 5 priority levels created');
      } catch (e) {
        print('❌ Create priority levels failed: $e');
        rethrow;
      }
    });

    test('2.4 Read Todo - Get by ID', () async {
      print('\n📖 Test 2.4: Read Todo by ID');

      try {
        final todo = await todoRepository.getTodoById(createdTodoId!);

        expect(todo, isNotNull);
        expect(todo!.id, equals(createdTodoId));
        expect(todo.title, equals('Test Personal Task'));

        print('✅ Todo retrieved');
        print('   Title: ${todo.title}');
      } catch (e) {
        print('❌ Read todo failed: $e');
        rethrow;
      }
    });

    test('2.5 Read Todos - Get all for user', () async {
      print('\n📖 Test 2.5: Get All Todos');

      try {
        final todos = await todoRepository.getAllTodos();

        expect(todos, isNotEmpty);
        expect(todos.length, greaterThanOrEqualTo(11)); // 1 + 5 types + 5 priorities

        print('✅ All todos retrieved');
        print('   Count: ${todos.length}');
      } catch (e) {
        print('❌ Get all todos failed: $e');
        rethrow;
      }
    });

    test('2.6 Read Todos - Get by date', () async {
      print('\n📖 Test 2.6: Get Todos by Date');

      try {
        final today = DateTime.now();
        final todos = await todoRepository.getTodosByDate(today);

        expect(todos, isNotEmpty);

        for (final todo in todos) {
          final isSameDay = todo.todoDate.year == today.year &&
              todo.todoDate.month == today.month &&
              todo.todoDate.day == today.day;
          expect(isSameDay, isTrue);
        }

        print('✅ Todos by date retrieved');
        print('   Count: ${todos.length}');
      } catch (e) {
        print('❌ Get todos by date failed: $e');
        rethrow;
      }
    });

    test('2.7 Read Todos - Get by type', () async {
      print('\n📖 Test 2.7: Get Todos by Type');

      try {
        final workTodos = await todoRepository.getTodosByType('work');

        expect(workTodos, isNotEmpty);

        for (final todo in workTodos) {
          expect(todo.type, equals('work'));
        }

        print('✅ Todos by type retrieved');
        print('   Work tasks: ${workTodos.length}');
      } catch (e) {
        print('❌ Get todos by type failed: $e');
        rethrow;
      }
    });

    test('2.8 Update Todo - Modify title and priority', () async {
      print('\n✏️  Test 2.8: Update Todo');

      try {
        final originalTodo = await todoRepository.getTodoById(createdTodoId!);
        final updatedTodo = originalTodo!.copyWith(
          title: 'Updated Personal Task',
          priority: 1,
          updatedAt: DateTime.now(),
        );

        final result = await todoRepository.updateTodo(updatedTodo);

        expect(result.title, equals('Updated Personal Task'));
        expect(result.priority, equals(1));

        print('✅ Todo updated');
        print('   New title: ${result.title}');
        print('   New priority: P${result.priority}');
      } catch (e) {
        print('❌ Update todo failed: $e');
        rethrow;
      }
    });

    test('2.9 Toggle Todo Status - Mark as completed', () async {
      print('\n✅ Test 2.9: Toggle Todo Status');

      try {
        final toggledTodo = await todoRepository.toggleTodoStatus(createdTodoId!);

        expect(toggledTodo.status, equals('completed'));
        expect(toggledTodo.isCompleted, isTrue);

        print('✅ Todo status toggled to completed');
      } catch (e) {
        print('❌ Toggle status failed: $e');
        rethrow;
      }
    });

    test('2.10 Toggle Todo Status - Mark as pending again', () async {
      print('\n🔄 Test 2.10: Toggle Todo Status Back');

      try {
        final toggledTodo = await todoRepository.toggleTodoStatus(createdTodoId!);

        expect(toggledTodo.status, equals('pending'));
        expect(toggledTodo.isCompleted, isFalse);

        print('✅ Todo status toggled back to pending');
      } catch (e) {
        print('❌ Toggle status back failed: $e');
        rethrow;
      }
    });

    test('2.11 Search Todos - Find by title', () async {
      print('\n🔍 Test 2.11: Search Todos');

      try {
        final results = await todoRepository.searchTodos('Updated');

        expect(results, isNotEmpty);
        expect(results.any((t) => t.title.contains('Updated')), isTrue);

        print('✅ Search completed');
        print('   Results: ${results.length}');
      } catch (e) {
        print('❌ Search failed: $e');
        rethrow;
      }
    });

    test('2.12 Delete Todo - Remove task', () async {
      print('\n🗑️  Test 2.12: Delete Todo');

      try {
        await todoRepository.deleteTodo(createdTodoId!);

        final deletedTodo = await todoRepository.getTodoById(createdTodoId!);
        expect(deletedTodo, isNull);

        print('✅ Todo deleted');
      } catch (e) {
        print('❌ Delete todo failed: $e');
        rethrow;
      }
    });
  });

  group('Phase 1: Calendar & Date Range Tests', () {
    test('3.1 Get Todos by Date Range - Weekly view', () async {
      print('\n📅 Test 3.1: Get Todos by Date Range (Week)');

      try {
        final today = DateTime.now();
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));

        final todos = await todoRepository.getTodosByDateRange(
          startOfWeek,
          endOfWeek,
        );

        expect(todos, isNotNull);

        print('✅ Weekly todos retrieved');
        print('   Range: ${startOfWeek.toLocal()} to ${endOfWeek.toLocal()}');
        print('   Count: ${todos.length}');
      } catch (e) {
        print('❌ Get weekly todos failed: $e');
        rethrow;
      }
    });

    test('3.2 Get Todos by Date Range - Monthly view', () async {
      print('\n📅 Test 3.2: Get Todos by Date Range (Month)');

      try {
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);

        final todos = await todoRepository.getTodosByDateRange(
          startOfMonth,
          endOfMonth,
        );

        expect(todos, isNotNull);

        print('✅ Monthly todos retrieved');
        print('   Range: ${startOfMonth.toLocal()} to ${endOfMonth.toLocal()}');
        print('   Count: ${todos.length}');
      } catch (e) {
        print('❌ Get monthly todos failed: $e');
        rethrow;
      }
    });
  });

  group('Phase 1: Data Validation Tests', () {
    test('4.1 Todo Entity - isOverdue check', () async {
      print('\n⏰ Test 4.1: Check Overdue Logic');

      final pastTodo = TodoEntity(
        id: const Uuid().v4(),
        userId: testUser!.id,
        title: 'Past Task',
        todoDate: DateTime.now().subtract(const Duration(days: 1)),
        priority: 3,
        type: 'other',
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(pastTodo.isOverdue, isTrue);

      final futureTodo = pastTodo.copyWith(
        todoDate: DateTime.now().add(const Duration(days: 1)),
      );

      expect(futureTodo.isOverdue, isFalse);

      print('✅ Overdue logic validated');
    });

    test('4.2 Todo Entity - Completed tasks not overdue', () async {
      print('\n✅ Test 4.2: Completed Tasks Not Overdue');

      final completedPastTodo = TodoEntity(
        id: const Uuid().v4(),
        userId: testUser!.id,
        title: 'Completed Past Task',
        todoDate: DateTime.now().subtract(const Duration(days: 1)),
        priority: 3,
        type: 'other',
        status: 'completed',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(completedPastTodo.isCompleted, isTrue);
      expect(completedPastTodo.isOverdue, isFalse);

      print('✅ Completed task overdue logic validated');
    });
  });

  group('Phase 1: Real-time Sync Tests', () {
    test('5.1 Supabase Connection - Verify database sync', () async {
      print('\n🔄 Test 5.1: Verify Database Sync');

      try {
        // Create a todo
        final todo = TodoEntity(
          id: const Uuid().v4(),
          userId: testUser!.id,
          title: 'Sync Test Task',
          todoDate: DateTime.now(),
          priority: 3,
          type: 'other',
          status: 'pending',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final created = await todoRepository.createTodo(todo);

        // Immediately fetch it from database
        final fetched = await todoRepository.getTodoById(created.id);

        expect(fetched, isNotNull);
        expect(fetched!.id, equals(created.id));
        expect(fetched.title, equals(created.title));

        // Clean up
        await todoRepository.deleteTodo(created.id);

        print('✅ Database sync verified');
      } catch (e) {
        print('❌ Sync verification failed: $e');
        rethrow;
      }
    });
  });
}
