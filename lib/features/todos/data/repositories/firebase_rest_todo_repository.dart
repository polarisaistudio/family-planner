import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/todo_entity.dart';

/// Firestore REST API for todos (no gRPC dependencies)
/// Works on iOS with Xcode 16+
class FirebaseRestTodoRepository {
  static const String _projectId = 'family-planner-86edd';
  static const String _baseUrl = 'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents';

  final String Function() _getIdToken;
  final String Function() _getUserId;

  FirebaseRestTodoRepository({
    required String Function() getIdToken,
    required String Function() getUserId,
  })  : _getIdToken = getIdToken,
        _getUserId = getUserId;

  /// Fetch all todos for current user
  Future<List<TodoEntity>> getTodos() async {
    try {
      final userId = _getUserId();
      print('🔵 [REST FIRESTORE] Fetching todos for user: $userId');

      // Use Firestore REST API to query todos
      final url = Uri.parse(
        '$_baseUrl:runQuery',
      );

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${_getIdToken()}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'structuredQuery': {
            'from': [{'collectionId': 'todos'}],
            'where': {
              'fieldFilter': {
                'field': {'fieldPath': 'userId'},
                'op': 'EQUAL',
                'value': {'stringValue': userId}
              }
            }
          }
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        final List<TodoEntity> todos = [];

        for (final result in results) {
          if (result['document'] != null) {
            final doc = result['document'];
            final fields = doc['fields'];
            final todoId = doc['name'].toString().split('/').last;

            todos.add(_todoFromFields(todoId, fields));
          }
        }

        print('🟢 [REST FIRESTORE] Fetched ${todos.length} todos');
        return todos;
      } else {
        print('🔴 [REST FIRESTORE] Error: ${response.statusCode}');
        throw Exception('Failed to fetch todos: ${response.statusCode}');
      }
    } catch (e) {
      print('🔴 [REST FIRESTORE] Exception: $e');
      rethrow;
    }
  }

  /// Create a new todo
  Future<TodoEntity> createTodo(TodoEntity todo) async {
    try {
      print('🔵 [REST FIRESTORE] Creating todo: ${todo.title}');

      final url = Uri.parse('$_baseUrl/todos/${todo.id}');
      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer ${_getIdToken()}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'fields': _todoToFields(todo),
        }),
      );

      if (response.statusCode == 200) {
        print('🟢 [REST FIRESTORE] Todo created: ${todo.title}');
        return todo;
      } else {
        print('🔴 [REST FIRESTORE] Error: ${response.statusCode}');
        throw Exception('Failed to create todo: ${response.statusCode}');
      }
    } catch (e) {
      print('🔴 [REST FIRESTORE] Exception: $e');
      rethrow;
    }
  }

  /// Batch create todos (for recurring events)
  Future<List<TodoEntity>> createTodosBatch(List<TodoEntity> todos) async {
    try {
      if (todos.isEmpty) return [];

      print('🔵 [REST FIRESTORE] Batch creating ${todos.length} todos');

      // Firestore REST API commit (batch write)
      final url = Uri.parse('$_baseUrl:commit');

      final writes = todos.map((todo) {
        return {
          'update': {
            'name': 'projects/$_projectId/databases/(default)/documents/todos/${todo.id}',
            'fields': _todoToFields(todo),
          },
          'updateMask': {
            'fieldPaths': _todoToFields(todo).keys.toList()
          }
        };
      }).toList();

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${_getIdToken()}',
          'Content-Type': 'application/json',
        },
        body: json.encode({'writes': writes}),
      );

      if (response.statusCode == 200) {
        print('🟢 [REST FIRESTORE] Batch created ${todos.length} todos');
        return todos;
      } else {
        print('🔴 [REST FIRESTORE] Error: ${response.statusCode}');
        print('🔴 [REST FIRESTORE] Response body: ${response.body}');
        throw Exception('Failed to batch create todos: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('🔴 [REST FIRESTORE] Exception: $e');
      rethrow;
    }
  }

  /// Update an existing todo
  Future<TodoEntity> updateTodo(TodoEntity todo) async {
    try {
      print('🔵 [REST FIRESTORE] Updating todo: ${todo.title}');

      final url = Uri.parse('$_baseUrl/todos/${todo.id}');
      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer ${_getIdToken()}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'fields': _todoToFields(todo),
        }),
      );

      if (response.statusCode == 200) {
        print('🟢 [REST FIRESTORE] Todo updated: ${todo.title}');
        return todo;
      } else {
        print('🔴 [REST FIRESTORE] Error: ${response.statusCode}');
        throw Exception('Failed to update todo: ${response.statusCode}');
      }
    } catch (e) {
      print('🔴 [REST FIRESTORE] Exception: $e');
      rethrow;
    }
  }

  /// Delete a todo
  Future<void> deleteTodo(String todoId) async {
    try {
      print('🔵 [REST FIRESTORE] Deleting todo: $todoId');

      final url = Uri.parse('$_baseUrl/todos/$todoId');
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer ${_getIdToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('🟢 [REST FIRESTORE] Todo deleted: $todoId');
      } else {
        print('🔴 [REST FIRESTORE] Error: ${response.statusCode}');
        throw Exception('Failed to delete todo: ${response.statusCode}');
      }
    } catch (e) {
      print('🔴 [REST FIRESTORE] Exception: $e');
      rethrow;
    }
  }

  /// Get todos by specific date
  Future<List<TodoEntity>> getTodosByDate(DateTime date) async {
    try {
      final userId = _getUserId();
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      print('🔵 [REST FIRESTORE] Fetching todos for date: $date');

      final url = Uri.parse('$_baseUrl:runQuery');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${_getIdToken()}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'structuredQuery': {
            'from': [{'collectionId': 'todos'}],
            'where': {
              'compositeFilter': {
                'op': 'AND',
                'filters': [
                  {
                    'fieldFilter': {
                      'field': {'fieldPath': 'userId'},
                      'op': 'EQUAL',
                      'value': {'stringValue': userId}
                    }
                  },
                  {
                    'fieldFilter': {
                      'field': {'fieldPath': 'todoDate'},
                      'op': 'GREATER_THAN_OR_EQUAL',
                      'value': {'timestampValue': _formatTimestamp(startOfDay)}
                    }
                  },
                  {
                    'fieldFilter': {
                      'field': {'fieldPath': 'todoDate'},
                      'op': 'LESS_THAN_OR_EQUAL',
                      'value': {'timestampValue': _formatTimestamp(endOfDay)}
                    }
                  }
                ]
              }
            },
            'orderBy': [
              {'field': {'fieldPath': 'todoDate'}, 'direction': 'ASCENDING'}
            ]
          }
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        final List<TodoEntity> todos = [];

        for (final result in results) {
          if (result['document'] != null) {
            final doc = result['document'];
            final fields = doc['fields'];
            final todoId = doc['name'].toString().split('/').last;
            todos.add(_todoFromFields(todoId, fields));
          }
        }

        print('🟢 [REST FIRESTORE] Fetched ${todos.length} todos for date');
        return todos;
      } else {
        print('🔴 [REST FIRESTORE] Error: ${response.statusCode}');
        throw Exception('Failed to fetch todos by date: ${response.statusCode}');
      }
    } catch (e) {
      print('🔴 [REST FIRESTORE] Exception: $e');
      rethrow;
    }
  }

  /// Get todos by date range
  Future<List<TodoEntity>> getTodosByDateRange(DateTime start, DateTime end) async {
    try {
      final userId = _getUserId();
      final startOfDay = DateTime(start.year, start.month, start.day);
      final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);

      print('🔵 [REST FIRESTORE] Fetching todos for date range: $start to $end');

      final url = Uri.parse('$_baseUrl:runQuery');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${_getIdToken()}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'structuredQuery': {
            'from': [{'collectionId': 'todos'}],
            'where': {
              'compositeFilter': {
                'op': 'AND',
                'filters': [
                  {
                    'fieldFilter': {
                      'field': {'fieldPath': 'userId'},
                      'op': 'EQUAL',
                      'value': {'stringValue': userId}
                    }
                  },
                  {
                    'fieldFilter': {
                      'field': {'fieldPath': 'todoDate'},
                      'op': 'GREATER_THAN_OR_EQUAL',
                      'value': {'timestampValue': _formatTimestamp(startOfDay)}
                    }
                  },
                  {
                    'fieldFilter': {
                      'field': {'fieldPath': 'todoDate'},
                      'op': 'LESS_THAN_OR_EQUAL',
                      'value': {'timestampValue': _formatTimestamp(endOfDay)}
                    }
                  }
                ]
              }
            },
            'orderBy': [
              {'field': {'fieldPath': 'todoDate'}, 'direction': 'ASCENDING'}
            ]
          }
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        final List<TodoEntity> todos = [];

        for (final result in results) {
          if (result['document'] != null) {
            final doc = result['document'];
            final fields = doc['fields'];
            final todoId = doc['name'].toString().split('/').last;
            todos.add(_todoFromFields(todoId, fields));
          }
        }

        print('🟢 [REST FIRESTORE] Fetched ${todos.length} todos for date range');
        return todos;
      } else {
        print('🔴 [REST FIRESTORE] Error: ${response.statusCode}');
        throw Exception('Failed to fetch todos by date range: ${response.statusCode}');
      }
    } catch (e) {
      print('🔴 [REST FIRESTORE] Exception: $e');
      rethrow;
    }
  }

  /// Get a single todo by ID
  Future<TodoEntity?> getTodoById(String id) async {
    try {
      print('🔵 [REST FIRESTORE] Fetching todo: $id');

      final url = Uri.parse('$_baseUrl/todos/$id');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${_getIdToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final doc = json.decode(response.body);
        final fields = doc['fields'];
        final todoId = doc['name'].toString().split('/').last;

        print('🟢 [REST FIRESTORE] Todo fetched: $id');
        return _todoFromFields(todoId, fields);
      } else if (response.statusCode == 404) {
        print('🟡 [REST FIRESTORE] Todo not found: $id');
        return null;
      } else {
        print('🔴 [REST FIRESTORE] Error: ${response.statusCode}');
        throw Exception('Failed to fetch todo: ${response.statusCode}');
      }
    } catch (e) {
      print('🔴 [REST FIRESTORE] Exception: $e');
      rethrow;
    }
  }

  /// Toggle todo completion status
  Future<TodoEntity> toggleTodoStatus(String id) async {
    try {
      print('🔵 [REST FIRESTORE] Toggling todo status: $id');

      // First, get the current todo
      final todo = await getTodoById(id);
      if (todo == null) {
        throw Exception('Todo not found: $id');
      }

      // Toggle the status
      final newStatus = todo.status == 'completed' ? 'pending' : 'completed';
      final updatedTodo = todo.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );

      // Update the todo
      return await updateTodo(updatedTodo);
    } catch (e) {
      print('🔴 [REST FIRESTORE] Exception: $e');
      rethrow;
    }
  }

  /// Convert TodoEntity to Firestore fields format
  Map<String, dynamic> _todoToFields(TodoEntity todo) {
    return {
      'userId': {'stringValue': todo.userId},
      'title': {'stringValue': todo.title},
      'description': {'stringValue': todo.description ?? ''},
      'todoDate': {'timestampValue': _formatTimestamp(todo.todoDate)},
      'todoTime': todo.todoTime != null
          ? {'timestampValue': _formatTimestamp(todo.todoTime!)}
          : {'nullValue': null},
      'priority': {'integerValue': todo.priority.toString()},
      'type': {'stringValue': todo.type},
      'status': {'stringValue': todo.status},
      'location': {'stringValue': todo.location ?? ''},
      'locationLat': todo.locationLat != null
          ? {'doubleValue': todo.locationLat}
          : {'nullValue': null},
      'locationLng': todo.locationLng != null
          ? {'doubleValue': todo.locationLng}
          : {'nullValue': null},
      'notificationEnabled': {'booleanValue': todo.notificationEnabled},
      'notificationMinutesBefore': {'integerValue': todo.notificationMinutesBefore.toString()},
      'createdAt': {'timestampValue': _formatTimestamp(todo.createdAt)},
      'updatedAt': {'timestampValue': _formatTimestamp(todo.updatedAt)},
      // Smart planning fields
      'travelTimeMinutes': {'integerValue': todo.travelTimeMinutes.toString()},
      'geofenceRadiusMeters': {'integerValue': todo.geofenceRadiusMeters.toString()},
      'weatherDependent': {'booleanValue': todo.weatherDependent},
      'trafficAware': {'booleanValue': todo.trafficAware},
      'preparationTimeMinutes': {'integerValue': todo.preparationTimeMinutes.toString()},
      'lastTrafficCheck': todo.lastTrafficCheck != null
          ? {'timestampValue': _formatTimestamp(todo.lastTrafficCheck!)}
          : {'nullValue': null},
      'lastWeatherCheck': todo.lastWeatherCheck != null
          ? {'timestampValue': _formatTimestamp(todo.lastWeatherCheck!)}
          : {'nullValue': null},
      'estimatedDepartureTime': todo.estimatedDepartureTime != null
          ? {'timestampValue': _formatTimestamp(todo.estimatedDepartureTime!)}
          : {'nullValue': null},
      // Recurrence fields
      'isRecurring': {'booleanValue': todo.isRecurring},
      'recurrencePattern': {'stringValue': todo.recurrencePattern ?? ''},
      'recurrenceInterval': todo.recurrenceInterval != null
          ? {'integerValue': todo.recurrenceInterval.toString()}
          : {'nullValue': null},
      'recurrenceWeekdays': todo.recurrenceWeekdays != null
          ? {'arrayValue': {'values': todo.recurrenceWeekdays!.map((day) => {'integerValue': day.toString()}).toList()}}
          : {'nullValue': null},
      'recurrenceEndDate': todo.recurrenceEndDate != null
          ? {'timestampValue': _formatTimestamp(todo.recurrenceEndDate!)}
          : {'nullValue': null},
      'recurrenceParentId': {'stringValue': todo.recurrenceParentId ?? ''},
      'isRecurrenceInstance': {'booleanValue': todo.isRecurrenceInstance},
      // Phase 4: Enhanced Task Management fields
      'category': {'stringValue': todo.category ?? ''},
      'tags': todo.tags != null && todo.tags!.isNotEmpty
          ? {'arrayValue': {'values': todo.tags!.map((tag) => {'stringValue': tag}).toList()}}
          : {'nullValue': null},
      'subtaskIds': todo.subtaskIds != null && todo.subtaskIds!.isNotEmpty
          ? {'arrayValue': {'values': todo.subtaskIds!.map((id) => {'stringValue': id}).toList()}}
          : {'nullValue': null},
      'subtasksTotal': {'integerValue': todo.subtasksTotal.toString()},
      'subtasksCompleted': {'integerValue': todo.subtasksCompleted.toString()},
      'templateId': {'stringValue': todo.templateId ?? ''},
      'priorityAutoAdjusted': {'booleanValue': todo.priorityAutoAdjusted},
      'priorityAdjustedAt': todo.priorityAdjustedAt != null
          ? {'timestampValue': _formatTimestamp(todo.priorityAdjustedAt!)}
          : {'nullValue': null},
    };
  }

  /// Format DateTime to Firestore-compatible timestamp (must end with 'Z')
  String _formatTimestamp(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String();
  }

  /// Convert Firestore fields to TodoEntity
  TodoEntity _todoFromFields(String id, Map<String, dynamic> fields) {
    return TodoEntity(
      id: id,
      userId: _getStringValue(fields['userId']),
      title: _getStringValue(fields['title']),
      description: _getStringValue(fields['description']),
      todoDate: _getDateTimeValue(fields['todoDate']),
      todoTime: _getNullableDateTimeValue(fields['todoTime']),
      priority: _getIntValue(fields['priority'], 3),
      type: _getStringValue(fields['type']),
      status: _getStringValue(fields['status']),
      location: _getStringValue(fields['location']),
      locationLat: _getNullableDoubleValue(fields['locationLat']),
      locationLng: _getNullableDoubleValue(fields['locationLng']),
      notificationEnabled: _getBoolValue(fields['notificationEnabled'], true),
      notificationMinutesBefore: _getIntValue(fields['notificationMinutesBefore'], 30),
      createdAt: _getDateTimeValue(fields['createdAt']),
      updatedAt: _getDateTimeValue(fields['updatedAt']),
      // Smart planning fields
      travelTimeMinutes: _getIntValue(fields['travelTimeMinutes'], 0),
      geofenceRadiusMeters: _getIntValue(fields['geofenceRadiusMeters'], 500),
      weatherDependent: _getBoolValue(fields['weatherDependent'], false),
      trafficAware: _getBoolValue(fields['trafficAware'], true),
      preparationTimeMinutes: _getIntValue(fields['preparationTimeMinutes'], 15),
      lastTrafficCheck: _getNullableDateTimeValue(fields['lastTrafficCheck']),
      lastWeatherCheck: _getNullableDateTimeValue(fields['lastWeatherCheck']),
      estimatedDepartureTime: _getNullableDateTimeValue(fields['estimatedDepartureTime']),
      // Recurrence fields
      isRecurring: _getBoolValue(fields['isRecurring'], false),
      recurrencePattern: _getStringValue(fields['recurrencePattern']),
      recurrenceInterval: _getNullableIntValue(fields['recurrenceInterval']),
      recurrenceWeekdays: _getIntListValue(fields['recurrenceWeekdays']),
      recurrenceEndDate: _getNullableDateTimeValue(fields['recurrenceEndDate']),
      recurrenceParentId: _getStringValue(fields['recurrenceParentId']),
      isRecurrenceInstance: _getBoolValue(fields['isRecurrenceInstance'], false),
      // Phase 4: Enhanced Task Management fields
      category: _getNullableStringValue(fields['category']),
      tags: _getStringListValue(fields['tags']),
      subtaskIds: _getStringListValue(fields['subtaskIds']),
      subtasksTotal: _getIntValue(fields['subtasksTotal'], 0),
      subtasksCompleted: _getIntValue(fields['subtasksCompleted'], 0),
      templateId: _getNullableStringValue(fields['templateId']),
      priorityAutoAdjusted: _getBoolValue(fields['priorityAutoAdjusted'], false),
      priorityAdjustedAt: _getNullableDateTimeValue(fields['priorityAdjustedAt']),
    );
  }

  // Helper methods to extract Firestore values
  String _getStringValue(dynamic field) {
    if (field == null) return '';
    return field['stringValue'] ?? '';
  }

  int _getIntValue(dynamic field, int defaultValue) {
    if (field == null) return defaultValue;
    final value = field['integerValue'];
    if (value == null) return defaultValue;
    return int.tryParse(value.toString()) ?? defaultValue;
  }

  int? _getNullableIntValue(dynamic field) {
    if (field == null || field['nullValue'] != null) return null;
    final value = field['integerValue'];
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  double? _getNullableDoubleValue(dynamic field) {
    if (field == null || field['nullValue'] != null) return null;
    return field['doubleValue'];
  }

  bool _getBoolValue(dynamic field, bool defaultValue) {
    if (field == null) return defaultValue;
    return field['booleanValue'] ?? defaultValue;
  }

  DateTime _getDateTimeValue(dynamic field) {
    if (field == null) return DateTime.now();
    final timestamp = field['timestampValue'];
    if (timestamp == null) return DateTime.now();
    return DateTime.parse(timestamp);
  }

  DateTime? _getNullableDateTimeValue(dynamic field) {
    if (field == null || field['nullValue'] != null) return null;
    final timestamp = field['timestampValue'];
    if (timestamp == null) return null;
    return DateTime.parse(timestamp);
  }

  List<int>? _getIntListValue(dynamic field) {
    if (field == null || field['nullValue'] != null) return null;
    final arrayValue = field['arrayValue'];
    if (arrayValue == null) return null;
    final values = arrayValue['values'] as List?;
    if (values == null) return null;
    return values.map((v) => int.tryParse(v['integerValue'].toString()) ?? 0).toList();
  }

  String? _getNullableStringValue(dynamic field) {
    if (field == null || field['nullValue'] != null) return null;
    final value = field['stringValue'];
    if (value == null || value.toString().isEmpty) return null;
    return value.toString();
  }

  List<String>? _getStringListValue(dynamic field) {
    if (field == null || field['nullValue'] != null) return null;
    final arrayValue = field['arrayValue'];
    if (arrayValue == null) return null;
    final values = arrayValue['values'] as List?;
    if (values == null || values.isEmpty) return null;
    return values
        .where((v) => v != null && v['stringValue'] != null)
        .map((v) => v['stringValue'].toString())
        .toList();
  }
}
