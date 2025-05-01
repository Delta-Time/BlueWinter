import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('ダークモード'),
            value: isDarkMode,
            onChanged: (value) {
              themeProvider.toggleTheme();
            },
            secondary: Icon(
              isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          const Divider(),
          
          // TL画面からの投稿範囲設定
          ListTile(
            title: const Text('TL画面からの投稿範囲'),
            subtitle: Text(_getVisibilityText(settingsProvider.defaultVisibility)),
            leading: const Icon(Icons.visibility),
            onTap: () => _showVisibilityDialog(context, settingsProvider),
          ),
          
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('ログアウト'),
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  void _showVisibilityDialog(BuildContext context, SettingsProvider settingsProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('投稿範囲の設定'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildVisibilityOption(context, settingsProvider, 'public', '公開'),
              _buildVisibilityOption(context, settingsProvider, 'unlisted', '未収載'),
              _buildVisibilityOption(context, settingsProvider, 'private', 'フォロワー限定'),
              _buildVisibilityOption(context, settingsProvider, 'direct', 'ダイレクト'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('キャンセル'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVisibilityOption(BuildContext context, SettingsProvider settingsProvider, 
      String value, String label) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: settingsProvider.defaultVisibility,
      onChanged: (String? newValue) {
        if (newValue != null) {
          settingsProvider.setDefaultVisibility(newValue);
          Navigator.pop(context);
        }
      },
    );
  }

  String _getVisibilityText(String visibility) {
    switch (visibility) {
      case 'public':
        return '公開';
      case 'unlisted':
        return '未収載';
      case 'private':
        return 'フォロワー限定';
      case 'direct':
        return 'ダイレクト';
      default:
        return visibility;
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ログアウト'),
          content: const Text('本当にログアウトしますか？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await Provider.of<AuthProvider>(context, listen: false).logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              child: const Text('ログアウト'),
            ),
          ],
        );
      },
    );
  }
} 