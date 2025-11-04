import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/todo_entity.dart';
import '../../../../core/platform/platform_service.dart';
import 'firebase_todo_repository_impl.dart';
import 'firebase_rest_todo_repository.dart';
import '../../../auth/data/repositories/unified_auth_repository.dart';

/// Unified todo repository that uses Firebase SDK or REST API based on platform
class UnifiedTodoRepository {
  final FirebaseTodoRepositoryImpl? _firebaseSDK;
  final FirebaseRestTodoRepository? _restAPI;
  final UnifiedAuthRepository _authRepository;

  UnifiedTodoRepository({
    required UnifiedAuthRepository authRepository,
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _authRepository = authRepository,
        _firebaseSDK = PlatformService.useFirebaseSDK && firebaseAuth != null && firestore != null
            ? FirebaseTodoRepositoryImpl(firestore, firebaseAuth)
            : null,
        _restAPI = PlatformService.useRestApi
            ? FirebaseRestTodoRepository(
                getUserId: () => authRepository.getCurrentUserIdSync() ?? '',
                getIdToken: () => authRepository.getIdToken() ?? '',
              )
            : null;

  Future<List<TodoEntity>> getTodos() async {
    if (PlatformService.useRestApi) {
      print('📱 [UNIFIED TODO] Using REST API (iOS)');
      return await _restAPI!.getTodos();
    } else {
      print('🌐 [UNIFIED TODO] Using Firebase SDK (Web/Android)');
      return await _firebaseSDK!.getAllTodos();
    }
  }

  Future<TodoEntity> createTodo(TodoEntity todo) async {
    if (PlatformService.useRestApi) {
      return await _restAPI!.createTodo(todo);
    } else {
      return await _firebaseSDK!.createTodo(todo);
    }
  }

  Future<List<TodoEntity>> createTodosBatch(List<TodoEntity> todos) async {
    if (PlatformService.useRestApi) {
      return await _restAPI!.createTodosBatch(todos);
    } else {
      return await _firebaseSDK!.createTodosBatch(todos);
    }
  }

  Future<TodoEntity> updateTodo(TodoEntity todo) async {
    if (PlatformService.useRestApi) {
      return await _restAPI!.updateTodo(todo);
    } else {
      return await _firebaseSDK!.updateTodo(todo);
    }
  }

  Future<void> deleteTodo(String todoId) async {
    if (PlatformService.useRestApi) {
      return await _restAPI!.deleteTodo(todoId);
    } else {
      return await _firebaseSDK!.deleteTodo(todoId);
    }
  }

  Stream<List<TodoEntity>> watchTodos() {
    if (PlatformService.useRestApi) {
      // REST API doesn't support real-time streams
      // Return a stream that emits once
      return Stream.fromFuture(_restAPI!.getTodos());
    } else {
      return _firebaseSDK!.watchTodos();
    }
  }

  Future<List<TodoEntity>> getTodosByDate(DateTime date) async {
    if (PlatformService.useRestApi) {
      return await _restAPI!.getTodosByDate(date);
    } else {
      return await _firebaseSDK!.getTodosByDate(date);
    }
  }

  Future<List<TodoEntity>> getTodosByDateRange(DateTime start, DateTime end) async {
    if (PlatformService.useRestApi) {
      return await _restAPI!.getTodosByDateRange(start, end);
    } else {
      return await _firebaseSDK!.getTodosByDateRange(start, end);
    }
  }

  Future<TodoEntity?> getTodoById(String id) async {
    if (PlatformService.useRestApi) {
      return await _restAPI!.getTodoById(id);
    } else {
      return await _firebaseSDK!.getTodoById(id);
    }
  }

  Future<TodoEntity> toggleTodoStatus(String id) async {
    if (PlatformService.useRestApi) {
      return await _restAPI!.toggleTodoStatus(id);
    } else {
      return await _firebaseSDK!.toggleTodoStatus(id);
    }
  }
}
