import '../domain/entities/task_template_entity.dart';

/// Predefined task templates for common scenarios
class PredefinedTemplates {
  static final List<TaskTemplateEntity> templates = [
    // Shopping List Template
    TaskTemplateEntity(
      id: 'weekly_shopping',
      userId: 'system',
      title: 'Weekly Shopping',
      description: 'Regular grocery shopping list',
      category: 'shopping',
      tags: ['groceries', 'weekly'],
      priority: 2,
      type: 'shopping',
      isPredefined: true,
      subtasks: [
        TaskTemplateSubtask(title: 'Fruits and vegetables', order: 1),
        TaskTemplateSubtask(title: 'Dairy products', order: 2),
        TaskTemplateSubtask(title: 'Meat and protein', order: 3),
        TaskTemplateSubtask(title: 'Bread and bakery', order: 4),
        TaskTemplateSubtask(title: 'Beverages', order: 5),
        TaskTemplateSubtask(title: 'Snacks', order: 6),
        TaskTemplateSubtask(title: 'Cleaning supplies', order: 7),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    // Morning Routine Template
    TaskTemplateEntity(
      id: 'morning_routine',
      userId: 'system',
      title: 'Morning Routine',
      description: 'Daily morning tasks',
      category: 'personal',
      tags: ['routine', 'daily'],
      priority: 1,
      type: 'personal',
      isPredefined: true,
      subtasks: [
        TaskTemplateSubtask(title: 'Wake up and stretch', order: 1),
        TaskTemplateSubtask(title: 'Shower and get dressed', order: 2),
        TaskTemplateSubtask(title: 'Make breakfast', order: 3),
        TaskTemplateSubtask(title: 'Check emails', order: 4),
        TaskTemplateSubtask(title: 'Review today\'s tasks', order: 5),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    // House Cleaning Template
    TaskTemplateEntity(
      id: 'weekly_cleaning',
      userId: 'system',
      title: 'Weekly House Cleaning',
      description: 'Complete house cleaning checklist',
      category: 'home',
      tags: ['cleaning', 'weekly', 'chores'],
      priority: 2,
      type: 'personal',
      isPredefined: true,
      subtasks: [
        TaskTemplateSubtask(title: 'Vacuum all rooms', order: 1),
        TaskTemplateSubtask(title: 'Mop kitchen and bathroom', order: 2),
        TaskTemplateSubtask(title: 'Clean bathrooms', order: 3),
        TaskTemplateSubtask(title: 'Dust furniture', order: 4),
        TaskTemplateSubtask(title: 'Change bed sheets', order: 5),
        TaskTemplateSubtask(title: 'Take out trash and recycling', order: 6),
        TaskTemplateSubtask(title: 'Clean windows', order: 7),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    // Meal Prep Template
    TaskTemplateEntity(
      id: 'meal_prep',
      userId: 'system',
      title: 'Weekly Meal Prep',
      description: 'Prepare meals for the week',
      category: 'family',
      tags: ['cooking', 'meal-prep', 'weekly'],
      priority: 2,
      type: 'personal',
      isPredefined: true,
      subtasks: [
        TaskTemplateSubtask(title: 'Plan weekly menu', order: 1),
        TaskTemplateSubtask(title: 'Check pantry inventory', order: 2),
        TaskTemplateSubtask(title: 'Make shopping list', order: 3),
        TaskTemplateSubtask(title: 'Buy ingredients', order: 4),
        TaskTemplateSubtask(title: 'Prep vegetables', order: 5),
        TaskTemplateSubtask(title: 'Cook proteins', order: 6),
        TaskTemplateSubtask(title: 'Portion and store meals', order: 7),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    // Work Project Setup Template
    TaskTemplateEntity(
      id: 'project_setup',
      userId: 'system',
      title: 'New Project Setup',
      description: 'Start a new work project',
      category: 'work',
      tags: ['project', 'setup', 'work'],
      priority: 1,
      type: 'work',
      isPredefined: true,
      subtasks: [
        TaskTemplateSubtask(title: 'Define project scope', order: 1),
        TaskTemplateSubtask(title: 'Set up project workspace', order: 2),
        TaskTemplateSubtask(title: 'Create timeline', order: 3),
        TaskTemplateSubtask(title: 'Assign team roles', order: 4),
        TaskTemplateSubtask(title: 'Schedule kickoff meeting', order: 5),
        TaskTemplateSubtask(title: 'Set up communication channels', order: 6),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    // Doctor Appointment Template
    TaskTemplateEntity(
      id: 'doctor_appointment',
      userId: 'system',
      title: 'Doctor Appointment',
      description: 'Prepare for doctor visit',
      category: 'health',
      tags: ['health', 'appointment'],
      priority: 1,
      type: 'appointment',
      isPredefined: true,
      subtasks: [
        TaskTemplateSubtask(title: 'Check insurance card', order: 1),
        TaskTemplateSubtask(title: 'List current medications', order: 2),
        TaskTemplateSubtask(title: 'Write down symptoms/questions', order: 3),
        TaskTemplateSubtask(title: 'Bring medical records if needed', order: 4),
        TaskTemplateSubtask(title: 'Arrive 15 minutes early', order: 5),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    // Travel Packing Template
    TaskTemplateEntity(
      id: 'travel_packing',
      userId: 'system',
      title: 'Travel Packing List',
      description: 'Pack for a trip',
      category: 'personal',
      tags: ['travel', 'packing', 'vacation'],
      priority: 1,
      type: 'personal',
      isPredefined: true,
      subtasks: [
        TaskTemplateSubtask(title: 'Pack clothes for each day', order: 1),
        TaskTemplateSubtask(title: 'Toiletries and medications', order: 2),
        TaskTemplateSubtask(title: 'Phone charger and electronics', order: 3),
        TaskTemplateSubtask(title: 'Travel documents (passport, tickets)', order: 4),
        TaskTemplateSubtask(title: 'Snacks and water bottle', order: 5),
        TaskTemplateSubtask(title: 'Entertainment (books, headphones)', order: 6),
        TaskTemplateSubtask(title: 'Money and cards', order: 7),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    // Bill Payment Template
    TaskTemplateEntity(
      id: 'monthly_bills',
      userId: 'system',
      title: 'Monthly Bill Payment',
      description: 'Pay monthly recurring bills',
      category: 'finance',
      tags: ['bills', 'finance', 'monthly'],
      priority: 1,
      type: 'personal',
      isPredefined: true,
      subtasks: [
        TaskTemplateSubtask(title: 'Rent/Mortgage', order: 1),
        TaskTemplateSubtask(title: 'Utilities (electric, water, gas)', order: 2),
        TaskTemplateSubtask(title: 'Internet and phone', order: 3),
        TaskTemplateSubtask(title: 'Insurance payments', order: 4),
        TaskTemplateSubtask(title: 'Credit card payments', order: 5),
        TaskTemplateSubtask(title: 'Subscriptions (streaming, gym, etc.)', order: 6),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    // Car Maintenance Template
    TaskTemplateEntity(
      id: 'car_maintenance',
      userId: 'system',
      title: 'Car Maintenance',
      description: 'Regular vehicle maintenance',
      category: 'errands',
      tags: ['car', 'maintenance', 'vehicle'],
      priority: 2,
      type: 'personal',
      isPredefined: true,
      subtasks: [
        TaskTemplateSubtask(title: 'Check oil level', order: 1),
        TaskTemplateSubtask(title: 'Check tire pressure', order: 2),
        TaskTemplateSubtask(title: 'Check coolant and fluids', order: 3),
        TaskTemplateSubtask(title: 'Check brake pads', order: 4),
        TaskTemplateSubtask(title: 'Clean interior and exterior', order: 5),
        TaskTemplateSubtask(title: 'Check lights and signals', order: 6),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    // Birthday Party Planning Template
    TaskTemplateEntity(
      id: 'birthday_party',
      userId: 'system',
      title: 'Birthday Party Planning',
      description: 'Plan a birthday celebration',
      category: 'family',
      tags: ['party', 'birthday', 'celebration'],
      priority: 2,
      type: 'personal',
      isPredefined: true,
      subtasks: [
        TaskTemplateSubtask(title: 'Set date and time', order: 1),
        TaskTemplateSubtask(title: 'Create guest list', order: 2),
        TaskTemplateSubtask(title: 'Send invitations', order: 3),
        TaskTemplateSubtask(title: 'Plan menu/order cake', order: 4),
        TaskTemplateSubtask(title: 'Buy decorations', order: 5),
        TaskTemplateSubtask(title: 'Plan activities/games', order: 6),
        TaskTemplateSubtask(title: 'Buy/prepare party favors', order: 7),
        TaskTemplateSubtask(title: 'Set up venue', order: 8),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  /// Get template by ID
  static TaskTemplateEntity? getTemplateById(String id) {
    try {
      return templates.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get templates by category
  static List<TaskTemplateEntity> getTemplatesByCategory(String category) {
    return templates.where((t) => t.category == category).toList();
  }

  /// Get all template categories
  static List<String> getCategories() {
    return templates
        .map((t) => t.category ?? '')
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
  }
}
