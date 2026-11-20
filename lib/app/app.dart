import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../data/catalogue_repository.dart';
import '../domain/models/catalogue.dart';
import '../domain/services/search_index.dart';
import '../features/comparison/comparison_cubit.dart';
import '../features/explorer/application/catalogue_cubit.dart';
import '../features/explorer/application/explorer_bloc.dart';
import '../features/explorer/presentation/detail_focus.dart';
import '../features/search/search_cubit.dart';
import '../features/theme/theme_cubit.dart';
import '../features/validation/validation_panel.dart';
import '../graph/interaction/viewport_controller.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class ThesisApp extends StatefulWidget {
  const ThesisApp({super.key});

  @override
  State<ThesisApp> createState() => _ThesisAppState();
}

class _ThesisAppState extends State<ThesisApp> {
  late final CatalogueRepository _repository = CatalogueRepository();
  late final GoRouter _router = buildRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => ComparisonCubit()),
        BlocProvider(create: (_) => CatalogueCubit(_repository)..load()),
      ],
      child: WidgetsApp.router(
        title: 'Thesis Topic Explorer',
        color: const Color(0xFF2B4C7E),
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
        localizationsDelegates: FLocalizations.localizationsDelegates,
        supportedLocales: FLocalizations.supportedLocales,
        builder: (context, child) =>
            _NotebookShell(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}

class _NotebookShell extends StatelessWidget {
  const _NotebookShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brightness = context.watch<ThemeCubit>().resolve(
      MediaQuery.platformBrightnessOf(context),
    );
    final notebook = brightness == Brightness.dark
        ? NotebookColors.dark
        : NotebookColors.light;
    return FTheme(
      data: notebookTheme(brightness),
      child: NotebookScope(
        colors: notebook,
        child: FToaster(
          child: FTooltipGroup(
            child: Builder(
              builder: (context) {
                return DefaultTextStyle(
                  style: context.theme.typography.body.sm.copyWith(
                    color: context.theme.colors.foreground,
                  ),
                  child: BlocBuilder<CatalogueCubit, CatalogueState>(
                    builder: (context, state) {
                      final page = state is CatalogueLoaded
                          ? _LoadedScope(
                              catalogue: state.catalogue,
                              child: child,
                            )
                          : child;
                      return Stack(
                        children: [
                          page,
                          if (state is CatalogueLoading)
                            const Positioned.fill(
                              child: ColoredBox(
                                color: Color(0xFFFFFFFF),
                                child: Center(child: Text('Loading catalogue')),
                              ),
                            ),
                          if (state is CatalogueFailed)
                            Positioned.fill(
                              child: FailedCatalogueScreen(
                                message: state.message,
                                issues: state.issues,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadedScope extends StatefulWidget {
  const _LoadedScope({required this.catalogue, required this.child});

  final Catalogue catalogue;
  final Widget child;

  @override
  State<_LoadedScope> createState() => _LoadedScopeState();
}

class _LoadedScopeState extends State<_LoadedScope> {
  late final ExplorerBloc _explorer = ExplorerBloc(catalogue: widget.catalogue);
  late final SearchCubit _search = SearchCubit(SearchIndex(widget.catalogue));
  late final ViewportController _viewport = ViewportController();
  late final DetailFocus _detail = DetailFocus();

  @override
  void dispose() {
    _explorer.close();
    _search.close();
    _viewport.dispose();
    _detail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _explorer),
        BlocProvider.value(value: _search),
      ],
      child: ViewportScope(
        controller: _viewport,
        child: DetailScope(focus: _detail, child: widget.child),
      ),
    );
  }
}
