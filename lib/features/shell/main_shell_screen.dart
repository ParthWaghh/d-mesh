import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../communication/screens/communication_screen.dart';
import '../dashboard/screens/dashboard_screen.dart';
import '../emergency/screens/emergency_screen.dart';
import '../live_map/screens/live_map_screen.dart';
import '../network/screens/network_screen.dart';
import '../settings/screens/settings_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardScreen(onNavigateToTab: _onTabSelected),
      const CommunicationScreen(),
      const LiveMapScreen(),
      const EmergencyScreen(),
      const NetworkScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.cyan),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum, color: AppColors.cyan),
            label: 'Comm',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: AppColors.cyan),
            label: 'Live Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.warning_amber_rounded),
            selectedIcon: Icon(Icons.warning_rounded, color: AppColors.redEmergency),
            label: 'SOS',
          ),
          NavigationDestination(
            icon: Icon(Icons.hub_outlined),
            selectedIcon: Icon(Icons.hub, color: AppColors.cyan),
            label: 'Network',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: AppColors.cyan),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

