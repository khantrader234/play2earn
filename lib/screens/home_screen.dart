import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import 'spin_screen.dart';
import 'daily_bonus_screen.dart';
import 'wallet_screen.dart';
import 'play_screen.dart';
import 'watch_ads_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const PlayScreen(),
    const DailyBonusScreen(),
    const SpinScreen(),
    const WalletScreen(),
    const WatchAdsScreen(),
    const ProfileScreen(),
  ];

  final List<String> _titles = [
    'Play Games',
    'Daily Bonus',
    'Daily Spin',
    'Wallet',
    'Watch & Earn',
    'Profile'
  ];

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF242B3D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider).signOut();
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Color(0xFFFFD700)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1F2C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF242B3D),
        elevation: 0,
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFFFD700)),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF242B3D),
        height: 65,
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: const Color(0xFFFFD700).withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.games, color: Colors.grey),
            selectedIcon: Icon(Icons.games, color: Color(0xFFFFD700)),
            label: 'Play',
          ),
          NavigationDestination(
            icon: Icon(Icons.card_giftcard, color: Colors.grey),
            selectedIcon: Icon(Icons.card_giftcard, color: Color(0xFFFFD700)),
            label: 'Daily B...',
          ),
          NavigationDestination(
            icon: Icon(Icons.casino, color: Colors.grey),
            selectedIcon: Icon(Icons.casino, color: Color(0xFFFFD700)),
            label: 'Spin',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet, color: Colors.grey),
            selectedIcon:
                Icon(Icons.account_balance_wallet, color: Color(0xFFFFD700)),
            label: 'Wallet',
          ),
          NavigationDestination(
            icon: Icon(Icons.play_circle_outline, color: Colors.grey),
            selectedIcon:
                Icon(Icons.play_circle_outline, color: Color(0xFFFFD700)),
            label: 'Watch ...',
          ),
          NavigationDestination(
            icon: Icon(Icons.person, color: Colors.grey),
            selectedIcon: Icon(Icons.person, color: Color(0xFFFFD700)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
