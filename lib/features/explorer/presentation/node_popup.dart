import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/services/stage_group.dart';
import '../../../graph/interaction/lattice_motion.dart';
import '../../../graph/interaction/viewport_controller.dart';
import '../../../graph/layout/layout_node.dart';
import '../application/catalogue_cubit.dart';
import '../application/explorer_state.dart';
import 'node_inspector.dart';

/// The selected circle speaking under its label. There is no second surface.
class CircleSpeech extends StatelessWidget {
  const CircleSpeech({required this.state, required this.originOf, super.key});

  final ExplorerState state;
  final Offset Function(LayoutNode node) originOf;

  @override
  Widget build(BuildContext context) {
    final speaker = _speaker(context, state);
    if (speaker == null) return const SizedBox.shrink();
    final origin = originOf(speaker);
    const width = 236.0;
    final left = origin.dx + speaker.width / 2 - width / 2;
    final top =
        origin.dy +
        LatticeMetrics.heightFor(speaker.stage) +
        LatticeMetrics.selectedDrop(speaker.stage) +
        8;
    final identity =
        state.selectedNodeId ?? state.selectedCandidateId ?? 'speech';
    return Positioned(
      key: const Key('node-popup'),
      left: left + ViewportController.canvasPad,
      top: top + ViewportController.canvasPad,
      width: width,
      child: _Spoken(
        key: ValueKey(identity),
        reduced: MediaQuery.disableAnimationsOf(context),
      ),
    );
  }
}

LayoutNode? _speaker(BuildContext context, ExplorerState state) {
  if (!state.inspectorOpen) return null;
  final selected = state.selectedNodeId;
  if (selected != null) {
    if (StageGroup.parse(selected) != null) return null;
    return state.layout.nodeById(selected);
  }
  final candidateId = state.selectedCandidateId;
  if (candidateId == null) return null;
  final catalogue = context.read<CatalogueCubit>().state;
  if (catalogue is! CatalogueLoaded) return null;
  final root = catalogue.catalogue.candidateById(candidateId)?.rootNodeId;
  if (root == null) return null;
  return state.layout.nodeById(root);
}

class _Spoken extends StatefulWidget {
  const _Spoken({required this.reduced, super.key});

  final bool reduced;

  @override
  State<_Spoken> createState() => _SpokenState();
}

class _SpokenState extends State<_Spoken> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    return _SpeechEntrance(
      reduced: widget.reduced,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) =>
            LatticeMotionScope.maybeOf(context)?.claimPointer(),
        child: InspectorPanel(
          detailOpen: _open,
          onToggle: () => setState(() => _open = !_open),
        ),
      ),
    );
  }
}

class _SpeechEntrance extends StatefulWidget {
  const _SpeechEntrance({required this.reduced, required this.child});

  final bool reduced;
  final Widget child;

  @override
  State<_SpeechEntrance> createState() => _SpeechEntranceState();
}

class _SpeechEntranceState extends State<_SpeechEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  ViewportController? _viewport;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = ViewportScope.of(context);
    if (!identical(next, _viewport)) {
      _viewport?.flight.removeListener(_syncFlight);
      _viewport = next;
      next.flight.addListener(_syncFlight);
    }
    _syncFlight();
  }

  void _syncFlight() {
    if (!mounted) return;
    if (widget.reduced) {
      _entrance.value = 1;
      return;
    }
    final ready = (_viewport?.flight.value ?? 1) >= 0.7;
    if (!ready) {
      if (_entrance.value != 0 || _entrance.isAnimating) _entrance.value = 0;
      return;
    }
    if (!_entrance.isAnimating && _entrance.value == 0) _entrance.forward();
  }

  @override
  void dispose() {
    _viewport?.flight.removeListener(_syncFlight);
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entrance,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_entrance.value);
        return IgnorePointer(
          ignoring: t == 0,
          child: Opacity(opacity: t, child: child),
        );
      },
      child: widget.child,
    );
  }
}
