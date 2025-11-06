// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Family Planner';

  @override
  String get appTagline => 'Plan together, achieve together';

  @override
  String get loginTitle => 'Log In';

  @override
  String get signUpTitle => 'Sign Up';

  @override
  String get createAccountPrompt => 'Create your account to get started';

  @override
  String get fullName => 'Full Name';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get enterFullName => 'Enter your full name';

  @override
  String get enterEmail => 'Enter your email';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get reEnterPassword => 'Re-enter your password';

  @override
  String get loginButton => 'Log In';

  @override
  String get signUpButton => 'Sign Up';

  @override
  String get logoutButton => 'Logout';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get loginFailed => 'Login Failed';

  @override
  String get registrationFailed => 'Registration failed';

  @override
  String get accountCreatedSuccess => 'Account created successfully!';

  @override
  String get pleaseEnterName => 'Please enter your name';

  @override
  String get pleaseEnterEmail => 'Please enter your email';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get selectDate => 'Select a date';

  @override
  String get allTasks => 'All Tasks';

  @override
  String get myTasks => 'My Tasks';

  @override
  String get familyMembers => 'Family Members';

  @override
  String get addNewTask => 'Add New Task';

  @override
  String get editTask => 'Edit Task';

  @override
  String get title => 'Title';

  @override
  String get description => 'Description (optional)';

  @override
  String get location => 'Location (optional)';

  @override
  String get enterTaskTitle => 'Enter task title';

  @override
  String get enterTaskDescription => 'Enter task description';

  @override
  String get searchLocation => 'Type at least 3 characters to search';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time (optional)';

  @override
  String get noTimeSet => 'No time set';

  @override
  String get type => 'Type';

  @override
  String get priority => 'Priority';

  @override
  String get subtasks => 'Subtasks';

  @override
  String get addSubtask => 'Add a subtask';

  @override
  String get assignTo => 'Assign To';

  @override
  String get assignHelper => 'Assign this task to a family member';

  @override
  String get notAssigned => 'Not assigned';

  @override
  String get shareWith => 'Share With';

  @override
  String get repeat => 'Repeat';

  @override
  String get doesNotRepeat => 'Does not repeat';

  @override
  String get repeatEvery => 'Repeat every';

  @override
  String get repeatOn => 'Repeat on:';

  @override
  String get ends => 'Ends';

  @override
  String get never => 'Never';

  @override
  String get appointment => 'Appointment';

  @override
  String get work => 'Work';

  @override
  String get shopping => 'Shopping';

  @override
  String get personal => 'Personal';

  @override
  String get other => 'Other';

  @override
  String get urgentP1 => 'Urgent (P1)';

  @override
  String get highP2 => 'High (P2)';

  @override
  String get mediumP3 => 'Medium (P3)';

  @override
  String get lowP4 => 'Low (P4)';

  @override
  String get noneP5 => 'None (P5)';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get yearly => 'Yearly';

  @override
  String get mon => 'Mon';

  @override
  String get tue => 'Tue';

  @override
  String get wed => 'Wed';

  @override
  String get thu => 'Thu';

  @override
  String get fri => 'Fri';

  @override
  String get sat => 'Sat';

  @override
  String get sun => 'Sun';

  @override
  String get day => 'day';

  @override
  String get days => 'days';

  @override
  String get week => 'week';

  @override
  String get weeks => 'weeks';

  @override
  String get month => 'month';

  @override
  String get months => 'months';

  @override
  String get year => 'year';

  @override
  String get years => 'years';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get retry => 'Retry';

  @override
  String get create => 'Create';

  @override
  String get update => 'Update';

  @override
  String get save => 'Save';

  @override
  String get close => 'Close';

  @override
  String get add => 'Add';

  @override
  String get remove => 'Remove';

  @override
  String get join => 'Join';

  @override
  String get createTask => 'Create';

  @override
  String get updateTask => 'Update';

  @override
  String get deleteTask => 'Delete Task';

  @override
  String get deleteRecurringTask => 'Delete Recurring Task';

  @override
  String get deleteThisTaskOnly => 'This task only';

  @override
  String get deleteAllRecurringTasks => 'All recurring tasks';

  @override
  String get deleteMultipleTasks => 'Delete Tasks';

  @override
  String confirmDeleteMultiple(int count) {
    return 'Are you sure you want to delete $count task(s)?';
  }

  @override
  String get taskCreatedSuccess => 'Task created successfully';

  @override
  String get taskUpdatedSuccess => 'Task updated successfully';

  @override
  String get taskDeletedSuccess => 'Task deleted';

  @override
  String get allRecurringTasksDeleted => 'All recurring tasks deleted';

  @override
  String get updateSuccessful => 'Update successful';

  @override
  String get failedToCreate => 'Failed to create task';

  @override
  String failedToUpdate(String error) {
    return 'Failed to update: $error';
  }

  @override
  String failedToDelete(String error) {
    return 'Failed to delete: $error';
  }

  @override
  String get subtasksUpdateFailed => 'Warning: Subtasks update failed';

  @override
  String get errorLoadingTasks => 'Error loading tasks';

  @override
  String get couldNotFindTask => 'Could not find task';

  @override
  String completedBy(String name) {
    return 'Completed by: $name';
  }

  @override
  String get category => 'Category';

  @override
  String get none => 'None';

  @override
  String get tags => 'Tags';

  @override
  String get addTags => 'Add tags (press Enter)';

  @override
  String get suggestions => 'Suggestions:';

  @override
  String get createNewFamily => 'Create New Family';

  @override
  String get joinExistingFamily => 'Join Existing Family';

  @override
  String get addMember => 'Add Member';

  @override
  String get createYourFamily => 'Create Your Family';

  @override
  String get familyCreated => '🎉 Family Created!';

  @override
  String get createFamilyHelper =>
      'Create a family to start sharing tasks with your family members.';

  @override
  String get familyName => 'Family Name';

  @override
  String familyCreatedMessage(String name) {
    return 'Family \"$name\" created!';
  }

  @override
  String inviteMessage(String name, String code) {
    return 'Join \"$name\" on Family Planner!\\n\\n$code';
  }

  @override
  String get joinFamily => 'Join Family';

  @override
  String get joinYourFamily => 'Join Your Family';

  @override
  String get inviteCode => 'Invite Code';

  @override
  String get joiningFamily => 'Joining...';

  @override
  String get removeFamilyMember => 'Remove Family Member';

  @override
  String confirmRemoveMember(String name) {
    return 'Are you sure you want to remove $name from your family?';
  }

  @override
  String memberRemoved(String name) {
    return '$name removed from family';
  }

  @override
  String errorRemovingMember(String error) {
    return 'Error removing member: $error';
  }

  @override
  String get planYourDay => 'Plan Your Day';

  @override
  String get optimizingSchedule => 'Optimizing your schedule...';

  @override
  String get deleteSelected => 'Delete selected';

  @override
  String get selectMultiple => 'Select multiple';

  @override
  String tasksSelected(int count) {
    return '$count selected';
  }

  @override
  String error(String message) {
    return 'Error: $message';
  }

  @override
  String get loading => 'Loading...';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => '中文 (Chinese)';
}
