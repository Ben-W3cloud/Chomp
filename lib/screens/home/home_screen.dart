import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/repo_provider.dart';
import '../../services/fcm_service.dart';
import '../../widgets/repo_card.dart';
import '../repo_detail/repo_detail_screen.dart';
import '../insights/insights_screen.dart';
import '../feed/feed_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(repoProvider.notifier).loadFromCache();
      await ref.read(repoProvider.notifier).syncFromGitHub();
      await FcmService().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const _HomeTab(),
      const InsightsScreen(),
      const FeedScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: screens[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.insights_outlined), label: 'Insights'),
          NavigationDestination(
              icon: Icon(Icons.dynamic_feed_outlined), label: 'Feed'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repoState = ref.watch(repoProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Chomp')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(repoProvider.notifier).syncFromGitHub(),
        child: repoState.isLoading && repoState.repos.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: repoState.repos.length,
                itemBuilder: (context, index) {
                  final repo = repoState.repos[index];
                  return RepoCard(
                    repo: repo,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => RepoDetailScreen(repo: repo)),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
