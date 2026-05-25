import 'package:flutter/material.dart';

import '../features/anniversaries/anniversaries_screen.dart';
import '../features/home/home_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/timeline/timeline_screen.dart';
import '../features/wishlist/wishlist_screen.dart';

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

  void _openSecondaryPage(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: SafeArea(child: child),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final destinations = <AppDestination>[
      AppDestination(
        label: 'Home',
        icon: Icons.favorite_border,
        selectedIcon: Icons.favorite,
        screen: HomeScreen(
          onWriteTodayNote: () => _selectTab(1),
          onReviewDates: () => _selectTab(2),
          onOpenBacklog: () => _openSecondaryPage(
            context,
            title: 'Ideas backlog',
            child: const WishlistScreen(),
          ),
          onOpenSettings: () => _openSecondaryPage(
            context,
            title: 'Space settings',
            child: const ProfileScreen(),
          ),
        ),
      ),
      const AppDestination(
        label: 'Timeline',
        icon: Icons.timeline_outlined,
        selectedIcon: Icons.timeline,
        screen: TimelineScreen(),
      ),
      const AppDestination(
        label: 'Dates',
        icon: Icons.event_outlined,
        selectedIcon: Icons.event,
        screen: AnniversariesScreen(),
      ),
    ];
    final current = destinations[_selectedIndex];

    return Scaffold(
      appBar: AppBar(title: Text(current.label)),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: destinations.map((destination) => destination.screen).toList(),
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
