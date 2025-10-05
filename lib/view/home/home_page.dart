import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../services/app_translations.dart';
import 'home_view.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    // o init state acontece apenas uma vez
    super.initState();
    Future.microtask(() => {}); // carregar os dados iniciais
  }

  @override
  Widget build(BuildContext context) {
    //authProvider
    final currentPage = ref.watch(navigationsProvider);
    Widget currentView;

    switch (currentPage) {
      case AppPage.home:
        currentView = const Center(child: HomeView());
        break;
      case AppPage.dashboard:
        currentView = const Center(child: Text('Dashboard View'));
        break;
    }
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('app_title'.tr),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment:
                CrossAxisAlignment.stretch, // <-- make children full width
            children: [
              DrawerHeader(
                margin: EdgeInsets.zero,
                padding: EdgeInsets.zero, // <-- Adicione esta linha
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(
                    16,
                  ),
                  child: Text(
                    'app_title'.tr,
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
              ),
              // Top items scroll here if needed
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.home),
                      title: const Text('Home'),
                      onTap: () {
                        ref
                            .read(navigationsProvider.notifier)
                            .navigateTo(AppPage.home);
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.dashboard),
                      title: const Text('Dashboard'),
                      onTap: () {
                        ref
                            .read(navigationsProvider.notifier)
                            .navigateTo(AppPage.dashboard);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () {
                  ref.read(authProvider.notifier).logout();
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      body: Row(children: [Expanded(child: currentView)]),
    );
  }
}
