import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/todo_entity.dart';
import '../../domain/repositories/todo_repository.dart';
import '../models/todo_model.dart';

/// Concrete implementation of TodoRepository using Supabase
class TodoRepositoryImpl implements TodoRepository {
  final SupabaseClient _supabase;

  TodoRepositoryImpl(this._supabase);

  String? get _userId => _supabase.auth.currentUser?.id;

  void _checkAuth() {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }
  }

  @override
  Future<List<TodoEntity>> getAllTodos() async {
    _checkAuth();
    try {
      final response = await _supabase
          .from('todos')
          .select()
          .eq('user_id', _userId!)
          .order('todo_date', ascending: true)
          .order('todo_time', ascending: true);

      return (response as List)
          .map((json) => TodoModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get todos: $e');
    }
  }

  @override
  Future<List<TodoEntity>> getTodosByDate(DateTime date) async {
    _checkAuth();
    try {
      final dateString = DateFormat('yyyy-MM-dd').format(date);
      final response = await _supabase
          .from('todos')
          .select()
          .eq('user_id', _userId!)
          .eq('todo_date', dateString)
          .order('todo_time', ascending: true);

      return (response as List)
          .map((json) => TodoModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get todos by date: $e');
    }
  }

  @override
  Future<List<TodoEntity>> getTodosByDateRange(
      DateTime start, DateTime end) async {
    _checkAuth();
    try {
      final startString = DateFormat('yyyy-MM-dd').format(start);
      final endString = DateFormat('yyyy-MM-dd').format(end);

      final response = await _supabase
          .from('todos')
          .select()
          .eq('user_id', _userId!)
          .gte('todo_date', startString)
          .lte('todo_date', endString)
          .order('todo_date', ascending: true)
          .order('todo_time', ascending: true);

      return (response as List)
          .map((json) => TodoModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get todos by date range: $e');
    }
  }

  @override
  Future<TodoEntity?> getTodoById(String id) async {
    _checkAuth();
    try {
      final response = await _supabase
          .from('todos')
          .select()
          .eq('id', id)
          .eq('user_id', _userId!)
          .maybeSingle();

      if (response == null) return null;
      return TodoModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get todo: $e');
    }
  }

  @override
  Future<TodoEntity> createTodo(TodoEntity todo) async {
    _checkAuth();
    try {
      final todoModel = TodoModel.fromEntity(todo);
      final json = todoModel.toJson();

      // Remove fields that should be auto-generated
      json.remove('id');
      json.remove('created_at');
      json.remove('updated_at');

      // Ensure user_id is set
      json['user_id'] = _userId!;

      final response =
          await _supabase.from('todos').insert(json).select().single();

      return TodoModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create todo: $e');
    }
  }

  @override
  Future<TodoEntity> updateTodo(TodoEntity todo) async {
    _checkAuth();
    try {
      final todoModel = TodoModel.fromEntity(todo);
      final json = todoModel.toJson();

      // Remove fields that shouldn't be updated directly
      json.remove('id');
      json.remove('user_id');
      json.remove('created_at');

      // Update timestamp
      json['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('todos')
          .update(json)
          .eq('id', todo.id)
          .eq('user_id', _userId!)
          .select()
          .single();

      return TodoModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update todo: $e');
    }
  }

  @override
  Future<void> deleteTodo(String id) async {
    _checkAuth();
    try {
      await _supabase.from('todos').delete().eq('id', id).eq('user_id', _userId!);
    } catch (e) {
      throw Exception('Failed to delete todo: $e');
    }
  }

  @override
  Future<TodoEntity> toggleTodoStatus(String id) async {
    _checkAuth();
    try {
      final todo = await getTodoById(id);
      if (todo == null) {
        throw Exception('Todo not found');
      }

      final newStatus = todo.isCompleted ? 'pending' : 'completed';
      final updatedTodo = todo.copyWith(status: newStatus);

      return await updateTodo(updatedTodo);
    } catch (e) {
      throw Exception('Failed to toggle todo status: $e');
    }
  }

  @override
  Future<List<TodoEntity>> getTodosByStatus(String status) async {
    _checkAuth();
    try {
      final response = await _supabase
          .from('todos')
          .select()
          .eq('user_id', _userId!)
          .eq('status', status)
          .order('todo_date', ascending: true);

      return (response as List)
          .map((json) => TodoModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get todos by status: $e');
    }
  }

  @override
  Future<List<TodoEntity>> getTodosByType(String type) async {
    _checkAuth();
    try {
      final response = await _supabase
          .from('todos')
          .select()
          .eq('user_id', _userId!)
          .eq('type', type)
          .order('todo_date', ascending: true);

      return (response as List)
          .map((json) => TodoModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get todos by type: $e');
    }
  }

  @override
  Stream<List<TodoEntity>> watchTodos() {
    _checkAuth();
    return _supabase
        .from('todos')
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId!)
        .order('todo_date', ascending: true)
        .map((data) =>
            data.map((json) => TodoModel.fromJson(json)).toList());
  }

  @override
  Future<List<TodoEntity>> searchTodos(String query) async {
    _checkAuth();
    try {
      final response = await _supabase
          .from('todos')
          .select()
          .eq('user_id', _userId!)
          .or('title.ilike.%$query%,description.ilike.%$query%')
          .order('todo_date', ascending: true);

      return (response as List)
          .map((json) => TodoModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search todos: $e');
    }
  }
}
