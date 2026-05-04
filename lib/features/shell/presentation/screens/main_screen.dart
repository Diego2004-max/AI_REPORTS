import 'package:flutter/material.dart';

import 'package:reportes_ai/features/home/presentation/screens/home_screen.dart';
import 'package:reportes_ai/features/map/presentation/screens/map_screen.dart';
import 'package:reportes_ai/features/profile/presentation/screens/profile_screen.dart';
import 'package:reportes_ai/features/reports/presentation/screens/create_report_screen.dart';
import 'package:reportes_ai/features/reports/presentation/screens/report_list_screen.dart';
import 'package:reportes_ai/shared/widgets/shared_widgets.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  Future<void> _onCreateReportTap() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateReportScreen()),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return const HomeScreen();
      case 1:
        return const MapScreen();
      case 2:
        return const ReportListScreen();
      case 3:
        return const ProfileScreen();
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _buildCurrentScreen(),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        onCreate: _onCreateReportTap,
      ),
    );
  }
}
