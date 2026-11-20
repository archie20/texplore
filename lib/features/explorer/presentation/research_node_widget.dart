import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/evidence_style.dart';
import '../../../app/theme/stage_style.dart';
import '../../../domain/enums/evidence_status.dart';
import '../../../domain/enums/research_stage.dart';
import '../../../domain/services/graph_queries.dart';
import '../../../domain/services/stage_group.dart';
import '../../../graph/interaction/lattice_motion.dart';
import '../../../graph/layout/layout_node.dart';
import '../../../graph/rendering/node_drift.dart';
import '../application/catalogue_cubit.dart';
import '../application/explorer_bloc.dart';
import '../application/explorer_event.dart';
import '../application/explorer_state.dart';

class ResearchNodeOrb extends StatelessWidget {
  const ResearchNodeOrb({
    required this.nodeId,
    required this.dimmed,
    required this.lit,
    super.key,
  });

  final String nodeId;
  final bool dimmed;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final catalogue = context.read<CatalogueCubit>().state;
    if (catalogue is! CatalogueLoaded) return const SizedBox.shrink();
    final node = catalogue.catalogue.nodes[nodeId];
    final group = StageGroup.parse(nodeId);
    if (node == null && group == null) return const SizedBox.shrink();
    final candidateId = node?.candidateId ?? group!.candidateId;
    final stage = node?.stage ?? group!.stage;
    final candidateIndex = catalogue.catalogue.candidates.indexWhere(
      (candidate) => candidate.id == candidateId,
    );
    final caption = node?.title ?? StageStyle.of(stage).label;
    return BlocSelector<
      ExplorerBloc,
      ExplorerState,
      ({bool selected, bool expanded, bool canExpand})
    >(
      selector: (state) {
        final placed = state.layout.nodeById(nodeId);
        return (
          selected: state.selectedNodeId == nodeId,
          expanded: state.expandedIds.contains(nodeId),
          canExpand: (placed?.childCount ?? 0) > 0,
        );
      },
      builder: (context, flags) {
        final orb = _OrbBody(
          id: nodeId,
          stage: stage,
          caption: caption,
          semanticsLabel: node == null
              ? '${StageStyle.of(stage).label}. ${flags.expanded ? 'Expanded.' : 'Collapsed.'}'
              : '${StageStyle.of(stage).label}. ${node.title}. ${node.evidenceStatus.label}. '
                    '${flags.canExpand ? (flags.expanded ? 'Expanded.' : 'Collapsed.') : ''}',
          canExpand: flags.canExpand,
          parentId: GraphQueries.canvasParentId(catalogue.catalogue, nodeId),
          evidenceStatus: node?.evidenceStatus,
          notebook: context.notebook,
          tick: context.notebook.tickFor(
            candidateIndex < 0 ? 0 : candidateIndex,
          ),
          selected: flags.selected,
          expanded: flags.expanded,
          dimmed: dimmed,
          lit: lit,
        );
        if (!flags.selected) return orb;
        return _SelectedPulse(child: orb);
      },
    );
  }
}

class _SelectedPulse extends StatefulWidget {
  const _SelectedPulse({required this.child});

  final Widget child;

  @override
  State<_SelectedPulse> createState() => _SelectedPulseState();
}

