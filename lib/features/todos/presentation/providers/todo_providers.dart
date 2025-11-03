import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/firebase_todo_repository_impl.dart';
import '../../domain/entities/todo_entity.dart';
import '../../domain/repositories/todo_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Provider for TodoRepository
final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  return FirebaseTodoRepositoryImpl(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

/// Provider for all todos
final todosProvider = StateNotifierProvider<TodosNotifier, AsyncValue<List<TodoEntity>>>((ref) {
  return TodosNotifier(ref.watch(todoRepositoryProvider));
});

/// Notifier for managing todos state
class TodosNotifier extends StateNotifier<AsyncValue<List<TodoEntity>>> {
  final TodoRepository _todoRepository;

  TodosNotifier(this._todoRepository) : super(const AsyncValue.loading()) {
    loadTodos();
  }

  /// Load all todos
  Future<void> loadTodos() async {
    state = const AsyncValue.loading();
    try {
      final todos = await _todoRepository.getAllTodos();
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
  final repository = ref.watch(todoRepositoryProvider);
  return await repository.getTodosByDate(date);
});

/// Provider for todos by date range
final todosByDateRangeProvider = FutureProvider.family<List<TodoEntity>, DateRange>((ref, dateRange) async {
  final repository = ref.watch(todoRepositoryProvider);
  return await repository.getTodosByDateRange(dateRange.start, dateRange.end);
});

/// Provider for a single todo by ID
final todoByIdProvider = FutureProvider.family<TodoEntity?, String>((ref, id) async {
  final repository = ref.watch(todoRepositoryProvider);
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
