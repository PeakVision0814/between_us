import 'package:flutter/material.dart';

void main() {
  runApp(const BetweenUsApp());
}

class BetweenUsApp extends StatelessWidget {
  const BetweenUsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Between Us',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AppShell(),
    );
  }
}

class AppTheme {
  static const Color ink = Color(0xFF231F20);
  static const Color paper = Color(0xFFFFF8F1);
  static const Color blush = Color(0xFFE86F64);
  static const Color berry = Color(0xFF7D3B52);
  static const Color mint = Color(0xFF5B9A8B);
  static const Color gold = Color(0xFFE1A955);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: blush,
      brightness: Brightness.light,
      surface: paper,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: paper,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: ink.withValues(alpha: 0.08)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        indicatorColor: blush.withValues(alpha: 0.16),
        backgroundColor: Colors.white,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected) ? berry : ink,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: ink,
          fontSize: 26,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: TextStyle(
          color: ink,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: TextStyle(
          color: ink,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: TextStyle(color: ink, height: 1.45),
      ),
    );
  }
}

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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      children: [
        Text('Between Us', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'A calm private space for memories, plans, and small everyday rituals.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        const CoupleOverviewCard(),
        const SizedBox(height: 14),
        const DailyNoteCard(),
        const SizedBox(height: 14),
        const SectionHeader(title: 'Next up'),
        const FeatureTile(
          icon: Icons.event_available,
          color: AppTheme.gold,
          title: 'First anniversary',
          subtitle: 'Add the relationship start date and show countdowns here.',
        ),
      ],
    );
  }
}

class CoupleOverviewCard extends StatelessWidget {
  const CoupleOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleBadge(label: 'A', color: AppTheme.blush),
                const SizedBox(width: 8),
                const CircleBadge(label: 'B', color: AppTheme.mint),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.berry.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'private beta',
                    style: TextStyle(
                      color: AppTheme.berry,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Our shared room',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            const Text(
              'Supabase auth and couple-space sync will connect this card to real private data in Phase 3.',
            ),
          ],
        ),
      ),
    );
  }
}

class DailyNoteCard extends StatelessWidget {
  const DailyNoteCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.sticky_note_2_outlined, color: AppTheme.blush),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily note',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'A lightweight message area will land here before backend sync.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      children: [
        SectionHeader(title: 'Timeline'),
        FeatureTile(
          icon: Icons.auto_stories_outlined,
          color: AppTheme.blush,
          title: 'Movie night',
          subtitle: 'Sample local entry for the first prototype.',
        ),
        FeatureTile(
          icon: Icons.local_cafe_outlined,
          color: AppTheme.mint,
          title: 'Sunday walk',
          subtitle: 'Timeline entries will later sync by couple space.',
        ),
      ],
    );
  }
}

class AnniversariesScreen extends StatelessWidget {
  const AnniversariesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      children: [
        SectionHeader(title: 'Anniversaries'),
        FeatureTile(
          icon: Icons.favorite_outline,
          color: AppTheme.berry,
          title: 'Relationship start',
          subtitle: 'Create countdowns and yearly reminders.',
        ),
        FeatureTile(
          icon: Icons.celebration_outlined,
          color: AppTheme.gold,
          title: 'Special days',
          subtitle: 'Birthdays, first trips, and private rituals.',
        ),
      ],
    );
  }
}

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      children: [
        SectionHeader(title: 'Wishlist'),
        FeatureTile(
          icon: Icons.restaurant_menu,
          color: AppTheme.mint,
          title: 'Home menu',
          subtitle: 'A later module for shared food requests and status.',
        ),
        FeatureTile(
          icon: Icons.redeem_outlined,
          color: AppTheme.blush,
          title: 'Gift ideas',
          subtitle: 'Keep small wishes in one private place.',
        ),
      ],
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      children: [
        SectionHeader(title: 'Profile'),
        FeatureTile(
          icon: Icons.lock_outline,
          color: AppTheme.berry,
          title: 'Private by default',
          subtitle:
              'No public profiles, feeds, or analytics-first product choices.',
        ),
        FeatureTile(
          icon: Icons.cloud_outlined,
          color: AppTheme.mint,
          title: 'Supabase pending',
          subtitle:
              'Auth, RLS, storage, and sync will be added after the local prototype.',
        ),
      ],
    );
  }
}

class AppPage extends StatelessWidget {
  const AppPage({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: children,
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

class FeatureTile extends StatelessWidget {
  const FeatureTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(subtitle),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CircleBadge extends StatelessWidget {
  const CircleBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
