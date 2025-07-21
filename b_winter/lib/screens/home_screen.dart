import 'package:flutter/material.dart';
import 'timeline_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BlueWinter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'ホーム'),
            Tab(text: '通知'),
            Tab(text: 'ローカル'),
            Tab(text: '連合'),
          ],
          labelColor: isDarkMode ? Colors.white : Colors.black,
          unselectedLabelColor: isDarkMode ? Colors.white60 : Colors.black54,
          indicatorColor: isDarkMode ? Colors.white : Colors.blue,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // ホームタイムライン
          TimelineScreen(
            timelineType: 'home',
            title: 'ホーム',
          ),
          
          // 通知画面
          const NotificationsScreen(),
          
          // ローカルタイムライン
          TimelineScreen(
            timelineType: 'local',
            title: 'ローカル',
          ),
          
          // 連合タイムライン
          TimelineScreen(
            timelineType: 'federated',
            title: '連合',
          ),
        ],
      ),
    );
  }
} 