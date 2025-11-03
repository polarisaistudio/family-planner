import '../entities/todo_entity.dart';

/// Abstract repository interface for todo operations
abstract class TodoRepository {
  /// Get all todos for the current user
  Future<List<TodoEntity>> getAllTodos();

  /// Get todos for a specific date
  Future<List<TodoEntity>> getTodosByDate(DateTime date);

  /// Get todos within a date range
  Future<List<TodoEntity>> getTodosByDateRange(DateTime start, DateTime end);

  /// Get a single todo by ID
  Future<TodoEntity?> getTodoById(String id);

  /// Create a new todo
  Future<TodoEntity> createTodo(TodoEntity todo);

  /// Create multiple todos in a batch (optimized for recurring tasks)
  Future<List<TodoEntity>> createTodosBatch(List<TodoEntity> todos);

  /// Update an existing todo
  Future<TodoEntity> updateTodo(TodoEntity todo);

  /// Delete a todo
  Future<void> deleteTodo(String id);

  /// Toggle todo completion status
  Future<TodoEntity> toggleTodoStatus(String id);

  /// Get todos by status
  Future<List<TodoEntity>> getTodosByStatus(String status);

  /// Get todos by type
  Future<List<TodoEntity>> getTodosByType(String type);

  /// Stream of all todos (real-time updates)
  Stream<List<TodoEntity>> watchTodos();

  /// Search todos by title or description
  Future<List<TodoEntity>> searchTodos(String query);
}
