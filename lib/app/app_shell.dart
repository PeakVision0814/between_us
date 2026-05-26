import 'package:flutter/material.dart';

import '../features/anniversaries/anniversaries_screen.dart';
import '../features/home/home_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/timeline/timeline_screen.dart';
import 'app_strings.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final destinations = <AppDestination>[
      AppDestination(
        label: strings.homeTab,
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        screen: HomeScreen(
          onLeaveOneLine: () => _selectTab(1),
          onReviewDates: () => _selectTab(2),
          onOpenMoments: () => _selectTab(1),
          onOpenSettings: () => _openSettings(context),
        ),
      ),
      AppDestination(
        label: strings.momentsTab,
        icon: Icons.auto_awesome_outlined,
        selectedIcon: Icons.auto_awesome,
        screen: const TimelineScreen(),
      ),
      AppDestination(
        label: strings.datesTab,
        icon: Icons.event_note_outlined,
        selectedIcon: Icons.event_note,
        screen: const AnniversariesScreen(),
      ),
    ];
    final current = destinations[_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(current.label),
        actions: [
          IconButton(
            onPressed: () => _openSettings(context),
            tooltip: strings.settingsTooltip,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: destinations
              .map((destination) => destination.screen)
              .toList(),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        destinations: destinations
            .map(
              (destination) => NavigationDestination(
                icon: Icon(destination.icon),
                selectedIcon: Icon(destination.selectedIcon),
                label: destination.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class AppDestination {
  const AppDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;
}
