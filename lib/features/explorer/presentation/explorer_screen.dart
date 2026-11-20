import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../../app/breakpoints.dart';
import '../../../domain/enums/research_stage.dart';
import '../../../domain/models/catalogue.dart';
import '../../../domain/services/stage_group.dart';
import '../../../graph/interaction/camera_motion.dart';
import '../../../graph/interaction/lattice_motion.dart';
import '../../../graph/interaction/viewport_controller.dart';
import '../../../graph/layout/layout_node.dart';
import '../../comparison/comparison_cubit.dart';
import '../../filters/filter_bar.dart';
import '../../outline/outline_view.dart';
import '../../search/search_palette.dart';
import '../../theme/theme_cubit.dart';
import '../../validation/validation_panel.dart';
import '../application/catalogue_cubit.dart';
import '../application/explorer_bloc.dart';
import '../application/explorer_event.dart';
import '../application/explorer_state.dart';
import 'canvas_toolbar.dart';
import 'minimap.dart';
import 'research_canvas.dart';
import 'url_sync.dart';

class ExplorerScreen extends StatefulWidget {
  const ExplorerScreen({super.key});

  @override
  State<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends State<ExplorerScreen> {
  final _canvasKey = GlobalKey<ResearchCanvasState>();
  final _searchKey = GlobalKey<SearchPaletteState>();
  final _lattice = LatticeMotion();
  var _reportOpen = false;
  var _framed = false;
  String? _cameraFromId;

  @override
  void dispose() {
    _lattice.dispose();
    super.dispose();
  }

  void _frameOnce() {
    if (_framed) return;
    _framed = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyFocus(context.read<ExplorerBloc>().state);
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalogue = context.watch<CatalogueCubit>().state;
    if (catalogue is! CatalogueLoaded) return const SizedBox.shrink();
    _frameOnce();
    final width = MediaQuery.sizeOf(context).width;
    final breakpoint = AppBreakpoint.of(width);
    return LatticeMotionScope(
      motion: _lattice,
      child: ExplorerUrlSync(
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
                _searchKey.currentState?.open(),
            const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
                _searchKey.currentState?.open(),
            const SingleActivator(LogicalKeyboardKey.escape): () =>
                context.read<ExplorerBloc>().add(const InspectorClosed()),
            const SingleActivator(LogicalKeyboardKey.minus): () =>
                _zoom(1 / 1.15),
            const SingleActivator(LogicalKeyboardKey.equal): () => _zoom(1.15),
            const SingleActivator(LogicalKeyboardKey.digit0): _fitAll,
          },
          child: Focus(
            autofocus: true,
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (event) => _lattice.armDismiss(event.position),
              onPointerMove: (event) => _lattice.trackDismiss(event.position),
              onPointerUp: (event) => _dismissPopup(event.position),
              onPointerCancel: (_) => _lattice.cancelDismiss(),
              child: MultiBlocListener(
                listeners: [
                  BlocListener<ExplorerBloc, ExplorerState>(
                    listenWhen: (previous, next) =>
                        previous.focusTick != next.focusTick,
                    listener: (context, state) => _applyFocus(state),
                  ),
                ],
                child: ColoredBox(
                  color: context.theme.colors.background,
                  child: Column(
                    children: [
                      _TopBar(
                        catalogue: catalogue.catalogue,
                        searchKey: _searchKey,
                        mobile: breakpoint.isMobile,
                        reportOpen: _reportOpen,
                        onReport: () =>
                            setState(() => _reportOpen = !_reportOpen),
                      ),
                      if (catalogue.catalogue.excluded.isNotEmpty)
                        _ExclusionBanner(
                          count: catalogue.catalogue.excluded.length,
                          onOpen: () => setState(() => _reportOpen = true),
                        ),
                      Expanded(
                        child: catalogue.catalogue.candidates.isEmpty
                            ? _EmptyCatalogue(
                                catalogue: catalogue.catalogue,
                                report: _reportOpen,
                              )
                            : _Workspace(
                                catalogue: catalogue.catalogue,
                                breakpoint: breakpoint,
                                canvasKey: _canvasKey,
                                reportOpen: _reportOpen,
                                onZoomIn: () => _zoom(1.15),
                                onZoomOut: () => _zoom(1 / 1.15),
                                onFitSelected: _fitSelected,
                                onFitAll: _fitAll,
                                onCloseReport: () =>
                                    setState(() => _reportOpen = false),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _dismissPopup(Offset position) {
    if (!_lattice.takeDismiss(position) || !mounted) return;
    final bloc = context.read<ExplorerBloc>();
    if (bloc.state.inspectorOpen) bloc.add(const InspectorClosed());
  }

  void _zoom(double factor) {
    final size =
        _canvasKey.currentState?.viewportSize() ?? MediaQuery.sizeOf(context);
    ViewportScope.of(context).zoomBy(factor, size);
  }

  void _fitAll() => _applyFocus(
    context.read<ExplorerBloc>().state.copyWith(focusKind: FocusKind.fitAll),
  );

  void _fitSelected() {
    final state = context.read<ExplorerBloc>().state;
    if (state.selectedNodeId != null) {
      _applyFocus(state.copyWith(focusKind: FocusKind.centreNode));
    } else {
      _applyFocus(state.copyWith(focusKind: FocusKind.fitCandidate));
    }
  }

  void _applyFocus(ExplorerState state) {
    final size = _canvasKey.currentState?.viewportSize();
    if (size == null || size.isEmpty) return;
    _lattice.sync(state.layout);
    final viewport = ViewportScope.of(context);
    switch (state.focusKind) {
      case FocusKind.fitAll:
        _cameraFromId = null;
        viewport.fit(
          _bounds(state.layout, {
            for (final node in state.layout.nodes) node.id,
          }, _lattice),
          size,
        );
      case FocusKind.fitCandidate:
        _cameraFromId = null;
        final id = state.selectedCandidateId;
        viewport.fit(
          _holdSpeech(
            _bounds(state.layout, {
              for (final node in state.layout.nodes)
                if (node.candidateId == id) node.id,
            }, _lattice),
            state,
            _lattice,
          ),
          size,
          bottomChrome: _speechChrome,
        );
      case FocusKind.centreNode:
        final nodeId = state.selectedNodeId;
        final node = nodeId == null ? null : state.layout.nodeById(nodeId);
        if (node == null || nodeId == null) return;
        final fromId = _cameraFromId;
        _cameraFromId = nodeId;
        if (node.stage == ResearchStage.thesisProblem &&
            state.expandedIds.contains(nodeId)) {
          viewport.fit(
            _holdSpeech(
              _bounds(
                state.layout,
                {
                  for (final placed in state.layout.nodes)
                    if (placed.candidateId == node.candidateId) placed.id,
                },
                _lattice,
                resting: true,
              ),
              state,
              _lattice,
              resting: true,
            ),
            size,
            bottomChrome: _speechChrome,
          );
          break;
        }
        if (StageGroup.parse(nodeId) != null) {
          viewport.fit(
            _bounds(
              state.layout,
              {
                for (final placed in state.layout.nodes)
                  if (placed.candidateId == node.candidateId &&
                      placed.stage == node.stage)
                    placed.id,
              },
              _lattice,
              resting: true,
            ),
            size,
          );
          break;
        }
        final children = _directChildIds(state.layout, nodeId);
        if (children.isNotEmpty) {
          viewport.fit(
            _bounds(
              state.layout,
              {nodeId, ...children},
              _lattice,
              resting: true,
            ),
            size,
          );
          break;
        }
        final loaded = context.read<CatalogueCubit>().state;
        final current = viewport.transformation.value.getMaxScaleOnAxis();
        final scale = loaded is! CatalogueLoaded
            ? current
            : cameraScale(
                catalogue: loaded.catalogue,
                fromId: fromId,
                toId: nodeId,
                current: current,
              );
        final diameter = LatticeMetrics.diameterFor(node.stage);
        final center = _circleCenter(node);
        final spoken = state.inspectorOpen
            ? center +
                  const Offset(0, 90) +
                  Offset(0, LatticeMetrics.selectedDrop(node.stage))
            : center;
        viewport.focusAt(
          Rect.fromCircle(center: spoken, radius: diameter / 2),
          size,
          scale: scale,
        );
      case FocusKind.zoomOut:
        final nodeId = state.selectedNodeId;
        if (nodeId == null || state.layout.nodeById(nodeId) == null) {
          viewport.fit(
            _bounds(
              state.layout,
              {for (final node in state.layout.nodes) node.id},
              _lattice,
              resting: true,
            ),
            size,
          );
          break;
        }
        final placed = state.layout.nodeById(nodeId);
        if (placed != null &&
            placed.stage == ResearchStage.thesisProblem &&
            state.expandedIds.contains(nodeId)) {
          var rect = _bounds(
            state.layout,
            {
              for (final item in state.layout.nodes)
                if (item.candidateId == placed.candidateId) item.id,
            },
            _lattice,
            resting: true,
          );
          rect = rect.inflate(rect.shortestSide * 0.38);
          _cameraFromId = nodeId;
          viewport.fit(rect, size);
          break;
        }
        if (placed != null && StageGroup.parse(nodeId) != null) {
          var rect = _bounds(
            state.layout,
            {
              for (final item in state.layout.nodes)
                if (item.candidateId == placed.candidateId) item.id,
            },
            _lattice,
            resting: true,
          );
          rect = rect.inflate(rect.shortestSide * 0.22);
          _cameraFromId = nodeId;
          viewport.fit(rect, size);
          break;
        }
        final parentId = _parentIdOf(state.layout, nodeId);
        final children = _directChildIds(state.layout, nodeId);
        if (parentId == null && children.isEmpty) {
          _cameraFromId = null;
          viewport.fit(
            _bounds(
              state.layout,
              {for (final node in state.layout.nodes) node.id},
              _lattice,
              resting: true,
            ),
            size,
          );
          break;
        }
        final focus = parentId ?? nodeId;
        var rect = _bounds(
          state.layout,
          {focus, ..._directChildIds(state.layout, focus)},
          _lattice,
          resting: true,
        );
        if (parentId == null) rect = rect.inflate(rect.shortestSide * 0.38);
        _cameraFromId = nodeId;
        viewport.fit(rect, size);
      case FocusKind.none:
        break;
    }
  }

  /// The canvas toolbar sits on the bottom of the frame. The spoken words
  /// stay above it.
  static const _speechChrome = 96.0;

  /// Keeps the words under a speaking circle inside the framed group.
  Rect _holdSpeech(
    Rect bounds,
    ExplorerState state,
    LatticeMotion motion, {
    bool resting = false,
  }) {
    final speaker = _speakingNode(state);
    if (speaker == null) return bounds;
    final origin = resting
        ? motion.restingTopLeft(speaker)
        : motion.topLeft(speaker);
    const reach = 220.0;
    const half = 130.0;
    final centerX = origin.dx + speaker.width / 2;
    final bottom =
        origin.dy +
        LatticeMetrics.heightFor(speaker.stage) +
        LatticeMetrics.selectedDrop(speaker.stage) +
        reach;
    return Rect.fromLTRB(
      bounds.left < centerX - half ? bounds.left : centerX - half,
      bounds.top,
      bounds.right > centerX + half ? bounds.right : centerX + half,
      bounds.bottom > bottom ? bounds.bottom : bottom,
    );
  }

  LayoutNode? _speakingNode(ExplorerState state) {
    if (!state.inspectorOpen) return null;
    final selected = state.selectedNodeId;
    if (selected != null) {
      if (StageGroup.parse(selected) != null) return null;
      return state.layout.nodeById(selected);
    }
    final candidateId = state.selectedCandidateId;
    if (candidateId == null) return null;
    for (final node in state.layout.nodes) {
      if (node.candidateId == candidateId &&
          node.stage == ResearchStage.thesisProblem) {
        return node;
      }
    }
    return null;
  }

  Offset _circleCenter(LayoutNode node) {
    final topLeft = _lattice.topLeft(node);
    final diameter = LatticeMetrics.diameterFor(node.stage);
    return Offset(topLeft.dx + node.width / 2, topLeft.dy + diameter / 2);
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.catalogue,
    required this.searchKey,
    required this.mobile,
    required this.reportOpen,
    required this.onReport,
  });

  final Catalogue catalogue;
  final GlobalKey<SearchPaletteState> searchKey;
  final bool mobile;
  final bool reportOpen;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final issueCount =
        catalogue.excluded.length +
        catalogue.issues.where((issue) => issue.isError).length;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.theme.colors.border)),
      ),
      child: SizedBox(
        height: 52,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            Center(
              child: Text(
                'Thesis topics',
                style: context.theme.typography.display.sm.copyWith(
                  fontSize: 16,
                ),
              ),
            ),
            if (mobile) ...[
              const SizedBox(width: 8),
              Center(
                child: BlocSelector<ExplorerBloc, ExplorerState, bool>(
                  selector: (state) => state.outlineVisible,
                  builder: (context, visible) => FButton(
                    key: const Key('outline-toggle'),
                    variant: visible ? .secondary : .ghost,
                    size: .sm,
                    onPress: () => context.read<ExplorerBloc>().add(
                      const OutlineToggled(),
                    ),
                    child: Text(visible ? 'Canvas' : 'Outline'),
                  ),
                ),
              ),
            ],
            const SizedBox(width: 12),
            Center(child: _CandidateSelect(catalogue: catalogue)),
            const SizedBox(width: 8),
            Center(child: SearchPalette(key: searchKey)),
            const SizedBox(width: 8),
            const Center(child: FilterBar()),
            const SizedBox(width: 8),
            Center(
              child: FButton(
                variant: .outline,
                size: .sm,
                onPress: () {
                  final ids = context.read<ComparisonCubit>().state.join(',');
                  context.go(ids.isEmpty ? '/compare' : '/compare?ids=$ids');
                },
                child: Text(
                  'Compare (${context.watch<ComparisonCubit>().state.length})',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Center(
              child: FButton(
                variant: reportOpen ? .secondary : .ghost,
                size: .sm,
                onPress: onReport,
                child: Text(
                  issueCount == 0 ? 'Report' : 'Report ($issueCount)',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Center(
              child: FButton(
                variant: .ghost,
                size: .sm,
                onPress: () => context.read<ThemeCubit>().toggle(
                  context.theme.colors.brightness,
                ),
                child: const Text('Theme'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidateSelect extends StatelessWidget {
  const _CandidateSelect({required this.catalogue});

  final Catalogue catalogue;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ExplorerBloc, ExplorerState, String?>(
      selector: (state) => state.selectedCandidateId,
      builder: (context, selected) {
        return SizedBox(
          width: 220,
          child: FSelect<String>(
            size: .sm,
            hint: 'Candidate',
            control: .lifted(
              value: selected,
              onChange: (id) {
                if (id != null)
                  context.read<ExplorerBloc>().add(CandidateSelected(id));
              },
            ),
            items: {
              for (final candidate in catalogue.candidates)
                candidate.shortTitle: candidate.id,
            },
          ),
        );
      },
    );
  }
}

class _ExclusionBanner extends StatelessWidget {
  const _ExclusionBanner({required this.count, required this.onOpen});

  final int count;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final label = count == 1
        ? '1 candidate failed validation'
        : '$count candidates failed validation';
    return GestureDetector(
      onTap: onOpen,
      child: ColoredBox(
        color: context.theme.colors.secondary,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '$label and ${count == 1 ? 'is' : 'are'} not on the canvas. Open the report for the record ids.',
          ),
        ),
      ),
    );
  }
}

class _EmptyCatalogue extends StatelessWidget {
  const _EmptyCatalogue({required this.catalogue, required this.report});

  final Catalogue catalogue;
  final bool report;

  @override
  Widget build(BuildContext context) {
    final message = catalogue.excluded.isEmpty
        ? 'No candidates in the catalogue.'
        : 'Every candidate failed validation, so the canvas is empty.';
    return Row(
      children: [
        Expanded(
          child: Center(
            child: Text(message, style: context.theme.typography.body.md),
          ),
        ),
        if (report)
          SizedBox(width: 360, child: ValidationPanel(catalogue: catalogue)),
      ],
    );
  }
}

class _Workspace extends StatelessWidget {
  const _Workspace({
    required this.catalogue,
    required this.breakpoint,
    required this.canvasKey,
    required this.reportOpen,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFitSelected,
    required this.onFitAll,
    required this.onCloseReport,
  });

  final Catalogue catalogue;
  final AppBreakpoint breakpoint;
  final GlobalKey<ResearchCanvasState> canvasKey;
  final bool reportOpen;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFitSelected;
  final VoidCallback onFitAll;
  final VoidCallback onCloseReport;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExplorerBloc, ExplorerState>(
      buildWhen: (previous, next) =>
          previous.outlineVisible != next.outlineVisible ||
          previous.minimapVisible != next.minimapVisible ||
          previous.layout != next.layout ||
          previous.filters != next.filters,
      builder: (context, state) {
        final canvas = _CanvasStack(
          canvasKey: canvasKey,
          state: state,
          onZoomIn: onZoomIn,
          onZoomOut: onZoomOut,
          onFitSelected: onFitSelected,
          onFitAll: onFitAll,
        );
        final outline = const SizedBox(width: 280, child: OutlineView());
        final showOutline = state.outlineVisible && !breakpoint.isMobile;
        final Widget body = breakpoint.isMobile && state.outlineVisible
            ? const OutlineView()
            : Row(
                children: [
                  if (showOutline) outline,
                  Expanded(child: canvas),
                ],
              );
        return Stack(
          children: [
            body,
            if (reportOpen)
              Positioned(
                top: 12,
                right: 12,
                bottom: 12,
                width: breakpoint.isMobile
                    ? MediaQuery.sizeOf(context).width - 24
                    : 380,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.theme.colors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.theme.colors.border),
                  ),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: FButton(
                          variant: .ghost,
                          size: .xs,
                          onPress: onCloseReport,
                          child: const Text('Close'),
                        ),
                      ),
                      Expanded(child: ValidationPanel(catalogue: catalogue)),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CanvasStack extends StatelessWidget {
  const _CanvasStack({
    required this.canvasKey,
    required this.state,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFitSelected,
    required this.onFitAll,
  });

  final GlobalKey<ResearchCanvasState> canvasKey;
  final ExplorerState state;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFitSelected;
  final VoidCallback onFitAll;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          children: [
            ResearchCanvas(key: canvasKey),
            if (state.layout.nodes.isEmpty)
              Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.theme.colors.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.theme.colors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('No nodes match these filters.'),
                        const SizedBox(height: 8),
                        FButton(
                          variant: .outline,
                          size: .sm,
                          onPress: () => context.read<ExplorerBloc>().add(
                            const FiltersCleared(),
                          ),
                          child: const Text('Clear filters'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Center(
                child: CanvasToolbar(
                  onZoomIn: onZoomIn,
                  onZoomOut: onZoomOut,
                  onFitSelected: onFitSelected,
                  onFitAll: onFitAll,
                ),
              ),
            ),
            if (state.minimapVisible)
              Positioned(
                left: 16,
                bottom: 64,
                child: Minimap(
                  layout: state.layout,
                  viewportSize: viewport,
                  onCentre: (scene) {
                    final size =
                        canvasKey.currentState?.viewportSize() ??
                        MediaQuery.sizeOf(context);
                    ViewportScope.of(context).centreOn(
                      Rect.fromCircle(center: scene, radius: 20),
                      size,
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

Set<String> _directChildIds(GraphLayout layout, String id) {
  return {
    for (final edge in layout.edges)
      if (!edge.crossLink && edge.sourceId == id) edge.targetId,
  };
}

String? _parentIdOf(GraphLayout layout, String id) {
  for (final edge in layout.edges) {
    if (!edge.crossLink && edge.targetId == id) return edge.sourceId;
  }
  return null;
}

Rect _bounds(
  GraphLayout layout,
  Set<String> ids,
  LatticeMotion motion, {
  bool resting = false,
}) {
  final picked = [
    for (final node in layout.nodes)
      if (ids.contains(node.id)) node,
  ];
  if (picked.isEmpty)
    return Rect.fromLTWH(
      0,
      0,
      layout.width <= 0 ? 1 : layout.width,
      layout.height <= 0 ? 1 : layout.height,
    );
  Offset originOf(LayoutNode node) =>
      resting ? motion.restingTopLeft(node) : motion.topLeft(node);
  final first = originOf(picked.first);
  var left = first.dx;
  var top = first.dy;
  var right = first.dx + picked.first.width;
  var bottom = first.dy + LatticeMetrics.heightFor(picked.first.stage);
  for (final node in picked.skip(1)) {
    final origin = originOf(node);
    if (origin.dx < left) left = origin.dx;
    if (origin.dy < top) top = origin.dy;
    if (origin.dx + node.width > right) right = origin.dx + node.width;
    if (origin.dy + LatticeMetrics.heightFor(node.stage) > bottom) {
      bottom = origin.dy + LatticeMetrics.heightFor(node.stage);
    }
  }
  return Rect.fromLTRB(left, top, right, bottom);
}
