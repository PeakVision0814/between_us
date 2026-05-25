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

  static const _destinations = <AppDestination>[
    AppDestination(
      label: 'Home',
      icon: Icons.favorite_border,
      selectedIcon: Icons.favorite,
      screen: HomeScreen(),
    ),
    AppDestination(
      label: 'Timeline',
      icon: Icons.timeline_outlined,
      selectedIcon: Icons.timeline,
      screen: TimelineScreen(),
    ),
    AppDestination(
      label: 'Dates',
      icon: Icons.event_outlined,
      selectedIcon: Icons.event,
      screen: AnniversariesScreen(),
    ),
    AppDestination(
      label: 'Wishlist',
      icon: Icons.card_giftcard_outlined,
      selectedIcon: Icons.card_giftcard,
      screen: WishlistScreen(),
    ),
    AppDestination(
      label: 'Profile',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      screen: ProfileScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final current = _destinations[_selectedIndex];

    return Scaffold(
      appBar: AppBar(title: Text(current.label)),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: _destinations
              .map((destination) => destination.screen)
              .toList(),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: _destinations
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
