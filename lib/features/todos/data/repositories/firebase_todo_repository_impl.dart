import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/todo_entity.dart';
import '../../domain/repositories/todo_repository.dart';
import '../models/todo_model.dart';
import '../../../../shared/utils/retry_helper.dart';

/// Firebase/Firestore implementation of TodoRepository
class FirebaseTodoRepositoryImpl implements TodoRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirebaseTodoRepositoryImpl(this._firestore, this._auth);

  String get _userId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.uid;
  }

  CollectionReference get _todosCollection => _firestore.collection('todos');

  @override
  Future<List<TodoEntity>> getAllTodos() async {
    try {
      print('🔵 [FIRESTORE] Fetching todos for user: $_userId');
      final snapshot = await _todosCollection
          .where('user_id', isEqualTo: _userId)
          .get();

      // Sort in-memory instead of requiring a Firestore index
      final todos = snapshot.docs
          .map((doc) => _todoFromFirestore(doc))
          .toList();

      // Sort by date descending (most recent first)
      todos.sort((a, b) => b.todoDate.compareTo(a.todoDate));

      print('🟢 [FIRESTORE] Fetched ${todos.length} todos');
      return todos;
    } catch (e) {
      print('🔴 [FIRESTORE] Error fetching todos: $e');
      throw Exception('Failed to get todos: $e');
    }
  }

  @override
  Future<List<TodoEntity>> getTodosByDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _todosCollection
          .where('user_id', isEqualTo: _userId)
          .where('todo_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('todo_date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('todo_date')
          .get();

      return snapshot.docs
          .map((doc) => _todoFromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get todos by date: $e');
    }
  }

  @override
  Future<List<TodoEntity>> getTodosByDateRange(DateTime start, DateTime end) async {
    try {
      final startOfDay = DateTime(start.year, start.month, start.day);
      final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);

      final snapshot = await _todosCollection
          .where('user_id', isEqualTo: _userId)
          .where('todo_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('todo_date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('todo_date')
          .get();

      return snapshot.docs
          .map((doc) => _todoFromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get todos by date range: $e');
    }
  }

  @override
  Future<TodoEntity?> getTodoById(String id) async {
    try {
      final doc = await _todosCollection.doc(id).get();

      if (!doc.exists) return null;

      return _todoFromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get todo: $e');
    }
  }

  @override
  Future<TodoEntity> createTodo(TodoEntity todo) async {
    return RetryHelper.retry(
      operation: () async {
        try {
          final docRef = _todosCollection.doc(todo.id);

          print('🔵 [FIRESTORE] Saving todo with date: ${todo.todoDate}');

          final data = {
            'user_id': _userId,
            'title': todo.title,
            'description': todo.description,
            'todo_date': Timestamp.fromDate(todo.todoDate),
            'todo_time': todo.todoTime != null
                ? Timestamp.fromDate(todo.todoTime!)
                : null,
            'priority': todo.priority,
            'type': todo.type,
            'status': todo.status,
            'location': todo.location,
            'location_lat': todo.locationLat,
            'location_lng': todo.locationLng,
            'notification_enabled': todo.notificationEnabled,
            'notification_minutes_before': todo.notificationMinutesBefore,
            'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
            // Phase 2: Smart Planning fields
            'travel_time_minutes': todo.travelTimeMinutes,
            'geofence_radius_meters': todo.geofenceRadiusMeters,
            'weather_dependent': todo.weatherDependent,
            'traffic_aware': todo.trafficAware,
            'preparation_time_minutes': todo.preparationTimeMinutes,
            'last_traffic_check': todo.lastTrafficCheck != null
                ? Timestamp.fromDate(todo.lastTrafficCheck!)
                : null,
            'last_weather_check': todo.lastWeatherCheck != null
                ? Timestamp.fromDate(todo.lastWeatherCheck!)
                : null,
            'estimated_departure_time': todo.estimatedDepartureTime != null
                ? Timestamp.fromDate(todo.estimatedDepartureTime!)
                : null,
            // Recurrence fields
            'is_recurring': todo.isRecurring,
            'recurrence_pattern': todo.recurrencePattern,
            'recurrence_interval': todo.recurrenceInterval,
            'recurrence_weekdays': todo.recurrenceWeekdays,
            'recurrence_end_date': todo.recurrenceEndDate != null
                ? Timestamp.fromDate(todo.recurrenceEndDate!)
                : null,
            'recurrence_parent_id': todo.recurrenceParentId,
            'is_recurrence_instance': todo.isRecurrenceInstance,
          };

          await docRef.set(data);

          final doc = await docRef.get();
          return _todoFromFirestore(doc);
        } catch (e) {
          throw Exception('Failed to create todo: $e');
        }
      },
      shouldRetry: RetryHelper.isRetryableError,
    );
  }

  @override
  Future<List<TodoEntity>> createTodosBatch(List<TodoEntity> todos) async {
    if (todos.isEmpty) return [];

    try {
      print('🔵 [FIRESTORE] Batch creating ${todos.length} todos');

      // Firestore batch write (up to 500 operations per batch)
      final batch = _firestore.batch();
      final createdTodos = <TodoEntity>[];

      for (final todo in todos) {
        final docRef = _todosCollection.doc(todo.id);

        final data = {
          'user_id': _userId,
          'title': todo.title,
          'description': todo.description,
          'todo_date': Timestamp.fromDate(todo.todoDate),
          'todo_time': todo.todoTime != null
              ? Timestamp.fromDate(todo.todoTime!)
              : null,
          'priority': todo.priority,
          'type': todo.type,
          'status': todo.status,
          'location': todo.location,
          'location_lat': todo.locationLat,
          'location_lng': todo.locationLng,
          'notification_enabled': todo.notificationEnabled,
          'notification_minutes_before': todo.notificationMinutesBefore,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
          // Phase 2: Smart Planning fields
          'travel_time_minutes': todo.travelTimeMinutes,
          'geofence_radius_meters': todo.geofenceRadiusMeters,
          'weather_dependent': todo.weatherDependent,
          'traffic_aware': todo.trafficAware,
          'preparation_time_minutes': todo.preparationTimeMinutes,
          'last_traffic_check': todo.lastTrafficCheck != null
              ? Timestamp.fromDate(todo.lastTrafficCheck!)
              : null,
          'last_weather_check': todo.lastWeatherCheck != null
              ? Timestamp.fromDate(todo.lastWeatherCheck!)
              : null,
          'estimated_departure_time': todo.estimatedDepartureTime != null
              ? Timestamp.fromDate(todo.estimatedDepartureTime!)
              : null,
          // Recurrence fields
          'is_recurring': todo.isRecurring,
          'recurrence_pattern': todo.recurrencePattern,
          'recurrence_interval': todo.recurrenceInterval,
          'recurrence_weekdays': todo.recurrenceWeekdays,
          'recurrence_end_date': todo.recurrenceEndDate != null
              ? Timestamp.fromDate(todo.recurrenceEndDate!)
              : null,
          'recurrence_parent_id': todo.recurrenceParentId,
          'is_recurrence_instance': todo.isRecurrenceInstance,
        };

        batch.set(docRef, data);

        // Add to result list with current timestamp (server timestamp will be different)
        createdTodos.add(todo.copyWith(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      // Commit all writes in a single batch
      await batch.commit();

      print('🟢 [FIRESTORE] Batch created ${createdTodos.length} todos');
      return createdTodos;
    } catch (e) {
      print('🔴 [FIRESTORE] Batch create error: $e');
      throw Exception('Failed to batch create todos: $e');
    }
  }

  @override
  Future<TodoEntity> updateTodo(TodoEntity todo) async {
    return RetryHelper.retry(
      operation: () async {
        try {
          final data = {
            'title': todo.title,
            'description': todo.description,
            'todo_date': Timestamp.fromDate(todo.todoDate),
            'todo_time': todo.todoTime != null
                ? Timestamp.fromDate(todo.todoTime!)
                : null,
            'priority': todo.priority,
            'type': todo.type,
            'status': todo.status,
            'location': todo.location,
            'location_lat': todo.locationLat,
            'location_lng': todo.locationLng,
            'notification_enabled': todo.notificationEnabled,
            'notification_minutes_before': todo.notificationMinutesBefore,
            'updated_at': FieldValue.serverTimestamp(),
            // Phase 2: Smart Planning fields
            'travel_time_minutes': todo.travelTimeMinutes,
            'geofence_radius_meters': todo.geofenceRadiusMeters,
            'weather_dependent': todo.weatherDependent,
            'traffic_aware': todo.trafficAware,
            'preparation_time_minutes': todo.preparationTimeMinutes,
            'last_traffic_check': todo.lastTrafficCheck != null
                ? Timestamp.fromDate(todo.lastTrafficCheck!)
                : null,
            'last_weather_check': todo.lastWeatherCheck != null
                ? Timestamp.fromDate(todo.lastWeatherCheck!)
                : null,
            'estimated_departure_time': todo.estimatedDepartureTime != null
                ? Timestamp.fromDate(todo.estimatedDepartureTime!)
                : null,
            // Recurrence fields
            'is_recurring': todo.isRecurring,
            'recurrence_pattern': todo.recurrencePattern,
            'recurrence_interval': todo.recurrenceInterval,
            'recurrence_weekdays': todo.recurrenceWeekdays,
            'recurrence_end_date': todo.recurrenceEndDate != null
                ? Timestamp.fromDate(todo.recurrenceEndDate!)
                : null,
            'recurrence_parent_id': todo.recurrenceParentId,
            'is_recurrence_instance': todo.isRecurrenceInstance,
          };

          await _todosCollection.doc(todo.id).update(data);

          final doc = await _todosCollection.doc(todo.id).get();
          return _todoFromFirestore(doc);
        } catch (e) {
          throw Exception('Failed to update todo: $e');
        }
      },
      shouldRetry: RetryHelper.isRetryableError,
    );
  }

  @override
  Future<void> deleteTodo(String id) async {
    return RetryHelper.retry(
      operation: () async {
        try {
          await _todosCollection.doc(id).delete();
        } catch (e) {
          throw Exception('Failed to delete todo: $e');
        }
      },
      shouldRetry: RetryHelper.isRetryableError,
    );
  }

  @override
  Future<TodoEntity> toggleTodoStatus(String id) async {
    return RetryHelper.retry(
      operation: () async {
        try {
          final doc = await _todosCollection.doc(id).get();
          if (!doc.exists) {
            throw Exception('Todo not found');
          }

          final todo = _todoFromFirestore(doc);
          final newStatus = todo.status == 'completed' ? 'pending' : 'completed';

          await _todosCollection.doc(id).update({
            'status': newStatus,
            'updated_at': FieldValue.serverTimestamp(),
          });

          final updatedDoc = await _todosCollection.doc(id).get();
          return _todoFromFirestore(updatedDoc);
        } catch (e) {
          throw Exception('Failed to toggle todo status: $e');
        }
      },
      shouldRetry: RetryHelper.isRetryableError,
    );
  }

  @override
  Future<List<TodoEntity>> getTodosByStatus(String status) async {
    try {
      final snapshot = await _todosCollection
          .where('user_id', isEqualTo: _userId)
          .where('status', isEqualTo: status)
          .get();

      final todos = snapshot.docs
          .map((doc) => _todoFromFirestore(doc))
          .toList();

      // Sort in-memory
      todos.sort((a, b) => b.todoDate.compareTo(a.todoDate));
      return todos;
    } catch (e) {
      throw Exception('Failed to get todos by status: $e');
    }
  }

  @override
  Future<List<TodoEntity>> getTodosByType(String type) async {
    try {
      final snapshot = await _todosCollection
          .where('user_id', isEqualTo: _userId)
          .where('type', isEqualTo: type)
          .get();

      final todos = snapshot.docs
          .map((doc) => _todoFromFirestore(doc))
          .toList();

      // Sort in-memory
      todos.sort((a, b) => b.todoDate.compareTo(a.todoDate));
      return todos;
    } catch (e) {
      throw Exception('Failed to get todos by type: $e');
    }
  }

  @override
  Stream<List<TodoEntity>> watchTodos() {
    try {
      return _todosCollection
          .where('user_id', isEqualTo: _userId)
          .snapshots()
          .handleError((error) {
            print('🔴 [FIRESTORE] Stream error: $error');
            // Return empty list on error to prevent stream from breaking
            return <DocumentSnapshot>[];
          })
          .map((snapshot) {
        final todos = snapshot.docs
            .map((doc) => _todoFromFirestore(doc))
            .toList();

        // Sort in-memory
        todos.sort((a, b) => b.todoDate.compareTo(a.todoDate));
        return todos;
      });
    } catch (e) {
      print('🔴 [FIRESTORE] Error creating stream: $e');
      // Return a stream with empty list if there's an error
      return Stream.value([]);
    }
  }

  @override
  Future<List<TodoEntity>> searchTodos(String query) async {
    try {
      final snapshot = await _todosCollection
          .where('user_id', isEqualTo: _userId)
          .get();

      // Client-side filtering for search
      final todos = snapshot.docs
          .map((doc) => _todoFromFirestore(doc))
          .where((todo) =>
              todo.title.toLowerCase().contains(query.toLowerCase()) ||
              (todo.description?.toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();

      return todos;
    } catch (e) {
      throw Exception('Failed to search todos: $e');
    }
  }

  /// Helper method to convert Firestore document to TodoEntity
  TodoEntity _todoFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final rawDate = (data['todo_date'] as Timestamp).toDate();
    print('🔵 [FIRESTORE] Retrieved todo date from Firestore: $rawDate');

    return TodoEntity(
      id: doc.id,
      userId: data['user_id'] as String,
      title: data['title'] as String,
      description: data['description'] as String?,
      todoDate: rawDate,
      todoTime: data['todo_time'] != null
          ? (data['todo_time'] as Timestamp).toDate()
          : null,
      priority: data['priority'] as int? ?? 3,
      type: data['type'] as String? ?? 'other',
      status: data['status'] as String? ?? 'pending',
      location: data['location'] as String?,
      locationLat: data['location_lat'] as double?,
      locationLng: data['location_lng'] as double?,
      notificationEnabled: data['notification_enabled'] as bool? ?? true,
      notificationMinutesBefore: data['notification_minutes_before'] as int? ?? 30,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      // Phase 2: Smart Planning fields
      travelTimeMinutes: data['travel_time_minutes'] as int? ?? 0,
      geofenceRadiusMeters: data['geofence_radius_meters'] as int? ?? 500,
      weatherDependent: data['weather_dependent'] as bool? ?? false,
      trafficAware: data['traffic_aware'] as bool? ?? true,
      preparationTimeMinutes: data['preparation_time_minutes'] as int? ?? 15,
      lastTrafficCheck: data['last_traffic_check'] != null
          ? (data['last_traffic_check'] as Timestamp).toDate()
          : null,
      lastWeatherCheck: data['last_weather_check'] != null
          ? (data['last_weather_check'] as Timestamp).toDate()
          : null,
      estimatedDepartureTime: data['estimated_departure_time'] != null
          ? (data['estimated_departure_time'] as Timestamp).toDate()
          : null,
      // Recurrence fields
      isRecurring: data['is_recurring'] as bool? ?? false,
      recurrencePattern: data['recurrence_pattern'] as String?,
      recurrenceInterval: data['recurrence_interval'] as int?,
      recurrenceWeekdays: (data['recurrence_weekdays'] as List?)?.cast<int>(),
      recurrenceEndDate: data['recurrence_end_date'] != null
          ? (data['recurrence_end_date'] as Timestamp).toDate()
          : null,
      recurrenceParentId: data['recurrence_parent_id'] as String?,
      isRecurrenceInstance: data['is_recurrence_instance'] as bool? ?? false,
    );
  }
}
