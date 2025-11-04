import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/firebase_todo_repository_impl.dart';
import '../../data/repositories/unified_todo_repository.dart';
import '../../domain/entities/todo_entity.dart';
import '../../domain/repositories/todo_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Provider for Unified Todo Repository (uses REST on iOS, SDK elsewhere)
final unifiedTodoRepositoryProvider = Provider<UnifiedTodoRepository>((ref) {
  final authRepo = ref.watch(unifiedAuthRepositoryProvider);
  return UnifiedTodoRepository(
    authRepository: authRepo,
    firebaseAuth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  );
});

/// Provider for all todos
final todosProvider = StateNotifierProvider<TodosNotifier, AsyncValue<List<TodoEntity>>>((ref) {
  return TodosNotifier(ref.watch(unifiedTodoRepositoryProvider));
});

/// Notifier for managing todos state
class TodosNotifier extends StateNotifier<AsyncValue<List<TodoEntity>>> {
  final UnifiedTodoRepository _todoRepository;

  TodosNotifier(this._todoRepository) : super(const AsyncValue.loading()) {
    loadTodos();
  }

  /// Load all todos
  Future<void> loadTodos() async {
    state = const AsyncValue.loading();
    try {
      final todos = await _todoRepository.getTodos();
      state = AsyncValue.data(todos);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Create a new todo
  Future<void> createTodo(TodoEntity todo) async {
    try {
      await _todoRepository.createTodo(todo);
      await loadTodos(); // Reload todos
    } catch (e) {
      // Handle error - repository already retries automatically
      rethrow;
    }
  }

  /// Create multiple todos in a batch (optimized for recurring tasks)
  Future<void> createTodosBatch(List<TodoEntity> todos) async {
    try {
      await _todoRepository.createTodosBatch(todos);
      await loadTodos(); // Reload todos once after all are created
    } catch (e) {
      rethrow;
    }
  }

  /// Update a todo
  Future<void> updateTodo(TodoEntity todo) async {
    try {
      await _todoRepository.updateTodo(todo);
      await loadTodos(); // Reload todos
    } catch (e) {
      // Handle error - repository already retries automatically
      rethrow;
    }
  }

  /// Delete a todo
  Future<void> deleteTodo(String id) async {
    try {
      await _todoRepository.deleteTodo(id);
      await loadTodos(); // Reload todos
    } catch (e) {
      // Handle error - repository already retries automatically
      rethrow;
    }
  }

  /// Delete all recurring todos with the same parent ID
  Future<void> deleteRecurringTodos(String parentId) async {
    try {
      print('🔵 [DELETE RECURRING] Starting deletion for parentId: $parentId');

      // Get all todos
      final allTodos = state.value ?? [];
      print('🔵 [DELETE RECURRING] Total todos: ${allTodos.length}');

      // Find all todos with matching parent ID or that are the parent
      final todosToDelete = allTodos.where((todo) =>
        todo.id == parentId || todo.recurrenceParentId == parentId
      ).toList();

      print('🔵 [DELETE RECURRING] Found ${todosToDelete.length} todos to delete');

      // Delete each one
      for (final todo in todosToDelete) {
        print('🔵 [DELETE RECURRING] Deleting todo: ${todo.id}');
        await _todoRepository.deleteTodo(todo.id);
      }

      print('🟢 [DELETE RECURRING] Deleted ${todosToDelete.length} todos, reloading...');
      await loadTodos(); // Reload todos
    } catch (e) {
      print('🔴 [DELETE RECURRING] Error: $e');
      rethrow;
    }
  }

  /// Toggle todo completion status
  Future<void> toggleTodoStatus(String id) async {
    try {
      await _todoRepository.toggleTodoStatus(id);
      await loadTodos(); // Reload todos
    } catch (e) {
      // Handle error - repository already retries automatically
      rethrow;
    }
  }

  /// Manually retry loading todos (for pull-to-refresh or error recovery)
  Future<void> retryLoadTodos() async {
    await loadTodos();
  }
}

/// Provider for todos by date
final todosByDateProvider = FutureProvider.family<List<TodoEntity>, DateTime>((ref, date) async {
  final repository = ref.watch(unifiedTodoRepositoryProvider);
  return await repository.getTodosByDate(date);
});

/// Provider for todos by date range
final todosByDateRangeProvider = FutureProvider.family<List<TodoEntity>, DateRange>((ref, dateRange) async {
  final repository = ref.watch(unifiedTodoRepositoryProvider);
  return await repository.getTodosByDateRange(dateRange.start, dateRange.end);
});

/// Provider for a single todo by ID
final todoByIdProvider = FutureProvider.family<TodoEntity?, String>((ref, id) async {
  final repository = ref.watch(unifiedTodoRepositoryProvider);
  return await repository.getTodoById(id);
});

/// Provider for selected date in calendar
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Helper class for date range
class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange(this.start, this.end);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}
