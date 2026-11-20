import 'package:go_router/go_router.dart';

import '../features/comparison/comparison_screen.dart';
import '../features/explorer/presentation/explorer_screen.dart';

GoRouter buildRouter() {
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const ExplorerScreen()),
      GoRoute(
        path: '/compare',
        builder: (context, state) => ComparisonScreen(
          initialIds: state.uri.queryParameters['ids'] ?? '',
        ),
      ),
    ],
  );
}
