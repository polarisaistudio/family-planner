// import 'package:firebase_auth/firebase_auth.dart';  // Disabled for iOS
// import 'package:cloud_firestore/cloud_firestore.dart';  // Disabled for iOS
import '../../domain/entities/todo_entity.dart';
import '../../../../core/platform/platform_service.dart';
// import 'firebase_todo_repository_impl.dart';  // SDK-based, not used on iOS
import 'firebase_rest_todo_repository.dart';
import '../../../auth/data/repositories/unified_auth_repository.dart';

/// Unified todo repository that uses REST API for iOS
class UnifiedTodoRepository {
  final FirebaseRestTodoRepository _restAPI;
  final UnifiedAuthRepository _authRepository;

  UnifiedTodoRepository({
    required UnifiedAuthRepository authRepository,
    dynamic firebaseAuth,   // Not used on iOS
    dynamic firestore,      // Not used on iOS
  })  : _authRepository = authRepository,
        _restAPI = FirebaseRestTodoRepository(
          getUserId: () => authRepository.getCurrentUserIdSync() ?? '',
          getIdToken: () => authRepository.getIdToken() ?? '',
        );

  Future<List<TodoEntity>> getTodos() async {
    print('📱 [UNIFIED TODO] Using REST API (iOS)');
    return await _restAPI.getTodos();
  }

  Future<TodoEntity> createTodo(TodoEntity todo) async {
    return await _restAPI.createTodo(todo);
  }

  Future<List<TodoEntity>> createTodosBatch(List<TodoEntity> todos) async {
    return await _restAPI.createTodosBatch(todos);
  }

  Future<TodoEntity> updateTodo(TodoEntity todo) async {
    return await _restAPI.updateTodo(todo);
  }

  Future<void> deleteTodo(String todoId) async {
    return await _restAPI.deleteTodo(todoId);
  }

  Stream<List<TodoEntity>> watchTodos() {
    // REST API doesn't support real-time streams
    // Return a stream that emits once
    return Stream.fromFuture(_restAPI.getTodos());
  }

  Future<List<TodoEntity>> getTodosByDate(DateTime date) async {
    return await _restAPI.getTodosByDate(date);
  }

  Future<List<TodoEntity>> getTodosByDateRange(DateTime start, DateTime end) async {
    return await _restAPI.getTodosByDateRange(start, end);
  }

  Future<TodoEntity?> getTodoById(String id) async {
    return await _restAPI.getTodoById(id);
  }

  Future<TodoEntity> toggleTodoStatus(String id) async {
    return await _restAPI.toggleTodoStatus(id);
  }
}
