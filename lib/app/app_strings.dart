import 'package:flutter/material.dart';

import 'app_controller.dart';

class AppStrings {
  const AppStrings._(this.language);

  final AppLanguage language;

  bool get isChinese => language == AppLanguage.zhCn;

  static AppStrings of(BuildContext context) {
    final controller = AppScope.of(context);
    return AppStrings._(controller.language);
  }

  String get appName => 'Between Us';
  String get homeTab => isChinese ? '首页' : 'Home';
  String get momentsTab => isChinese ? '片刻' : 'Moments';
  String get datesTab => isChinese ? '日期' : 'Dates';
  String get settingsTitle => isChinese ? '设置' : 'Settings';
  String get settingsTooltip => settingsTitle;
  String get homeGreeting =>
      isChinese ? _greetingInChinese() : _greetingInEnglish();
  String get homeSubtitle => isChinese
      ? '想说的时候，留一句就好。'
      : 'Leave a little note whenever it feels right.';
  String get leaveOneLineLabel => isChinese ? '留一句话' : 'Leave a note';
  String get recentMomentSection => isChinese ? '刚刚的片刻' : 'A recent moment';
  String get nextDateSection => isChinese ? '下一个重要日期' : 'Next important date';
  String get quickLinksSection => isChinese ? '顺手看看' : 'Quick look';
  String get openMomentsLabel => isChinese ? '去片刻' : 'Open Moments';
  String get openDatesLabel => isChinese ? '看日期' : 'View Dates';
  String get openSettingsLabel => isChinese ? '设置' : 'Settings';
  String get coupleHeadline => isChinese ? '小满 和 阿澈' : 'Xiaoman & Ache';
  String get coupleStatus => isChinese ? '在一起第 214 天' : 'Day 214 together';
  String get coupleNote => isChinese
      ? '今晚都在，晚点一起吃面。'
      : 'Both around tonight. Maybe noodles a little later.';
  String get actionCardTitle =>
      isChinese ? '现在想说点什么？' : 'Anything you want to say?';
  String get actionCardHint => isChinese
      ? '不用写长句，留一句就已经很好。'
      : 'It does not need to be long. One line is already enough.';
  String get actionCardExample => isChinese
      ? '比如：到家记得跟我说一声，我给你留一碗汤。'
      : 'For example: text me when you get home. I will save you a bowl of soup.';
  String get momentsPageTitle => momentsTab;
  String get momentsIntro => isChinese
      ? '想到的时候留一句，翻回来看看也轻轻松松。'
      : 'Drop a small note when it comes to mind, then come back to it later.';
  String get momentsListTitle => isChinese ? '最近的片刻' : 'Recent moments';
  String get datesPageTitle => datesTab;
  String get datesHeroTitle => isChinese ? '最近要记得的是' : 'Coming up next';
  String get savedDatesTitle => isChinese ? '已经记下的日期' : 'Saved dates';
  String get settingsLanguageTitle => isChinese ? '语言' : 'Language';
  String get settingsThemeTitle => isChinese ? '主题模式' : 'Theme mode';
  String get settingsTimeZoneTitle => isChinese ? '设备时区' : 'Device time zone';
  String get settingsTimeZoneHint => isChinese
      ? '首页的今天、片刻时间和倒计时都会按这里显示。'
      : 'Home, moment times, and countdowns follow this device time zone.';
  String get settingsLockPreviewTitle =>
      isChinese ? '锁屏预览' : 'Lock-screen previews';
  String get settingsLockPreviewSubtitle => isChinese
      ? '在通知里直接显示片刻内容。'
      : 'Show moment text directly inside notifications.';
  String get settingsLocalHint => isChinese
      ? '这些设置现在只在本地预览里生效。'
      : 'These settings only live inside this local prototype for now.';
  String get chineseLabel => '简体中文';
  String get englishLabel => 'English';
  String get themeSystemLabel => isChinese ? '跟随系统' : 'System';
  String get themeLightLabel => isChinese ? '浅色' : 'Light';
  String get themeDarkLabel => isChinese ? '深色' : 'Dark';

  List<MomentCopy> get moments => isChinese
      ? const [
          MomentCopy(author: '阿澈', timeLabel: '刚刚', text: '到家啦，楼下买到了你喜欢的豆花。'),
          MomentCopy(
            author: '小满',
            timeLabel: '昨晚 21:18',
            text: '今天风有点大，回来的时候记得把外套拉好。',
          ),
          MomentCopy(
            author: '阿澈',
            timeLabel: '周日 17:40',
            text: '下次还想跟你去那家小店，汤底真的很暖。',
          ),
        ]
      : const [
          MomentCopy(
            author: 'Ache',
            timeLabel: 'Just now',
            text:
                'I am home. The tofu pudding place downstairs still had your favorite one.',
          ),
          MomentCopy(
            author: 'Xiaoman',
            timeLabel: 'Last night 9:18 PM',
            text: 'The wind was strong today. Zip your jacket on the way back.',
          ),
          MomentCopy(
            author: 'Ache',
            timeLabel: 'Sun 5:40 PM',
            text:
                'I want to go back to that little place with you. The broth felt so warm.',
          ),
        ];

  List<DateCopy> get dates => isChinese
      ? const [
          DateCopy(
            title: '关系纪念日',
            dateLabel: '6 月 6 日',
            countdownLabel: '还有 12 天',
            subtitle: '每年都想认真记得的那一天',
          ),
          DateCopy(
            title: '第一次一起看海',
            dateLabel: '6 月 25 日',
            countdownLabel: '还有 31 天',
            subtitle: '这次想早点出发，给日落留时间',
          ),
          DateCopy(
            title: '阿澈生日',
            dateLabel: '8 月 8 日',
            countdownLabel: '还有 75 天',
            subtitle: '先把那家蛋糕店记着',
          ),
        ]
      : const [
          DateCopy(
            title: 'Relationship anniversary',
            dateLabel: 'June 6',
            countdownLabel: '12 days left',
            subtitle: 'The day we always want to keep in mind',
          ),
          DateCopy(
            title: 'First trip to the sea',
            dateLabel: 'June 25',
            countdownLabel: '31 days left',
            subtitle:
                'Start a little earlier this time so sunset does not rush us',
          ),
          DateCopy(
            title: 'Ache\'s birthday',
            dateLabel: 'August 8',
            countdownLabel: '75 days left',
            subtitle: 'Keep that cake shop in mind',
          ),
        ];

  String _greetingInChinese() {
    final hour = DateTime.now().hour;
    if (hour < 11) {
      return '早安';
    }
    if (hour < 18) {
      return '下午好';
    }
    return '晚上好';
  }

  String _greetingInEnglish() {
    final hour = DateTime.now().hour;
    if (hour < 11) {
      return 'Good morning';
    }
    if (hour < 18) {
      return 'Good afternoon';
    }
    return 'Good evening';
  }
}

class MomentCopy {
  const MomentCopy({
    required this.author,
    required this.timeLabel,
    required this.text,
  });

  final String author;
  final String timeLabel;
  final String text;
}

class DateCopy {
  const DateCopy({
    required this.title,
    required this.dateLabel,
    required this.countdownLabel,
    required this.subtitle,
  });

  final String title;
  final String dateLabel;
  final String countdownLabel;
  final String subtitle;
}
