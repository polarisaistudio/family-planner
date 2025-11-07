import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_constants.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../todos/domain/entities/todo_entity.dart';
import '../../../todos/domain/entities/subtask_entity.dart';
import '../../../todos/presentation/providers/todo_providers.dart';
import '../../../todos/presentation/providers/subtask_providers.dart';
import '../../../todos/services/providers/todo_notification_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../shared/utils/recurrence_helper.dart';
import '../../../family/presentation/providers/family_provider.dart';
import '../../../../core/services/providers/translation_provider.dart';
import '../../../../shared/widgets/translated_text.dart';
import 'category_picker_widget.dart';
import 'tag_input_widget.dart';
import 'subtask_list_widget.dart';

class AddTodoDialog extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  final TodoEntity? todoToEdit;
  final DateTime? suggestedReminderTime;

  const AddTodoDialog({
    super.key,
    required this.selectedDate,
    this.todoToEdit,
    this.suggestedReminderTime,
  });

  @override
  ConsumerState<AddTodoDialog> createState() => _AddTodoDialogState();
}

class _AddTodoDialogState extends ConsumerState<AddTodoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _locationFocusNode = FocusNode();

  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;
  int _priority = AppConstants.priorityMedium;
  String _type = AppConstants.todoTypePersonal;
  bool _isLoading = false;
  String? _location;
  double? _locationLat;
  double? _locationLng;

  // Location search state
  Timer? _debounceTimer;
  List<Location> _locationSuggestions = [];
  List<String> _placeNames = [];
  bool _isSearchingLocations = false;
  bool _showLocationDropdown = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  // Recurrence fields
  bool _isRecurring = false;
  String _recurrencePattern = 'daily';
  int _recurrenceInterval = 1;
  List<int> _selectedWeekdays = [];
  DateTime? _recurrenceEndDate;

  // Family collaboration fields
  String? _assignedToId;
  String? _assignedToName;
  List<String> _sharedWith = [];

  // Phase 4: Enhanced Task Management fields
  String? _category;
  List<String> _tags = [];
  List<SubtaskEntity> _subtasks = [];
  final TextEditingController _subtaskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;

    // If editing, populate fields
    if (widget.todoToEdit != null) {
      final todo = widget.todoToEdit!;
      _titleController.text = todo.title;
      _descriptionController.text = todo.description ?? '';
      _locationController.text = todo.location ?? '';
      _selectedDate = todo.todoDate;
      if (todo.todoTime != null) {
        _selectedTime = TimeOfDay(
          hour: todo.todoTime!.hour,
          minute: todo.todoTime!.minute,
        );
      }
      _priority = todo.priority;
      _type = todo.type;
      _location = todo.location;
      _locationLat = todo.locationLat;
      _locationLng = todo.locationLng;
      _isRecurring = todo.isRecurring;
      _recurrencePattern = todo.recurrencePattern ?? 'daily';
      _recurrenceInterval = todo.recurrenceInterval ?? 1;
      _selectedWeekdays = todo.recurrenceWeekdays ?? [];
      _recurrenceEndDate = todo.recurrenceEndDate;
      _assignedToId = todo.assignedToId;
      _assignedToName = todo.assignedToName;
      _sharedWith = todo.sharedWith ?? [];
      _category = todo.category;
      _tags = todo.tags ?? [];
    }

    // Load family members and subtasks when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = ref.read(currentUserProvider).value;
      if (user != null) {
        ref.read(familyMembersProvider.notifier).loadFamilyMembers(user.id);
      }

      // Load subtasks if editing an existing todo
      if (widget.todoToEdit != null) {
        print('🔵 [ADD TODO] Loading subtasks for todo: ${widget.todoToEdit!.id}');
        print('🔵 [ADD TODO] Todo hasSubtasks: ${widget.todoToEdit!.hasSubtasks}, subtasksTotal: ${widget.todoToEdit!.subtasksTotal}');

        try {
          // Always try to load subtasks, even if hasSubtasks is false
          // This handles the case where subtasks were just created but the todo hasn't been refreshed yet
          await ref.read(subtasksProvider.notifier).loadSubtasksForTodo(widget.todoToEdit!.id);
          final loadedSubtasks = ref.read(subtasksProvider.notifier).getSubtasksForTodo(widget.todoToEdit!.id);
          print('🔵 [ADD TODO] Loaded ${loadedSubtasks.length} subtasks');
          setState(() {
            _subtasks = loadedSubtasks;
          });
        } catch (e) {
          // Handle error silently or show a message
          print('❌ [ADD TODO] Failed to load subtasks: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _locationFocusNode.dispose();
    _subtaskController.dispose();
    _debounceTimer?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _showLocationDropdown = false;
  }

  Future<void> _searchLocations(String query) async {
    if (query.trim().length < 3) {
      _removeOverlay();
      setState(() {
        _locationSuggestions = [];
        _placeNames = [];
        _isSearchingLocations = false;
      });
      return;
    }

    setState(() => _isSearchingLocations = true);

    try {
      // Use Nominatim (OpenStreetMap) API for place search
      final encodedQuery = Uri.encodeComponent(query);
      final url = 'https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&limit=5&addressdetails=1';

      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'FamilyPlanner/1.0'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);

        final locations = <Location>[];
        final placeNames = <String>[];

        for (var result in results) {
          final lat = double.parse(result['lat'].toString());
          final lon = double.parse(result['lon'].toString());
          final displayName = result['display_name'] as String;

          locations.add(Location(
            latitude: lat,
            longitude: lon,
            timestamp: DateTime.now(),
          ));
          placeNames.add(displayName);
        }

        setState(() {
          _locationSuggestions = locations;
          _placeNames = placeNames;
          _isSearchingLocations = false;
        });

        if (_locationSuggestions.isNotEmpty) {
          _showOverlay();
        } else {
          _removeOverlay();
        }
      } else {
        throw Exception('Failed to search locations: ${response.statusCode}');
      }
    } catch (e) {
      print('🔴 [LOCATION SEARCH] Error: $e');
      if (!mounted) return;
      setState(() {
        _locationSuggestions = [];
        _placeNames = [];
        _isSearchingLocations = false;
      });
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 300, // Match the text field width approximately
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60), // Position below the text field
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _locationSuggestions.length,
                itemBuilder: (context, index) {
                  final location = _locationSuggestions[index];
                  final placeName = index < _placeNames.length
                      ? _placeNames[index]
                      : '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';

                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.location_on, size: 20),
                    title: Text(
                      placeName,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () async {
                      await _selectLocation(location, placeName);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _showLocationDropdown = true);
  }

  Future<void> _selectLocation(Location location, String placeName) async {
    // Use the place name from Nominatim directly
    setState(() {
      _locationController.text = placeName;
      _location = placeName;
      _locationLat = location.latitude;
      _locationLng = location.longitude;
    });

    _removeOverlay();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create DateTime for time if selected (in UTC to avoid timezone conversion)
      DateTime? todoTime;
      if (_selectedTime != null) {
        todoTime = DateTime.utc(
          2000,
          1,
          1,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
      }

      // Normalize the date to midnight local time to avoid timezone issues
      final normalizedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );

      print('🔵 [ADD TODO] Selected date: $_selectedDate');
      print('🔵 [ADD TODO] Normalized date: $normalizedDate');

      final isEditing = widget.todoToEdit != null;

      final todo = TodoEntity(
        id: isEditing ? widget.todoToEdit!.id : const Uuid().v4(),
        userId: user.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        todoDate: normalizedDate,
        todoTime: todoTime,
        priority: _priority,
        type: _type,
        status: isEditing ? widget.todoToEdit!.status : AppConstants.statusPending,
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        locationLat: _locationLat,
        locationLng: _locationLng,
        createdAt: isEditing ? widget.todoToEdit!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
        isRecurring: _isRecurring,
        recurrencePattern: _isRecurring ? _recurrencePattern : null,
        recurrenceInterval: _isRecurring ? _recurrenceInterval : null,
        recurrenceWeekdays: _isRecurring && _recurrencePattern == 'weekly'
            ? _selectedWeekdays
            : null,
        recurrenceEndDate: _isRecurring ? _recurrenceEndDate : null,
        // Family collaboration fields
        assignedToId: _assignedToId,
        assignedToName: _assignedToName,
        sharedWith: _sharedWith.isEmpty ? null : _sharedWith,
        // Phase 4: Enhanced Task Management fields
        category: _category,
        tags: _tags.isEmpty ? null : _tags,
        subtaskIds: _subtasks.isEmpty ? null : _subtasks.map((s) => s.id).toList(),
        subtasksTotal: _subtasks.length,
        subtasksCompleted: _subtasks.where((s) => s.isCompleted).length,
        templateId: null,
        priorityAutoAdjusted: false,
        priorityAdjustedAt: null,
      );

      if (isEditing) {
        // Update existing todo
        await ref.read(todosProvider.notifier).updateTodo(todo);

        // Update subtasks - delete old ones and create new ones
        try {
          if (widget.todoToEdit!.hasSubtasks) {
            print('🔵 [SUBTASKS] Deleting old subtasks for todo: ${todo.id}');
            await ref.read(subtasksProvider.notifier).deleteSubtasksForTodo(todo.id);
          }
          if (_subtasks.isNotEmpty) {
            print('🔵 [SUBTASKS] Creating ${_subtasks.length} new subtasks');
            await ref.read(subtasksProvider.notifier).createSubtasks(todo.id, _subtasks);
          }
        } catch (e) {
          print('🔴 [SUBTASKS] Error updating subtasks: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.warningSubtasksUpdateFailed(e.toString())),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 10),
              ),
            );
          }
        }

        // Send notification if assignment changed
        final oldTodo = widget.todoToEdit;
        if (oldTodo!.assignedToId != todo.assignedToId && todo.assignedToId != null) {
          final notificationService = ref.read(todoNotificationServiceProvider);
          await notificationService.notifyTaskAssigned(
            todo: todo,
            assignedToId: todo.assignedToId!,
            assignedByName: user.fullName ?? 'Someone',
          );
        }
      } else if (_isRecurring) {
        // Generate recurring instances for the next 365 days
        final endDate = _recurrenceEndDate ?? normalizedDate.add(const Duration(days: 365));
        final instances = RecurrenceHelper.generateRecurringInstances(
          parentTodo: todo,
          startDate: normalizedDate,
          endDate: endDate,
        );

        print('🔵 [ADD TODO] Creating ${instances.length} recurring instances');

        // Create all instances in a single batch to avoid multiple UI re-renders
        await ref.read(todosProvider.notifier).createTodosBatch(instances);

        print('🟢 [ADD TODO] Batch creation complete');
      } else {
        await ref.read(todosProvider.notifier).createTodo(todo);

        // Create subtasks if any
        if (_subtasks.isNotEmpty) {
          try {
            print('🔵 [SUBTASKS] Creating ${_subtasks.length} subtasks for new todo: ${todo.id}');
            await ref.read(subtasksProvider.notifier).createSubtasks(todo.id, _subtasks);
            print('🟢 [SUBTASKS] Subtasks created successfully');
          } catch (e) {
            print('🔴 [SUBTASKS] Error creating subtasks: $e');
            // Don't fail the whole operation if subtasks fail
          }
        }

        // Send notification if task is assigned to someone
        if (todo.assignedToId != null) {
          final notificationService = ref.read(todoNotificationServiceProvider);
          await notificationService.notifyTaskAssigned(
            todo: todo,
            assignedToId: todo.assignedToId!,
            assignedByName: user.fullName ?? 'Someone',
          );
        }
      }

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? AppLocalizations.of(context)!.taskUpdatedSuccess : AppLocalizations.of(context)!.taskCreatedSuccess),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.failedToTask(
            widget.todoToEdit != null ? 'update' : 'create',
            e.toString()
          )),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.retry,
            textColor: Colors.white,
            onPressed: () => _handleSubmit(),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getIntervalLabel() {
    final l10n = AppLocalizations.of(context)!;
    switch (_recurrencePattern) {
      case 'daily':
        return _recurrenceInterval == 1 ? l10n.day : l10n.days;
      case 'weekly':
        return _recurrenceInterval == 1 ? l10n.week : l10n.weeks;
      case 'monthly':
        return _recurrenceInterval == 1 ? l10n.month : l10n.months;
      case 'yearly':
        return _recurrenceInterval == 1 ? l10n.year : l10n.years;
      default:
        return '';
    }
  }

  void _addSubtask() {
    final title = _subtaskController.text.trim();
    if (title.isEmpty) return;

    final subtask = SubtaskEntity(
      id: const Uuid().v4(),
      todoId: widget.todoToEdit?.id ?? '', // Will be set when saving todo
      title: title,
      isCompleted: false,
      order: _subtasks.length,
      createdAt: DateTime.now(),
    );

    setState(() {
      _subtasks.add(subtask);
      _subtaskController.clear();
    });
  }

  void _toggleSubtask(String subtaskId, bool isCompleted) {
    setState(() {
      final index = _subtasks.indexWhere((s) => s.id == subtaskId);
      if (index != -1) {
        _subtasks[index] = _subtasks[index].copyWith(
          isCompleted: isCompleted,
          completedAt: isCompleted ? DateTime.now() : null,
        );
      }
    });
  }

  void _deleteSubtask(String subtaskId) {
    setState(() {
      _subtasks.removeWhere((s) => s.id == subtaskId);
      // Reorder remaining subtasks
      for (var i = 0; i < _subtasks.length; i++) {
        _subtasks[i] = _subtasks[i].copyWith(order: i);
      }
    });
  }

  void _reorderSubtasks(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final subtask = _subtasks.removeAt(oldIndex);
      _subtasks.insert(newIndex, subtask);

      // Update order for all subtasks
      for (var i = 0; i < _subtasks.length; i++) {
        _subtasks[i] = _subtasks[i].copyWith(order: i);
      }
    });
  }

  Widget _buildWeekdayChip(String label, int weekday) {
    final isSelected = _selectedWeekdays.contains(weekday);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedWeekdays.add(weekday);
          } else {
            _selectedWeekdays.remove(weekday);
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.todoToEdit != null ? AppLocalizations.of(context)!.editTask : AppLocalizations.of(context)!.addNewTask,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),

                // Show translated title if editing
                if (widget.todoToEdit != null && _titleController.text.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.title, size: 20, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TranslatedText(
                            _titleController.text,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.title,
                    hintText: AppLocalizations.of(context)!.enterTaskTitle,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppLocalizations.of(context)!.pleaseEnterTitle;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Show translated description if editing and not empty
                if (widget.todoToEdit != null && _descriptionController.text.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.description, size: 20, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TranslatedText(
                            _descriptionController.text,
                            style: const TextStyle(fontSize: 14),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.description,
                    hintText: AppLocalizations.of(context)!.enterTaskDescription,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Location with autocomplete
                CompositedTransformTarget(
                  link: _layerLink,
                  child: TextFormField(
                    controller: _locationController,
                    focusNode: _locationFocusNode,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.location,
                      hintText: AppLocalizations.of(context)!.searchLocation,
                      prefixIcon: const Icon(Icons.location_on),
                      suffixIcon: _isSearchingLocations
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : _locationController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _locationController.clear();
                                    setState(() {
                                      _location = null;
                                      _locationLat = null;
                                      _locationLng = null;
                                    });
                                    _removeOverlay();
                                  },
                                )
                              : null,
                    ),
                    onChanged: (value) {
                      // Cancel previous timer
                      _debounceTimer?.cancel();

                      // Set new timer for debounced search
                      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                        if (value.trim().isNotEmpty) {
                          _searchLocations(value.trim());
                        } else {
                          setState(() {
                            _location = null;
                            _locationLat = null;
                            _locationLng = null;
                          });
                          _removeOverlay();
                        }
                      });
                    },
                    onTap: () {
                      // Show overlay if there are suggestions
                      if (_locationSuggestions.isNotEmpty) {
                        _showOverlay();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Date
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(AppLocalizations.of(context)!.date),
                  subtitle: Text(DateFormat('EEEE, MMM d, yyyy', Localizations.localeOf(context).languageCode).format(_selectedDate)),
                  onTap: _selectDate,
                ),

                // Time
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time),
                  title: Text(AppLocalizations.of(context)!.time),
                  subtitle: Text(
                    _selectedTime != null
                        ? _selectedTime!.format(context)
                        : AppLocalizations.of(context)!.noTimeSet,
                  ),
                  onTap: _selectTime,
                  trailing: _selectedTime != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() => _selectedTime = null);
                          },
                        )
                      : null,
                ),
                const SizedBox(height: 16),

                // Type
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.type,
                    prefixIcon: const Icon(Icons.category),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: AppConstants.todoTypeAppointment,
                      child: Text(AppLocalizations.of(context)!.appointment),
                    ),
                    DropdownMenuItem(
                      value: AppConstants.todoTypeWork,
                      child: Text(AppLocalizations.of(context)!.work),
                    ),
                    DropdownMenuItem(
                      value: AppConstants.todoTypeShopping,
                      child: Text(AppLocalizations.of(context)!.shopping),
                    ),
                    DropdownMenuItem(
                      value: AppConstants.todoTypePersonal,
                      child: Text(AppLocalizations.of(context)!.personal),
                    ),
                    DropdownMenuItem(
                      value: AppConstants.todoTypeOther,
                      child: Text(AppLocalizations.of(context)!.other),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _type = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Priority
                DropdownButtonFormField<int>(
                  value: _priority,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.priority,
                    prefixIcon: const Icon(Icons.flag),
                  ),
                  items: [
                    DropdownMenuItem(value: 1, child: Text(AppLocalizations.of(context)!.urgentP1)),
                    DropdownMenuItem(value: 2, child: Text(AppLocalizations.of(context)!.highP2)),
                    DropdownMenuItem(value: 3, child: Text(AppLocalizations.of(context)!.mediumP3)),
                    DropdownMenuItem(value: 4, child: Text(AppLocalizations.of(context)!.lowP4)),
                    DropdownMenuItem(value: 5, child: Text(AppLocalizations.of(context)!.noneP5)),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _priority = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Category Picker
                CategoryPickerWidget(
                  selectedCategoryId: _category,
                  onCategorySelected: (categoryId) {
                    setState(() => _category = categoryId);
                  },
                ),
                const SizedBox(height: 16),

                // Subtasks Section
                Text(
                  AppLocalizations.of(context)!.subtasks,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _subtaskController,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.addSubtask,
                          prefixIcon: const Icon(Icons.check_box_outline_blank, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (_) => _addSubtask(),
                        textInputAction: TextInputAction.done,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      onPressed: _addSubtask,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_subtasks.isNotEmpty)
                  SubtaskListWidget(
                    subtasks: _subtasks,
                    onSubtaskToggled: _toggleSubtask,
                    onSubtaskDeleted: _deleteSubtask,
                    onSubtaskReordered: _reorderSubtasks,
                    isEditing: true,
                  ),
                const SizedBox(height: 16),

                // Family Collaboration Section
                Consumer(
                  builder: (context, ref, child) {
                    final familyMembersState = ref.watch(familyMembersProvider);
                    final members = familyMembersState.members;

                    if (members.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Assign To dropdown
                        DropdownButtonFormField<String?>(
                          value: _assignedToId,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.assignTo,
                            prefixIcon: const Icon(Icons.person_add),
                            helperText: AppLocalizations.of(context)!.assignHelper,
                          ),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(AppLocalizations.of(context)!.notAssigned),
                            ),
                            ...members.map((member) {
                              return DropdownMenuItem<String?>(
                                value: member.id,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: member.color != null
                                          ? Color(int.parse(member.color!.substring(1), radix: 16) + 0xFF000000)
                                          : Colors.blue,
                                      child: Text(
                                        member.name.substring(0, 1).toUpperCase(),
                                        style: const TextStyle(fontSize: 10, color: Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(member.name),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _assignedToId = value;
                              _assignedToName = value != null
                                  ? members.firstWhere((m) => m.id == value).name
                                  : null;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Share With section
                        Text(
                          AppLocalizations.of(context)!.shareWith,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: members.map((member) {
                            final isShared = _sharedWith.contains(member.id);
                            return FilterChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 10,
                                    backgroundColor: member.color != null
                                        ? Color(int.parse(member.color!.substring(1), radix: 16) + 0xFF000000)
                                        : Colors.blue,
                                    child: Text(
                                      member.name.substring(0, 1).toUpperCase(),
                                      style: const TextStyle(fontSize: 8, color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(member.name),
                                ],
                              ),
                              selected: isShared,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _sharedWith.add(member.id);
                                  } else {
                                    _sharedWith.remove(member.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        if (_sharedWith.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context)!.sharedWithCount(_sharedWith.length),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),

                // Recurrence Section
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(AppLocalizations.of(context)!.repeat),
                  subtitle: _isRecurring
                      ? Text(
                          RecurrenceHelper.getRecurrenceDescription(
                            pattern: _recurrencePattern,
                            interval: _recurrenceInterval,
                            weekdays: _selectedWeekdays.isEmpty ? null : _selectedWeekdays,
                            endDate: _recurrenceEndDate,
                            locale: Localizations.localeOf(context).languageCode,
                          ),
                          style: const TextStyle(fontSize: 12),
                        )
                      : Text(AppLocalizations.of(context)!.doesNotRepeat),
                  value: _isRecurring,
                  onChanged: (value) {
                    setState(() => _isRecurring = value);
                  },
                ),

                if (_isRecurring) ...[
                  const SizedBox(height: 8),

                  // Recurrence Pattern
                  DropdownButtonFormField<String>(
                    value: _recurrencePattern,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.repeatPattern,
                      prefixIcon: const Icon(Icons.repeat),
                    ),
                    items: [
                      DropdownMenuItem(value: 'daily', child: Text(AppLocalizations.of(context)!.daily)),
                      DropdownMenuItem(value: 'weekly', child: Text(AppLocalizations.of(context)!.weekly)),
                      DropdownMenuItem(value: 'monthly', child: Text(AppLocalizations.of(context)!.monthly)),
                      DropdownMenuItem(value: 'yearly', child: Text(AppLocalizations.of(context)!.yearly)),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _recurrencePattern = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Recurrence Interval
                  Row(
                    children: [
                      Text(AppLocalizations.of(context)!.repeatEvery),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: DropdownButtonFormField<int>(
                          value: _recurrenceInterval,
                          isExpanded: true,
                          isDense: true,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            border: OutlineInputBorder(),
                          ),
                          items: List.generate(30, (i) => i + 1)
                              .map((i) => DropdownMenuItem(
                                    value: i,
                                    child: Text('$i'),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _recurrenceInterval = value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(_getIntervalLabel()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Weekday Selection (for weekly recurrence)
                  if (_recurrencePattern == 'weekly') ...[
                    Text(
                      AppLocalizations.of(context)!.repeatOn,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildWeekdayChip(AppLocalizations.of(context)!.mon, 1),
                        _buildWeekdayChip(AppLocalizations.of(context)!.tue, 2),
                        _buildWeekdayChip(AppLocalizations.of(context)!.wed, 3),
                        _buildWeekdayChip(AppLocalizations.of(context)!.thu, 4),
                        _buildWeekdayChip(AppLocalizations.of(context)!.fri, 5),
                        _buildWeekdayChip(AppLocalizations.of(context)!.sat, 6),
                        _buildWeekdayChip(AppLocalizations.of(context)!.sun, 7),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // End Date
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_busy),
                    title: Text(AppLocalizations.of(context)!.ends),
                    subtitle: Text(
                      _recurrenceEndDate != null
                          ? DateFormat('MMM d, yyyy', Localizations.localeOf(context).languageCode).format(_recurrenceEndDate!)
                          : AppLocalizations.of(context)!.never,
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _recurrenceEndDate ?? _selectedDate.add(const Duration(days: 30)),
                        firstDate: _selectedDate,
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setState(() => _recurrenceEndDate = date);
                      }
                    },
                    trailing: _recurrenceEndDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() => _recurrenceEndDate = null);
                            },
                          )
                        : null,
                  ),
                ],

                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.todoToEdit != null ? AppLocalizations.of(context)!.update : AppLocalizations.of(context)!.create),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
