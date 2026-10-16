import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_repository.dart';
import '../features/auth/login_screen.dart';
import '../features/dashboard/admin_shell.dart';
import '../features/profile/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/loading',
    refreshListenable: _RefreshOnChange(ref),
    redirect: (context, state) {
      final auth = ref.read(currentAppUserProvider);
      final atLoading = state.matchedLocation == '/loading';
      final atLogin = state.matchedLocation == '/login';

      if (auth.isLoading) return atLogin ? '/loading' : null;

      final user = auth.valueOrNull;
      if (user == null) return atLogin ? null : '/login';
      if (atLoading || atLogin) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/loading', builder: (_, __) => const _AuthLoadingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/home', builder: (_, __) => const AdminShell()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    ],
  );
});

class _RefreshOnChange extends ChangeNotifier {
  _RefreshOnChange(Ref ref) {
    ref.listen(currentAppUserProvider, (_, __) => notifyListeners());
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
