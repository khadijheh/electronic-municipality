import 'package:flutter/material.dart' hide Text;
import 'package:electronic_municipality_final/l10n/localized_text.dart';
import 'package:electronic_municipality_final/l10n/app_localizations.dart';
import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../complaints/presentation/screens/complaints_screen.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../news/presentation/screens/news_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../transactions/presentation/screens/transactions_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _index = widget.initialIndex;

  void _openProfile() {
    Navigator.of(context).pushNamed(AppRoutes.profile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: _buildPage(_index),
      ),
      bottomNavigationBar: _MunicipalityBottomNavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 18, 12, 20),
            children: [
              const ListTile(
                title: Text(
                  'إدارة الخدمات',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('الملف الشخصي'),
                onTap: () {
                  Navigator.pop(context);
                  _openProfile();
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('الإعدادات'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          SettingsScreen(onOpenProfile: _openProfile),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return HomeScreen(
          onOpenProfile: _openProfile,
          onOpenComplaints: () => setState(() => _index = 2),
          onOpenTransactions: () => setState(() => _index = 1),
          onOpenNews: () => setState(() => _index = 3),
        );
      case 1:
        return const TransactionsScreen();
      case 2:
        return const ComplaintsScreen();
      case 3:
        return const NewsScreen();
      case 4:
        return SettingsScreen(onOpenProfile: _openProfile);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _MunicipalityBottomNavigationBar extends StatelessWidget {
  const _MunicipalityBottomNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final navigationTheme = NavigationBarThemeData(
      height: 75,
      backgroundColor: AppColors.background,
      elevation: 0,
      indicatorColor: const Color(0xFF002A1C),
      indicatorShape: const StadiumBorder(),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: MaterialStateProperty.resolveWith((states) {
        final selected = states.contains(MaterialState.selected);
        return IconThemeData(
          color: selected ? const Color(0xFF6C9380) : const Color(0xFF414844),
          size: selected ? 22 : 24,
        );
      }),
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        final selected = states.contains(MaterialState.selected);
        return TextStyle(
          color: selected ? const Color(0xFF00120A) : const Color(0xFF414844),
          fontSize: selected ? 11 : 10,
          height: 1.45,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w400,
        );
      }),
    );

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 512),
          child: Container(
            height: 77,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: const Color(0x4DC1C8C2),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2600120A),
                  blurRadius: 32,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Theme(
                data: Theme.of(context).copyWith(
                  navigationBarTheme: navigationTheme,
                ),
                child: NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.home_outlined),
                      selectedIcon: const Icon(Icons.home_rounded),
                      label: context.tr('الرئيسية'),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.receipt_long_outlined),
                      selectedIcon: const Icon(Icons.receipt_long_rounded),
                      label: context.tr('المعاملات'),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      selectedIcon: const Icon(Icons.chat_bubble_rounded),
                      label: context.tr('الشكاوى'),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.newspaper_outlined),
                      selectedIcon: const Icon(Icons.newspaper_rounded),
                      label: context.tr('الأخبار'),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.settings_outlined),
                      selectedIcon: const Icon(Icons.settings_rounded),
                      label: context.tr('الإعدادات'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
