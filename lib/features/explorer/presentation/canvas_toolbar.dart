import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import '../../../app/theme/app_theme.dart';
import '../../../graph/interaction/viewport_controller.dart';
import '../application/explorer_bloc.dart';
import '../application/explorer_event.dart';
import '../application/explorer_state.dart';

class CanvasToolbar extends StatelessWidget {
  const CanvasToolbar({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFitSelected,
    required this.onFitAll,
    super.key,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFitSelected;
  final VoidCallback onFitAll;

  @override
  Widget build(BuildContext context) {
    final viewport = ViewportScope.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.theme.colors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.theme.colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Tool('Zoom out', onZoomOut),
              AnimatedBuilder(
                animation: viewport.transformation,
                builder: (context, _) {
                  final percent =
                      (viewport.transformation.value.getMaxScaleOnAxis() * 100)
                          .round();
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      '$percent%',
                      style: context.theme.typography.body.xs.copyWith(
                        fontFamily: monoFamily,
                      ),
                    ),
                  );
                },
              ),
              _Tool('Zoom in', onZoomIn),
              const SizedBox(width: 8),
              _Tool('Fit selected', onFitSelected),
              _Tool('Fit all', onFitAll),
              _Tool(
                'Reset',
                () => context.read<ExplorerBloc>().add(const ViewReset()),
              ),
              BlocSelector<ExplorerBloc, ExplorerState, bool>(
                selector: (state) => state.minimapVisible,
                builder: (context, visible) =>
                    _Tool(visible ? 'Hide map' : 'Map', () {
                      context.read<ExplorerBloc>().add(const MinimapToggled());
                    }),
              ),
              BlocSelector<ExplorerBloc, ExplorerState, bool>(
                selector: (state) => state.outlineVisible,
                builder: (context, visible) =>
                    _Tool(visible ? 'Hide outline' : 'Outline', () {
                      context.read<ExplorerBloc>().add(const OutlineToggled());
                    }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tool extends StatelessWidget {
  const _Tool(this.label, this.onPress);

  final String label;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    return FButton(
      variant: .ghost,
      size: .xs,
      onPress: onPress,
      child: Text(label),
    );
  }
}
