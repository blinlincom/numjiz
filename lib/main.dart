import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'database/database_helper.dart';
import 'screens/home_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/plates_screen.dart';
import 'screens/expense_types_screen.dart';
import 'screens/daily_report_screen.dart';
import 'widgets/app_logo.dart';
import 'utils/responsive.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NiuMaApp());
}

/// 启动页 - 初始化数据库期间显示品牌 Logo，避免白屏
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await DatabaseHelper.ensureInit();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainPage(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.headerGradient,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogo(size: 100, rounded: true),
              const SizedBox(height: 24),
              const Text('牛马记账', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 1)),
              const SizedBox(height: 8),
              Text('司机费用管理', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
              const SizedBox(height: 40),
              SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NiuMaApp extends StatelessWidget {
  const NiuMaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '牛马记账',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashPage(),
      routes: {
        '/plates': (context) => const PlatesScreen(),
        '/expense_types': (context) => const ExpenseTypesScreen(),
        '/daily_report': (context) => const DailyReportScreen(),
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // 侧边导航栏
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onTabChanged,
              extended: MediaQuery.of(context).size.width > 1300,
              minWidth: 72,
              backgroundColor: Colors.white,
              elevation: 4,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    const AppLogo(size: 48),
                    const SizedBox(height: 8),
                    const Text('牛马记账', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  ],
                ),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: IconButton(
                      icon: const Icon(Icons.directions_car_rounded),
                      tooltip: '车牌管理',
                      onPressed: () => Navigator.pushNamed(context, '/plates'),
                    ),
                  ),
                ),
              ),
              indicatorColor: AppTheme.primaryColor.withValues(alpha: 0.12),
              selectedIconTheme: const IconThemeData(color: AppTheme.primaryColor),
              unselectedIconTheme: const IconThemeData(color: AppTheme.textSecondary),
              selectedLabelTextStyle: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.home_rounded), label: Text('首页')),
                NavigationRailDestination(icon: Icon(Icons.bar_chart_rounded), label: Text('统计')),
              ],
            ),
            const VerticalDivider(width: 1, thickness: 1, color: AppTheme.dividerColor),
            // 主内容区
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: const [HomeScreen(), StatsScreen()],
              ),
            ),
          ],
        ),
      );
    }

    // 手机/平板：底部导航
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        children: const [HomeScreen(), StatsScreen()],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, '首页'),
                  _buildNavItem(1, Icons.bar_chart_rounded, Icons.bar_chart, '统计'),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/daily_report'),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.summarize_rounded, color: AppTheme.textSecondary, size: 22),
                          const SizedBox(height: 2),
                          Text('日报', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/expense_types'),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.category_rounded, color: AppTheme.textSecondary, size: 22),
                          const SizedBox(height: 2),
                          Text('分类', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/plates'),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.directions_car_rounded, color: AppTheme.textSecondary, size: 22),
                          const SizedBox(height: 2),
                          Text('车牌', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData icon, String label) {
    final selected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabChanged(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: selected ? 20 : 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? activeIcon : icon, color: selected ? AppTheme.primaryColor : AppTheme.textSecondary, size: 24),
            if (selected) ...[
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ],
        ),
      ),
    );
  }
}