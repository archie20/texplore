import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_theme.dart';
import '../../../domain/enums/research_stage.dart';
import '../../../domain/models/catalogue.dart';
import '../../../domain/services/graph_queries.dart';
import '../../../graph/interaction/lattice_motion.dart';
import '../../../graph/interaction/viewport_controller.dart';
import '../../../graph/layout/edge_router.dart';
import '../../../graph/layout/layout_node.dart';
import '../../../graph/rendering/edge_painter.dart';
import '../application/catalogue_cubit.dart';
import '../application/explorer_bloc.dart';
import '../application/explorer_state.dart';
import 'node_popup.dart';
import 'research_node_widget.dart';

class ResearchCanvas extends StatefulWidget {
  const ResearchCanvas({super.key});

  @override
  State<ResearchCanvas> createState() => ResearchCanvasState();
}

class ResearchCanvasState extends State<ResearchCanvas>
    with TickerProviderStateMixin {
  final GlobalKey _viewportKey = GlobalKey();
  late final AnimationController _motion;
  late final AnimationController _flow;
  late final AnimationController _life;
  var _lifeSeconds = 0.0;
  var _lifeSample = 0.0;
  var _drift = true;
  Matrix4 _from = Matrix4.identity();
  Matrix4 _to = Matrix4.identity();
  Size _flightViewport = Size.zero;
  String? _flowToken;
  ViewportController? _viewport;
  LatticeMotion? _lattice;

  ViewportController get _viewportController =>
      _viewport ?? ViewportScope.of(context);

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 880),
    );
    _flow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _life = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 14500),
    );
    _life.addListener(_advanceLife);
    _life.repeat();
    _motion.addListener(() {
      final viewport = _viewport;
      if (viewport == null || _flightViewport.isEmpty) return;
      final t = Curves.easeOutCubic.transform(_motion.value);
      viewport.transformation.value = ViewportController.interpolateView(
        from: _from,
        to: _to,
        t: t,
        viewport: _flightViewport,
      );
      viewport.reportFlight(t);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = ViewportScope.of(context);
    if (!identical(next, _viewport)) {
      _viewport?.removeListener(_onViewportRequest);
      _viewport = next;
      next.addListener(_onViewportRequest);
    }
    final reduced = MediaQuery.disableAnimationsOf(context);
    _drift = !reduced;
    if (reduced) {
      _flow.stop();
      _flow.value = 0;
      _life.stop();
      _life.value = 0;
    } else {
      if (!_life.isAnimating) _life.repeat();
      final token = _flowToken;
      if (token != null && token.isNotEmpty && !_flow.isAnimating) {
        _flow.repeat();
      }
    }
    _bindLattice();
  }

  void _bindLattice() {
    final motion = LatticeMotionScope.maybeOf(context);
    if (!identical(motion, _lattice)) {
      _lattice?.unbind();
      _lattice = motion;
      motion?.bind(this);
    }
    final transform = _viewport?.transformation;
    if (transform != null) _lattice?.attach(transform);
    _lattice?.reducedMotion = MediaQuery.disableAnimationsOf(context);
  }

  @override
  void dispose() {
    _lattice?.unbind();
    _lattice = null;
    _viewport?.removeListener(_onViewportRequest);
    _motion.dispose();
    _flow.dispose();
    _life.dispose();
    super.dispose();
  }

  void _onViewportRequest() {
    final target = _viewport?.takeTarget();
    if (target == null || !mounted) return;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final size = _viewportKey.currentContext?.size ?? Size.zero;
    if (reduced || size.isEmpty) {
      _viewportController.transformation.value = target;
      _viewportController.reportFlight(1);
      return;
    }
    _from = _viewportController.transformation.value.clone();
    _to = target;
    _flightViewport = size;
    final scaleDelta = (_to.getMaxScaleOnAxis() - _from.getMaxScaleOnAxis())
        .abs();
    final pan =
        (ViewportController.sceneAtCenter(_to, size) -
                ViewportController.sceneAtCenter(_from, size))
            .distance *
        ((_from.getMaxScaleOnAxis() + _to.getMaxScaleOnAxis()) / 2);
    final milliseconds = (380 + scaleDelta * 160 + pan * 0.18)
        .clamp(450, 700)
        .round();
    _motion.duration = Duration(milliseconds: milliseconds);
    _viewportController.reportFlight(0);
    _motion.forward(from: 0);
  }

  void _syncFlow(Set<String> highlighted) {
    final token = (highlighted.toList()..sort()).join('|');
    if (token == _flowToken) return;
    _flowToken = token;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _flowToken != token) return;
      if (MediaQuery.disableAnimationsOf(context) || token.isEmpty) {
        _flow.stop();
        _flow.value = 0;
        return;
      }
      _flow.repeat();
    });
  }

  Size? viewportSize() => _viewportKey.currentContext?.size;

  void _advanceLife() {
    final value = _life.value;
    var delta = value - _lifeSample;
    if (delta < -0.5) delta += 1;
    if (delta < 0) delta = 0;
    _lifeSample = value;
    final cycle = (_life.duration ?? Duration.zero).inMicroseconds / 1000000;
    _lifeSeconds += delta * cycle;
  }

  double _readLifeSeconds() => _lifeSeconds;

  @override
  Widget build(BuildContext context) {
    final notebook = context.notebook;
    return LifeClock(
      motion: _life,
      seconds: _readLifeSeconds,
      child: ColoredBox(
        color: notebook.canvas,
        child: Stack(
          key: _viewportKey,
          children: [
            Positioned.fill(
              child: CustomPaint(painter: DotGridPainter(color: notebook.dot)),
            ),
            BlocBuilder<ExplorerBloc, ExplorerState>(
              buildWhen: (previous, next) =>
                  previous.layout != next.layout ||
                  previous.selectedNodeId != next.selectedNodeId ||
                  previous.selectedCandidateId != next.selectedCandidateId ||
                  previous.inspectorOpen != next.inspectorOpen ||
                  previous.filters.showLiterature !=
                      next.filters.showLiterature ||
                  previous.dimmedIds != next.dimmedIds,
              builder: (context, state) {
                final catalogue = context.read<CatalogueCubit>().state;
                final loaded = catalogue is CatalogueLoaded
                    ? catalogue.catalogue
                    : null;
                final edges = [
                  ...state.layout.edges,
                  if (loaded != null && state.filters.showLiterature)
                    ..._literatureEdges(loaded, state.layout),
                ];
                final route = loaded == null || state.selectedNodeId == null
                    ? const <String>{}
                    : GraphQueries.routeIds(loaded, state.selectedNodeId!);
                final highlighted =
                    loaded == null || state.selectedNodeId == null
                    ? const <String>{}
                    : GraphQueries.focusIds(loaded, state.selectedNodeId!);
                // One semantics node for the lattice. Hundreds of circle nodes inside
                // the transform trip a Flutter semantics assert when the window resizes.
                // The outline and the popup carry the readable names.
                final lattice = _lattice;
                lattice?.sync(state.layout);
                _syncFlow(route);
                final world = _worldSize(
                  state.layout,
                  lattice,
                  speakerId: state.inspectorOpen ? state.selectedNodeId : null,
                );
                final departing =
                    lattice?.departingNodes ?? const <LayoutNode>[];
                final orbs = <String, Widget>{
                  for (final node in [...state.layout.nodes, ...departing])
                    node.id: ResearchNodeOrb(
                      key: ValueKey('node-${node.id}'),
                      nodeId: node.id,
                      dimmed: state.dimmedIds.contains(node.id),
                      lit: highlighted.contains(node.id),
                    ),
                };
                return Semantics(
                  container: true,
                  label: 'Research lattice',
                  child: ExcludeSemantics(
                    child: InteractiveViewer(
                      key: lattice?.viewerKey,
                      transformationController:
                          _viewportController.transformation,
                      constrained: false,
                      alignment: Alignment.topLeft,
                      minScale: ViewportController.minScale,
                      maxScale: ViewportController.maxScale,
                      boundaryMargin: const EdgeInsets.all(2400),
                      child: SizedBox(
                        width: world.width,
                        height: world.height,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            if (lattice == null)
                              CustomPaint(
                                size: world,
                                painter: EdgePainter(
                                  edges: edges,
                                  edgeColor: notebook.edge,
                                  mutedColor: notebook.edgeMuted,
                                  accentColor: notebook.ink,
                                  highlighted: highlighted,
                                  route: route,
                                  flow: _flow,
                                  offset: _canvasShift,
                                  driftSeconds: _drift
                                      ? _readLifeSeconds
                                      : null,
                                  repaint: Listenable.merge([_flow, _life]),
                                ),
                              )
                            else
                              AnimatedBuilder(
                                animation: lattice,
                                builder: (context, _) {
                                  return Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      CustomPaint(
                                        size: world,
                                        painter: EdgePainter(
                                          edges: lattice.follow(edges),
                                          edgeColor: notebook.edge,
                                          mutedColor: notebook.edgeMuted,
                                          accentColor: notebook.ink,
                                          highlighted: highlighted,
                                          route: route,
                                          flow: _flow,
                                          offset: _canvasShift,
                                          driftSeconds: _drift
                                              ? _readLifeSeconds
                                              : null,
                                          repaint: Listenable.merge([
                                            _flow,
                                            _life,
                                          ]),
                                        ),
                                      ),
                                      for (final node in [
                                        ...state.layout.nodes,
                                        for (final node
                                            in lattice.departingNodes)
                                          if (state.layout.nodeById(node.id) ==
                                                  null &&
                                              orbs.containsKey(node.id))
                                            node,
                                      ])
                                        Positioned(
                                          key: ValueKey('position-${node.id}'),
                                          left: _childOf(lattice.topLeft(node))
                                              .dx,
                                          top: _childOf(lattice.topLeft(node))
                                              .dy,
                                          width: node.width,
                                          height: _nodeHeight(
                                            node,
                                            state.selectedNodeId,
                                          ),
                                          child: _ArrivingOrb(
                                            presence: lattice.presence(node.id),
                                            child: orbs[node.id]!,
                                          ),
                                        ),
                                      for (final band in state.layout.bands)
                                        if (band.banner != null)
                                          _BandLabel(
                                            band: band,
                                            layout: state.layout,
                                            lattice: lattice,
                                            color: notebook.banner,
                                            style: context
                                                .theme
                                                .typography
                                                .body
                                                .xs,
                                          ),
                                      CircleSpeech(
                                        state: state,
                                        originOf: lattice.topLeft,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            if (lattice == null)
                              for (final node in state.layout.nodes)
                                Positioned(
                                  key: ValueKey('position-${node.id}'),
                                  left: node.x + ViewportController.canvasPad,
                                  top: node.y + ViewportController.canvasPad,
                                  width: node.width,
                                  height: _nodeHeight(
                                    node,
                                    state.selectedNodeId,
                                  ),
                                  child: orbs[node.id]!,
                                ),
                            if (lattice == null)
                              CircleSpeech(
                                state: state,
                                originOf: (node) => Offset(node.x, node.y),
                              ),
                            if (lattice == null)
                              for (final band in state.layout.bands)
                                if (band.banner != null)
                                  Positioned(
                                    left: 48 + ViewportController.canvasPad,
                                    top:
                                        band.top -
                                        28 +
                                        ViewportController.canvasPad,
                                    child: Text(
                                      band.banner!,
                                      style: context.theme.typography.body.xs
                                          .copyWith(
                                            color: notebook.banner,
                                            letterSpacing: 0.4,
                                          ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BandLabel extends StatelessWidget {
  const _BandLabel({
    required this.band,
    required this.layout,
    required this.lattice,
    required this.color,
    required this.style,
  });

  final CandidateBand band;
  final GraphLayout layout;
  final LatticeMotion lattice;
  final Color color;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    LayoutNode? root;
    for (final node in layout.nodes) {
      if (node.candidateId == band.candidateId &&
          node.stage == ResearchStage.thesisProblem) {
        root = node;
        break;
      }
    }
    final origin = root == null ? Offset(48, band.top) : lattice.topLeft(root);
    final child = _childOf(origin);
    return Positioned(
      left: child.dx,
      top: child.dy - 22,
      child: Text(
        band.banner!,
        style: style.copyWith(color: color, letterSpacing: 0.4),
      ),
    );
  }
}

const _canvasShift = Offset(
  ViewportController.canvasPad,
  ViewportController.canvasPad,
);

Offset _childOf(Offset scene) => ViewportController.childPoint(scene);

double _nodeHeight(LayoutNode node, String? selectedId) {
  final drop = selectedId == node.id
      ? LatticeMetrics.selectedDrop(node.stage)
      : 0.0;
  return LatticeMetrics.heightFor(node.stage) + drop;
}

/// The viewer child has to contain every circle, including ones that rest
/// above or left of the layout. [ViewportController.canvasPad] is empty room
/// on each side so a drag still lands inside the hit-tested box.
Size _worldSize(
  GraphLayout layout,
  LatticeMotion? lattice, {
  String? speakerId,
}) {
  var right = layout.width;
  var bottom = layout.height;
  void include(Offset topLeft, LayoutNode node) {
    right = math.max(right, topLeft.dx + node.width);
    bottom = math.max(
      bottom,
      topLeft.dy + LatticeMetrics.heightFor(node.stage),
    );
    if (node.id != speakerId) return;
    final centerX = topLeft.dx + node.width / 2;
    right = math.max(right, centerX + 130);
    bottom = math.max(
      bottom,
      topLeft.dy +
          LatticeMetrics.heightFor(node.stage) +
          LatticeMetrics.selectedDrop(node.stage) +
          520,
    );
  }

  for (final node in layout.nodes) {
    include(lattice?.topLeft(node) ?? Offset(node.x, node.y), node);
  }
  for (final node in lattice?.departingNodes ?? const <LayoutNode>[]) {
    if (layout.nodeById(node.id) != null) continue;
    include(lattice!.topLeft(node), node);
  }
  const pad = ViewportController.canvasPad;
  return Size(math.max(right, 1) + pad * 2, math.max(bottom, 1) + pad * 2);
}

List<RoutedEdge> _literatureEdges(Catalogue catalogue, GraphLayout layout) {
  const router = EdgeRouter();
  final byPublication = <String, List<String>>{};
  for (final link in catalogue.evidenceLinks.values) {
    byPublication.putIfAbsent(link.publicationId, () => []).add(link.nodeId);
  }
  final edges = <RoutedEdge>[];
  for (final entry in byPublication.entries) {
    final placed = [
      for (final id in entry.value.toSet())
        if (layout.nodeById(id) != null) layout.nodeById(id)!,
    ];
    if (placed.length < 2) continue;
    for (final other in placed.skip(1)) {
      edges.add(
        router.cross('lit-${entry.key}-${other.id}', placed.first, other),
      );
    }
  }
  return edges;
}

class _ArrivingOrb extends StatelessWidget {
  const _ArrivingOrb({required this.presence, required this.child});

  final double presence;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shown = presence.clamp(0.0, 1.0);
    return IgnorePointer(
      ignoring: shown < 0.98,
      child: Opacity(
        opacity: shown,
        child: Transform.scale(
          scale: 0.2 + 0.8 * shown,
          alignment: Alignment.topCenter,
          child: child,
        ),
      ),
    );
  }
}
