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

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final destinations = <AppDestination>[
      AppDestination(
        label: strings.homeTab,
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        screen: HomeScreen(
          onOpenCalendar: () => _selectTab(1),
          onOpenPlansNotes: () => _selectTab(2),
          onOpenUs: () => _selectTab(3),
          onCreatePlan: () => _selectTab(2),
          onWriteNote: () => _selectTab(2),
        ),
      ),
      AppDestination(
        label: strings.calendarTab,
        icon: Icons.calendar_month_outlined,
        selectedIcon: Icons.calendar_month,
        screen: const CalendarScreen(),
      ),
      AppDestination(
        label: strings.plansNotesTab,
        icon: Icons.edit_note_outlined,
        selectedIcon: Icons.edit_note,
        screen: const PlansNotesScreen(),
      ),
      AppDestination(
        label: strings.usTab,
        icon: Icons.favorite_border,
        selectedIcon: Icons.favorite,
        screen: const UsScreen(),
      ),
    ];
    final current = destinations[_selectedIndex];

    return Scaffold(
      appBar: AppBar(title: Text(current.label)),
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
