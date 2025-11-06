// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '家庭计划';

  @override
  String get appTagline => '一起计划，共同成就';

  @override
  String get loginTitle => '登录';

  @override
  String get signUpTitle => '注册';

  @override
  String get createAccountPrompt => '创建您的账户开始使用';

  @override
  String get fullName => '姓名';

  @override
  String get email => '邮箱';

  @override
  String get password => '密码';

  @override
  String get confirmPassword => '确认密码';

  @override
  String get enterFullName => '请输入您的姓名';

  @override
  String get enterEmail => '请输入您的邮箱';

  @override
  String get enterPassword => '请输入密码';

  @override
  String get reEnterPassword => '请再次输入密码';

  @override
  String get loginButton => '登录';

  @override
  String get signUpButton => '注册';

  @override
  String get logoutButton => '退出登录';

  @override
  String get dontHaveAccount => '还没有账户？';

  @override
  String get alreadyHaveAccount => '已有账户？';

  @override
  String get loginFailed => '登录失败';

  @override
  String get registrationFailed => '注册失败';

  @override
  String get accountCreatedSuccess => '账户创建成功！';

  @override
  String get pleaseEnterName => '请输入您的姓名';

  @override
  String get pleaseEnterEmail => '请输入您的邮箱';

  @override
  String get pleaseEnterValidEmail => '请输入有效的邮箱地址';

  @override
  String get pleaseEnterPassword => '请输入密码';

  @override
  String get passwordMinLength => '密码至少需要6个字符';

  @override
  String get passwordsDoNotMatch => '两次输入的密码不一致';

  @override
  String get selectDate => '选择日期';

  @override
  String get allTasks => '所有任务';

  @override
  String get myTasks => '我的任务';

  @override
  String get familyMembers => '家庭成员';

  @override
  String get addNewTask => '添加新任务';

  @override
  String get editTask => '编辑任务';

  @override
  String get title => '标题';

  @override
  String get description => '描述（可选）';

  @override
  String get location => '位置（可选）';

  @override
  String get enterTaskTitle => '请输入任务标题';

  @override
  String get enterTaskDescription => '请输入任务描述';

  @override
  String get searchLocation => '输入至少3个字符进行搜索';

  @override
  String get date => '日期';

  @override
  String get time => '时间（可选）';

  @override
  String get noTimeSet => '未设置时间';

  @override
  String get type => '类型';

  @override
  String get priority => '优先级';

  @override
  String get subtasks => '子任务';

  @override
  String get addSubtask => '添加子任务';

  @override
  String get assignTo => '分配给';

  @override
  String get assignHelper => '将此任务分配给家庭成员';

  @override
  String get notAssigned => '未分配';

  @override
  String get shareWith => '分享给';

  @override
  String get repeat => '重复';

  @override
  String get doesNotRepeat => '不重复';

  @override
  String get repeatEvery => '每';

  @override
  String get repeatOn => '重复于：';

  @override
  String get ends => '结束';

  @override
  String get never => '永不';

  @override
  String get appointment => '预约';

  @override
  String get work => '工作';

  @override
  String get shopping => '购物';

  @override
  String get personal => '个人';

  @override
  String get other => '其他';

  @override
  String get urgentP1 => '紧急 (P1)';

  @override
  String get highP2 => '高 (P2)';

  @override
  String get mediumP3 => '中 (P3)';

  @override
  String get lowP4 => '低 (P4)';

  @override
  String get noneP5 => '无 (P5)';

  @override
  String get daily => '每天';

  @override
  String get weekly => '每周';

  @override
  String get monthly => '每月';

  @override
  String get yearly => '每年';

  @override
  String get mon => '周一';

  @override
  String get tue => '周二';

  @override
  String get wed => '周三';

  @override
  String get thu => '周四';

  @override
  String get fri => '周五';

  @override
  String get sat => '周六';

  @override
  String get sun => '周日';

  @override
  String get day => '天';

  @override
  String get days => '天';

  @override
  String get week => '周';

  @override
  String get weeks => '周';

  @override
  String get month => '月';

  @override
  String get months => '月';

  @override
  String get year => '年';

  @override
  String get years => '年';

  @override
  String get ok => '确定';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get retry => '重试';

  @override
  String get create => '创建';

  @override
  String get update => '更新';

  @override
  String get save => '保存';

  @override
  String get close => '关闭';

  @override
  String get add => '添加';

  @override
  String get remove => '移除';

  @override
  String get join => '加入';

  @override
  String get createTask => '创建';

  @override
  String get updateTask => '更新';

  @override
  String get deleteTask => '删除任务';

  @override
  String get deleteRecurringTask => '删除重复任务';

  @override
  String get deleteThisTaskOnly => '仅此任务';

  @override
  String get deleteAllRecurringTasks => '所有重复任务';

  @override
  String get deleteMultipleTasks => '删除任务';

  @override
  String confirmDeleteMultiple(int count) {
    return '确定要删除 $count 个任务吗？';
  }

  @override
  String get taskCreatedSuccess => '任务创建成功';

  @override
  String get taskUpdatedSuccess => '任务更新成功';

  @override
  String get taskDeletedSuccess => '任务已删除';

  @override
  String get allRecurringTasksDeleted => '所有重复任务已删除';

  @override
  String get updateSuccessful => '更新成功';

  @override
  String get failedToCreate => '创建任务失败';

  @override
  String failedToUpdate(String error) {
    return '更新失败：$error';
  }

  @override
  String failedToDelete(String error) {
    return '删除失败：$error';
  }

  @override
  String get subtasksUpdateFailed => '警告：子任务更新失败';

  @override
  String get errorLoadingTasks => '加载任务出错';

  @override
  String get couldNotFindTask => '找不到任务';

  @override
  String completedBy(String name) {
    return '完成者：$name';
  }

  @override
  String get category => '类别';

  @override
  String get none => '无';

  @override
  String get tags => '标签';

  @override
  String get addTags => '添加标签（按回车键）';

  @override
  String get suggestions => '建议：';

  @override
  String get createNewFamily => '创建新家庭';

  @override
  String get joinExistingFamily => '加入现有家庭';

  @override
  String get addMember => '添加成员';

  @override
  String get createYourFamily => '创建您的家庭';

  @override
  String get familyCreated => '🎉 家庭已创建！';

  @override
  String get createFamilyHelper => '创建家庭以开始与家人共享任务。';

  @override
  String get familyName => '家庭名称';

  @override
  String familyCreatedMessage(String name) {
    return '家庭 \"$name\" 已创建！';
  }

  @override
  String inviteMessage(String name, String code) {
    return '加入家庭计划的 \"$name\"！\\n\\n邀请码：$code';
  }

  @override
  String get joinFamily => '加入家庭';

  @override
  String get joinYourFamily => '加入您的家庭';

  @override
  String get inviteCode => '邀请码';

  @override
  String get joiningFamily => '正在加入...';

  @override
  String get removeFamilyMember => '移除家庭成员';

  @override
  String confirmRemoveMember(String name) {
    return '确定要将 $name 从家庭中移除吗？';
  }

  @override
  String memberRemoved(String name) {
    return '$name 已从家庭中移除';
  }

  @override
  String errorRemovingMember(String error) {
    return '移除成员时出错：$error';
  }

  @override
  String get planYourDay => '规划您的一天';

  @override
  String get optimizingSchedule => '正在优化您的日程...';

  @override
  String get deleteSelected => '删除所选';

  @override
  String get selectMultiple => '多选';

  @override
  String tasksSelected(int count) {
    return '已选择 $count 个';
  }

  @override
  String error(String message) {
    return '错误：$message';
  }

  @override
  String get loading => '加载中...';

  @override
  String get settings => '设置';

  @override
  String get language => '语言';

  @override
  String get languageEnglish => 'English (英文)';

  @override
  String get languageChinese => '中文';
}