class _SelectedPulseState extends State<_SelectedPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  var _played = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
      _pulse.value = 0;
      return;
    }
    if (_played) return;
    _played = true;
    _pulse.forward(from: 0).whenComplete(() {
      if (mounted) _pulse.reverse();
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final scale = 1 + _pulse.value * 0.08;
        return Transform.scale(
          scale: scale,
          filterQuality: FilterQuality.low,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _OrbBody extends StatefulWidget {
  const _OrbBody({
    required this.id,
    required this.stage,
    required this.caption,
    required this.semanticsLabel,
    required this.canExpand,
    required this.parentId,
    required this.evidenceStatus,
    required this.notebook,
    required this.tick,
    required this.selected,
    required this.expanded,
    required this.dimmed,
    required this.lit,
  });

  final String id;
  final ResearchStage stage;
  final String caption;
  final String semanticsLabel;
  final bool canExpand;
  final String? parentId;
  final EvidenceStatus? evidenceStatus;
  final NotebookColors notebook;
  final Color tick;
  final bool selected;
  final bool expanded;
  final bool dimmed;
  final bool lit;

  @override
  State<_OrbBody> createState() => _OrbBodyState();
}

class _OrbBodyState extends State<_OrbBody> {
  var _hover = false;
  var _keyboard = false;

  @override
  Widget build(BuildContext context) {
    final stage = StageStyle.of(widget.stage);
    final border = widget.evidenceStatus == null
        ? EvidenceBorder.solid
        : evidenceBorderFor(widget.evidenceStatus!);
    final diameter = LatticeMetrics.diameterFor(widget.stage);
    final problem = widget.stage == ResearchStage.thesisProblem;
    final faded = widget.evidenceStatus == EvidenceStatus.superseded;
    final label = widget.semanticsLabel;
    final ring = widget.selected
        ? widget.notebook.ink
        : widget.lit
        ? Color.lerp(widget.tick, widget.notebook.ink, 0.45)!
        : widget.tick;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final emphasis = widget.selected
        ? LatticeMetrics.selectedScale
        : _keyboard
        ? 1.09
        : _hover
        ? 1.07
        : 1.0;
    final life = reduced ? null : LifeClock.motionOf(context);
    return Opacity(
      opacity: (widget.dimmed ? 0.32 : 1) * (faded ? 0.5 : 1),
      child: Semantics(
        button: true,
        label: label,
        expanded: widget.canExpand ? widget.expanded : null,
        selected: widget.selected,
        child: _OrbFocus(
          ring: widget.notebook.ink,
          onKey: (event) => _onKey(context, event),
          onFocused: (focused) {
            if (_keyboard == focused) return;
            setState(() => _keyboard = focused);
          },
          child: MouseRegion(
            onEnter: (_) => setState(() => _hover = true),
            onExit: (_) => setState(() => _hover = false),
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) =>
                  LatticeMotionScope.maybeOf(context)?.claimPointer(),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => context.read<ExplorerBloc>().add(
                  NodeSelected(widget.id, centre: true),
                ),
                onPanStart: (details) =>
                    LatticeMotionScope.maybeOf(context)
                        ?.beginDrag(widget.id, details.globalPosition),
                onPanUpdate: (details) =>
                    LatticeMotionScope.maybeOf(context)
                        ?.updateDrag(details.globalPosition),
                onPanEnd: (_) => LatticeMotionScope.maybeOf(context)?.endDrag(),
                onPanCancel: () =>
                    LatticeMotionScope.maybeOf(context)?.endDrag(),
                child: Column(
                  children: [
                    _Drift(
                      life: life,
                      id: widget.id,
                      child: _LivingCircle(
                        life: life,
                        phase: _lifePhase(widget.id),
                        emphasis: emphasis,
                        reduced: reduced,
                        diameter: diameter,
                        ring: CustomPaint(
                          painter: _CirclePainter(
                            fill: Color.alphaBlend(
                              widget.tick.withValues(
                                alpha: widget.selected ? 0.46 : 0.1,
                              ),
                              widget.notebook.card,
                            ),
                            color: ring,
                            strokeWidth: 1.0,
                            dashed:
                                !widget.selected &&
                                border == EvidenceBorder.dashed,
                            dotted:
                                !widget.selected &&
                                border == EvidenceBorder.dotted,
                            glow: widget.selected
                                ? widget.notebook.ink.withValues(alpha: 0.16)
                                : null,
                          ),
                        ),
                        icon: Icon(
                          stage.icon,
                          size: problem ? 20 : 16,
                          color: widget.selected
                              ? widget.notebook.ink
                              : widget.tick,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: reduced
                          ? Duration.zero
                          : const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      height: widget.selected
                          ? LatticeMetrics.selectedDrop(widget.stage)
                          : 0,
                    ),
                    Expanded(
                      child: _Drift(
                        life: life,
                        id: widget.id,
                        filterQuality: FilterQuality.medium,
                        child: RepaintBoundary(
                          child: Text(
                            StageGroup.parse(widget.id) != null
                                ? stage.label
                                : widget.caption,
                            textAlign: TextAlign.center,
                            maxLines: problem ? 4 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.theme.typography.body.xs.copyWith(
                              fontSize: widget.selected
                                  ? (problem ? 13 : 12)
                                  : (problem ? 12 : 11),
                              height: 1.15,
                              fontWeight: widget.selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: widget.selected
                                  ? widget.notebook.ink
                                  : context.theme.colors.foreground,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  KeyEventResult _onKey(BuildContext context, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final bloc = context.read<ExplorerBloc>();
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      bloc.add(NodeSelected(widget.id, centre: true));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
        widget.canExpand &&
        !widget.expanded) {
      bloc.add(NodeToggled(widget.id));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (widget.expanded && widget.canExpand) {
        bloc.add(NodeToggled(widget.id));
      } else if (widget.parentId != null) {
        bloc.add(NodeSelected(widget.parentId!, centre: true));
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}

class _OrbFocus extends StatefulWidget {
  const _OrbFocus({
    required this.ring,
    required this.onKey,
    required this.onFocused,
    required this.child,
  });

  final Color ring;
  final KeyEventResult Function(KeyEvent event) onKey;
  final ValueChanged<bool> onFocused;
  final Widget child;

  @override
  State<_OrbFocus> createState() => _OrbFocusState();
}

class _OrbFocusState extends State<_OrbFocus> {
  var _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      includeSemantics: false,
      onFocusChange: (focused) {
        setState(() => _focused = focused);
        widget.onFocused(focused);
      },
      onKeyEvent: (node, event) => widget.onKey(event),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: _focused ? Border.all(color: widget.ring, width: 2) : null,
        ),
        child: widget.child,
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  const _CirclePainter({
    required this.fill,
    required this.color,
    required this.strokeWidth,
    required this.dashed,
    required this.dotted,
    required this.glow,
  });

  final Color fill;
  final Color color;
  final double strokeWidth;
  final bool dashed;
  final bool dotted;
  final Color? glow;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - strokeWidth;
    final glowColor = glow;
    if (glowColor != null) {
      canvas.drawCircle(
        center,
        radius + 4,
        Paint()
          ..color = glowColor
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
      );
    }
    canvas.drawCircle(center, radius, Paint()..color = fill);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;
    if (!dashed && !dotted) {
      // A solid ring looks the same at every angle. One stretch of this
      // same stroke is lighter, so the turn is visible as the circle rotates.
      final bounds = Rect.fromCircle(center: center, radius: radius);
      final light = Color.lerp(color, const Color(0xFFFFFFFF), 0.82)!;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..shader = SweepGradient(
            colors: [light, color, color, light],
            stops: const [0.0, 0.16, 0.84, 1.0],
          ).createShader(bounds),
      );
    } else {
      final path = Path()
        ..addOval(Rect.fromCircle(center: center, radius: radius));
      final dash = dotted ? 1.6 : 5.0;
      final gap = dotted ? 3.0 : 3.5;
      for (final metric in path.computeMetrics()) {
        var distance = 0.0;
        while (distance < metric.length) {
          final next = distance + dash < metric.length
              ? distance + dash
              : metric.length;
          canvas.drawPath(metric.extractPath(distance, next), paint);
          distance = next + gap;
        }
      }
    }
  }

  @override
  bool shouldRepaint(_CirclePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.fill != fill ||
        oldDelegate.dashed != dashed ||
        oldDelegate.dotted != dotted ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.glow != glow;
  }
}

/// One shared clock so every circle can drift without its own ticker.
class LifeClock extends InheritedWidget {
  const LifeClock({
    required this.motion,
    required this.seconds,
    required super.child,
    super.key,
  });

  final Animation<double> motion;
  final double Function() seconds;

  static Animation<double>? motionOf(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<LifeClock>();
    final scope = element?.widget;
    return scope is LifeClock ? scope.motion : null;
  }

  static double Function() secondsOf(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<LifeClock>();
    final scope = element?.widget;
    return scope is LifeClock ? scope.seconds : () => 0;
  }

  @override
  bool updateShouldNotify(LifeClock oldWidget) => motion != oldWidget.motion;
}

double _lifePhase(String id) {
  var hash = 2166136261;
  for (final unit in id.codeUnits) {
    hash ^= unit;
    hash = (hash * 16777619) & 0x7fffffff;
  }
  return (hash % 997) / 997;
}

class _Drift extends StatelessWidget {
  const _Drift({
    required this.life,
    required this.id,
    required this.child,
    this.filterQuality = FilterQuality.low,
  });

  final Animation<double>? life;
  final String id;
  final Widget child;
  final FilterQuality filterQuality;

  @override
  Widget build(BuildContext context) {
    final motion = life;
    if (motion == null) return child;
    final seconds = LifeClock.secondsOf(context);
    return AnimatedBuilder(
      animation: motion,
      builder: (context, cached) {
        final drift = NodeDrift.at(id, seconds());
        return Transform(
          alignment: Alignment.center,
          filterQuality: filterQuality,
          transform: Matrix4.identity()
            ..translateByDouble(drift.dx, drift.dy, 0, 1),
          child: cached,
        );
      },
      child: child,
    );
  }
}

class _LivingCircle extends StatelessWidget {
  const _LivingCircle({
    required this.life,
    required this.phase,
    required this.emphasis,
    required this.reduced,
    required this.diameter,
    required this.ring,
    required this.icon,
  });

  final Animation<double>? life;
  final double phase;
  final double emphasis;
  final bool reduced;
  final double diameter;
  final Widget ring;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    // The ring is one layer and the icon is another. Only the ring turns.
    final motion = life;
    final circle = SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        fit: StackFit.expand,
        children: [
          motion == null
              ? ring
              : AnimatedBuilder(
                  animation: motion,
                  builder: (context, cached) {
                    return Transform.rotate(
                      angle: (motion.value + phase) * math.pi * 2,
                      filterQuality: FilterQuality.low,
                      child: cached,
                    );
                  },
                  child: RepaintBoundary(child: ring),
                ),
          RepaintBoundary(child: Center(child: icon)),
        ],
      ),
    );
    return AnimatedScale(
      scale: emphasis,
      alignment: Alignment.center,
      filterQuality: FilterQuality.low,
      duration: reduced ? Duration.zero : const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      child: circle,
    );
  }
}
