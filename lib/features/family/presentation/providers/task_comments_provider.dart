import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/family_member_entity.dart';
import '../../data/repositories/family_repository.dart';
import 'family_provider.dart';

// State class for task comments
class TaskCommentsState {
  final List<TaskCommentEntity> comments;
  final bool isLoading;
  final String? error;

  TaskCommentsState({
    required this.comments,
    required this.isLoading,
    this.error,
  });

  TaskCommentsState copyWith({
    List<TaskCommentEntity>? comments,
    bool? isLoading,
    String? error,
  }) {
    return TaskCommentsState(
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// StateNotifier for managing task comments
class TaskCommentsNotifier extends StateNotifier<TaskCommentsState> {
  final FamilyRepository _repository;
  final String taskId;

  TaskCommentsNotifier(this._repository, this.taskId)
      : super(TaskCommentsState(
          comments: [],
          isLoading: false,
        ));

  /// Load comments for the task
  Future<void> loadComments() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final comments = await _repository.getTaskComments(taskId);

      // Sort comments by creation date (oldest first)
      comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      state = state.copyWith(
        comments: comments,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Add a new comment
  Future<void> addComment(TaskCommentEntity comment) async {
    try {
      await _repository.addTaskComment(comment);

      // Add the comment to the state immediately for better UX
      state = state.copyWith(
        comments: [...state.comments, comment],
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Delete a comment
  Future<void> deleteComment(String commentId) async {
    try {
      await _repository.deleteTaskComment(commentId);

      // Remove the comment from the state
      state = state.copyWith(
        comments: state.comments.where((c) => c.id != commentId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Clear any error messages
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider family for task comments (different provider for each task)
final taskCommentsProvider = StateNotifierProvider.family<TaskCommentsNotifier, TaskCommentsState, String>(
  (ref, taskId) {
    final repository = ref.watch(familyRepositoryProvider);
    return TaskCommentsNotifier(repository, taskId);
  },
);
