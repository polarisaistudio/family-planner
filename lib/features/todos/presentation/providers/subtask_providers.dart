import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/subtask_entity.dart';
import '../../data/repositories/subtask_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

// Provider for SubtaskRepository
final subtaskRepositoryProvider = Provider<SubtaskRepository>((ref) {
  final authRepo = ref.watch(unifiedAuthRepositoryProvider);

  return SubtaskRepository(
    client: http.Client(),
    getIdToken: () {
      final token = authRepo.getIdToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }
      return token;
    },
  );
});

// Provider for subtasks state management
final subtasksProvider = StateNotifierProvider<SubtasksNotifier, AsyncValue<Map<String, List<SubtaskEntity>>>>((ref) {
  return SubtasksNotifier(ref);
});

class SubtasksNotifier extends StateNotifier<AsyncValue<Map<String, List<SubtaskEntity>>>> {
  final Ref _ref;

  SubtasksNotifier(this._ref) : super(const AsyncValue.data({}));

  SubtaskRepository get _repository => _ref.read(subtaskRepositoryProvider);

  /// Load subtasks for a specific todo
  Future<void> loadSubtasksForTodo(String todoId) async {
    try {
      final subtasks = await _repository.getSubtasksForTodo(todoId);

      state = state.whenData((data) {
        final newData = Map<String, List<SubtaskEntity>>.from(data);
        newData[todoId] = subtasks;
        return newData;
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Create subtasks for a todo
  Future<void> createSubtasks(String todoId, List<SubtaskEntity> subtasks) async {
    if (subtasks.isEmpty) return;

    try {
      // Update todoId for all subtasks
      final updatedSubtasks = subtasks.map((s) => s.copyWith(todoId: todoId)).toList();

      // Try batch first, fall back to individual creates if it fails with 403
      try {
        await _repository.createSubtasksBatch(updatedSubtasks);
      } catch (batchError) {
        print('🟡 [SUBTASKS] Batch create failed, trying individual creates: $batchError');
        // Fall back to creating subtasks one by one
        for (final subtask in updatedSubtasks) {
          await _repository.createSubtask(subtask);
        }
      }

      state = state.whenData((data) {
        final newData = Map<String, List<SubtaskEntity>>.from(data);
        newData[todoId] = updatedSubtasks;
        return newData;
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Toggle subtask completion
  Future<void> toggleSubtask(String todoId, String subtaskId, bool isCompleted) async {
    try {
      await _repository.toggleSubtaskCompletion(subtaskId, isCompleted);

      state = state.whenData((data) {
        final newData = Map<String, List<SubtaskEntity>>.from(data);
        final todoSubtasks = newData[todoId];

        if (todoSubtasks != null) {
          final updatedSubtasks = todoSubtasks.map((s) {
            if (s.id == subtaskId) {
              return s.copyWith(
                isCompleted: isCompleted,
                completedAt: isCompleted ? DateTime.now() : null,
              );
            }
            return s;
          }).toList();

          newData[todoId] = updatedSubtasks;
        }

        return newData;
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Update a subtask
  Future<void> updateSubtask(String todoId, SubtaskEntity subtask) async {
    try {
      await _repository.updateSubtask(subtask);

      state = state.whenData((data) {
        final newData = Map<String, List<SubtaskEntity>>.from(data);
        final todoSubtasks = newData[todoId];

        if (todoSubtasks != null) {
          final updatedSubtasks = todoSubtasks.map((s) {
            return s.id == subtask.id ? subtask : s;
          }).toList();

          newData[todoId] = updatedSubtasks;
        }

        return newData;
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Delete a subtask
  Future<void> deleteSubtask(String todoId, String subtaskId) async {
    try {
      await _repository.deleteSubtask(subtaskId);

      state = state.whenData((data) {
        final newData = Map<String, List<SubtaskEntity>>.from(data);
        final todoSubtasks = newData[todoId];

        if (todoSubtasks != null) {
          final updatedSubtasks = todoSubtasks.where((s) => s.id != subtaskId).toList();
          newData[todoId] = updatedSubtasks;
        }

        return newData;
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Delete all subtasks for a todo
  Future<void> deleteSubtasksForTodo(String todoId) async {
    try {
      // Get the subtasks first so we can delete them individually if batch fails
      final subtasks = await _repository.getSubtasksForTodo(todoId);

      if (subtasks.isEmpty) {
        return;
      }

      // Try batch delete first, fall back to individual deletes if it fails with 403
      try {
        await _repository.deleteSubtasksForTodo(todoId);
      } catch (batchError) {
        print('🟡 [SUBTASKS] Batch delete failed, trying individual deletes: $batchError');
        // Fall back to deleting subtasks one by one
        for (final subtask in subtasks) {
          await _repository.deleteSubtask(subtask.id);
        }
      }

      state = state.whenData((data) {
        final newData = Map<String, List<SubtaskEntity>>.from(data);
        newData.remove(todoId);
        return newData;
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Get subtasks for a specific todo from the state
  List<SubtaskEntity> getSubtasksForTodo(String todoId) {
    return state.maybeWhen(
      data: (data) => data[todoId] ?? [],
      orElse: () => [],
    );
  }
}
