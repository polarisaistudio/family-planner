import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../domain/entities/subtask_entity.dart';

class SubtaskRepository {
  static const String _projectId = 'family-planner-86edd';
  static const String _firebaseApiKey = 'AIzaSyAcbjRJIbMLDG5OEJytuBCaWBd8o0pMIWI';
  static const String _firestoreBaseUrl = 'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents';

  final http.Client _client;
  final String Function() _getIdToken;

  SubtaskRepository({
    required http.Client client,
    required String Function() getIdToken,
  })  : _client = client,
        _getIdToken = getIdToken;

  /// Create a new subtask
  Future<void> createSubtask(SubtaskEntity subtask) async {
    print('🔵 [SUBTASK REPO] Creating individual subtask: ${subtask.id} for todo: ${subtask.todoId}');
    final token = _getIdToken();
    final url = '$_firestoreBaseUrl/subtasks/${subtask.id}?key=$_firebaseApiKey';
    print('🔵 [SUBTASK REPO] PATCH URL: $url');

    final response = await _client.patch(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'fields': _toFirestoreFields(subtask),
      }),
    );

    print('🔵 [SUBTASK REPO] Individual create response status: ${response.statusCode}');

    if (response.statusCode != 200) {
      print('❌ [SUBTASK REPO] Individual create failed: ${response.body}');
      throw Exception('Failed to create subtask: ${response.body}');
    }

    print('✅ [SUBTASK REPO] Successfully created subtask: ${subtask.id}');
  }

  /// Batch create multiple subtasks
  Future<void> createSubtasksBatch(List<SubtaskEntity> subtasks) async {
    if (subtasks.isEmpty) return;

    final token = _getIdToken();
    print('🔵 [SUBTASK REPO] Token available: ${token != null}, length: ${token?.length ?? 0}');
    final url = '$_firestoreBaseUrl:batchWrite?key=$_firebaseApiKey';

    final writes = subtasks.map((subtask) {
      return {
        'update': {
          'name': 'projects/$_projectId/databases/(default)/documents/subtasks/${subtask.id}',
          'fields': _toFirestoreFields(subtask),
        },
        'currentDocument': {
          'exists': false, // Create new document
        },
      };
    }).toList();

    print('🔵 [SUBTASK REPO] Sending batch write to: $url');
    print('🔵 [SUBTASK REPO] Number of writes: ${writes.length}');

    final response = await _client.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'writes': writes}),
    );

    if (response.statusCode != 200) {
      print('🔴 [SUBTASK REPO] Batch create failed with status ${response.statusCode}');
      print('🔴 [SUBTASK REPO] Request body: ${json.encode({'writes': writes})}');
      print('🔴 [SUBTASK REPO] Response: ${response.body}');
      throw Exception('Failed to batch create subtasks (${response.statusCode}): ${response.body}');
    }

    print('🟢 [SUBTASK REPO] Batch create successful');
  }

  /// Get all subtasks for a todo
  Future<List<SubtaskEntity>> getSubtasksForTodo(String todoId) async {
    print('🔵 [SUBTASK REPO] Fetching subtasks for todo: $todoId');
    final token = _getIdToken();
    final url = '$_firestoreBaseUrl:runQuery?key=$_firebaseApiKey';

    final response = await _client.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'structuredQuery': {
          'from': [
            {'collectionId': 'subtasks'}
          ],
          'where': {
            'fieldFilter': {
              'field': {'fieldPath': 'todoId'},
              'op': 'EQUAL',
              'value': {'stringValue': todoId}
            }
          },
          // Removed orderBy temporarily - will sort in memory instead
          // 'orderBy': [
          //   {
          //     'field': {'fieldPath': 'order'},
          //     'direction': 'ASCENDING'
          //   }
          // ]
        }
      }),
    );

    print('🔵 [SUBTASK REPO] Query response status: ${response.statusCode}');

    if (response.statusCode != 200) {
      print('❌ [SUBTASK REPO] Query failed: ${response.body}');
      throw Exception('Failed to get subtasks: ${response.body}');
    }

    print('🔵 [SUBTASK REPO] Response body: ${response.body}');

    final dynamic decodedResponse = json.decode(response.body);
    print('🔵 [SUBTASK REPO] Decoded response type: ${decodedResponse.runtimeType}');

    // Firestore runQuery returns an array, but empty results return [{}]
    final List<dynamic> results = decodedResponse is List ? decodedResponse : [];
    print('🔵 [SUBTASK REPO] Number of results: ${results.length}');

    final subtasks = <SubtaskEntity>[];

    for (var i = 0; i < results.length; i++) {
      final result = results[i];
      print('🔵 [SUBTASK REPO] Result $i: ${result.runtimeType}, has document: ${result['document'] != null}');

      if (result is Map && result['document'] != null) {
        try {
          final document = result['document'] as Map<String, dynamic>;
          final fields = document['fields'] as Map<String, dynamic>;
          final subtask = _fromFirestoreFields(fields);
          subtasks.add(subtask);
          print('🔵 [SUBTASK REPO] Parsed subtask: ${subtask.id} - ${subtask.title}');
        } catch (e) {
          print('❌ [SUBTASK REPO] Failed to parse result $i: $e');
        }
      }
    }

    // Sort by order field in memory (since we removed orderBy from query to avoid index requirement)
    subtasks.sort((a, b) => a.order.compareTo(b.order));

    print('✅ [SUBTASK REPO] Found ${subtasks.length} subtasks for todo $todoId');
    return subtasks;
  }

  /// Update a subtask
  Future<void> updateSubtask(SubtaskEntity subtask) async {
    final token = _getIdToken();
    final url = '$_firestoreBaseUrl/subtasks/${subtask.id}?key=$_firebaseApiKey';

    final response = await _client.patch(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'fields': _toFirestoreFields(subtask),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update subtask: ${response.body}');
    }
  }

  /// Toggle subtask completion status
  Future<void> toggleSubtaskCompletion(String subtaskId, bool isCompleted) async {
    final token = _getIdToken();
    final url = '$_firestoreBaseUrl/subtasks/$subtaskId?key=$_firebaseApiKey&updateMask.fieldPaths=isCompleted&updateMask.fieldPaths=completedAt';

    final fields = {
      'isCompleted': {'booleanValue': isCompleted},
      'completedAt': isCompleted
          ? {'timestampValue': DateTime.now().toUtc().toIso8601String()}
          : {'nullValue': null},
    };

    final response = await _client.patch(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'fields': fields}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to toggle subtask: ${response.body}');
    }
  }

  /// Delete a subtask
  Future<void> deleteSubtask(String subtaskId) async {
    final token = _getIdToken();
    final url = '$_firestoreBaseUrl/subtasks/$subtaskId?key=$_firebaseApiKey';

    final response = await _client.delete(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete subtask: ${response.body}');
    }
  }

  /// Delete all subtasks for a todo
  Future<void> deleteSubtasksForTodo(String todoId) async {
    final subtasks = await getSubtasksForTodo(todoId);

    final token = _getIdToken();
    final url = '$_firestoreBaseUrl:batchWrite?key=$_firebaseApiKey';

    final deletes = subtasks.map((subtask) {
      return {
        'delete': 'projects/$_projectId/databases/(default)/documents/subtasks/${subtask.id}',
      };
    }).toList();

    if (deletes.isEmpty) return;

    final response = await _client.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'writes': deletes}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to batch delete subtasks: ${response.body}');
    }
  }

  // Helper method to convert SubtaskEntity to Firestore fields format
  Map<String, dynamic> _toFirestoreFields(SubtaskEntity subtask) {
    return {
      'id': {'stringValue': subtask.id},
      'todoId': {'stringValue': subtask.todoId},
      'title': {'stringValue': subtask.title},
      'isCompleted': {'booleanValue': subtask.isCompleted},
      'order': {'integerValue': subtask.order.toString()},
      'createdAt': {'timestampValue': subtask.createdAt.toUtc().toIso8601String()},
      'completedAt': subtask.completedAt != null
          ? {'timestampValue': subtask.completedAt!.toUtc().toIso8601String()}
          : {'nullValue': null},
    };
  }

  // Helper method to convert Firestore fields to SubtaskEntity
  SubtaskEntity _fromFirestoreFields(Map<String, dynamic> fields) {
    return SubtaskEntity(
      id: fields['id']['stringValue'] as String,
      todoId: fields['todoId']['stringValue'] as String,
      title: fields['title']['stringValue'] as String,
      isCompleted: fields['isCompleted']['booleanValue'] as bool? ?? false,
      order: int.parse(fields['order']['integerValue'].toString()),
      createdAt: DateTime.parse(fields['createdAt']['timestampValue'] as String),
      completedAt: fields['completedAt']['timestampValue'] != null
          ? DateTime.parse(fields['completedAt']['timestampValue'] as String)
          : null,
    );
  }
}
