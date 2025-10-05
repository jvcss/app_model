import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppPage {
  home,
  dashboard,
}

final navigationsProvider = StateNotifierProvider<NavigationProvider, AppPage>(
  (ref) => NavigationProvider(),
);

class NavigationProvider extends StateNotifier<AppPage> {
  NavigationProvider() : super(AppPage.home);

  void navigateTo(AppPage page) {
    state = page;
  }
} 