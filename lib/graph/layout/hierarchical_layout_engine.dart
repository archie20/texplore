import 'dart:math' as math;
import 'dart:ui';

import '../../domain/enums/relationship_type.dart';
import '../../domain/enums/research_stage.dart';
import '../../domain/models/catalogue.dart';
import '../../domain/models/research_node.dart';
import '../../domain/services/graph_queries.dart';
import '../../domain/services/stage_group.dart';
import 'edge_router.dart';
import 'layout_node.dart';
import 'loose_scatter.dart';

class HierarchicalLayoutEngine {
  HierarchicalLayoutEngine({EdgeRouter? router})
    : _router = router ?? const EdgeRouter();

  final EdgeRouter _router;

  static const columnPitch = LatticeMetrics.columnPitch;
  static const nodeHeight = LatticeMetrics.nodeHeight;
  static const rootHeight = LatticeMetrics.rootHeight;
  static const originX = LatticeMetrics.originX;
  static const originY = LatticeMetrics.originY;

  /// Thesis problems stay at the root. Their research stages sit at irregular
  /// distances and gaps around that problem. An open stage's records use that
  /// same irregular placement. They are not set on a ring or a fan. Opening a
  /// stage does not move the other stages.
  GraphLayout layout({
    required Catalogue catalogue,
    required Set<String> visibleIds,
    required Set<String> expandedIds,
  }) {
    final placed = <LayoutNode>[];
    final bands = <CandidateBand>[];
    final edges = <RoutedEdge>[];
    var cursor = LatticeMetrics.originY;
    var sawAlternative = false;

    for (final candidate in catalogue.candidates) {
      final root = catalogue.nodes[candidate.rootNodeId];
      if (root == null || !visibleIds.contains(root.id)) continue;
      final top = cursor;
      final stages = GraphQueries.stagesOf(catalogue, root.candidateId);
      final seats = <_Seat>[
        _Seat(
          id: root.id,
          candidateId: root.candidateId,
          stage: root.stage,
          title: root.title,
          summary: root.summary,
          center: Offset(
            originX + LatticeMetrics.rootWidth / 2,
            top + LatticeMetrics.diameterFor(root.stage) / 2,
          ),
          childCount: stages.length,
          expanded: expandedIds.contains(root.id),
          linkFrom: null,
          drawn: true,
        ),
      ];
      if (expandedIds.contains(root.id)) {
        seats.addAll(
          _scatter(
            catalogue: catalogue,
            root: root,
            stages: stages,
            visibleIds: visibleIds,
            expandedIds: expandedIds,
            problemCenter: seats.first.center,
          ),
        );
      }
      final shifted = _shift(seats, originX, top);
      final byLocal = <String, LayoutNode>{};
      for (final seat in shifted) {
        if (!seat.drawn) continue;
        final node = _atCenter(seat);
        byLocal[node.id] = node;
        placed.add(node);
      }
      for (final seat in shifted) {
        if (!seat.drawn) continue;
        final from = seat.linkFrom;
        if (from == null) continue;
        final source = byLocal[from];
        final target = byLocal[seat.id];
        if (source == null || target == null) continue;
        edges.add(_router.hierarchy(source, target));
      }
      var bottom = top + LatticeMetrics.rootHeight;
      for (final node in byLocal.values) {
        final lower = node.y + node.height;
        if (lower > bottom) bottom = lower;
      }
      final banner =
          !sawAlternative && candidate.priority != CandidatePriority.primary
          ? 'Alternative / exploratory'
          : null;
      if (candidate.priority != CandidatePriority.primary) {
        sawAlternative = true;
      }
      bands.add(
        CandidateBand(
          candidateId: candidate.id,
          top: top,
          bottom: bottom,
          banner: banner,
        ),
      );
      cursor = bottom + LatticeMetrics.candidateGap;
    }

    final byId = {for (final node in placed) node.id: node};
    for (final link in catalogue.crossLinks) {
      final source = byId[link.sourceNodeId];
      final target = byId[link.targetNodeId];
      if (source == null || target == null) continue;
      edges.add(_router.cross(link.id, source, target));
    }

    var width =
        LatticeMetrics.originX + columnPitch * 3 + LatticeMetrics.padding;
    var height = cursor + LatticeMetrics.padding;
    for (final node in placed) {
      final right = node.x + node.width + LatticeMetrics.padding;
      final lower = node.y + node.height + LatticeMetrics.padding;
      if (right > width) width = right;
      if (lower > height) height = lower;
    }
    if (placed.isEmpty) {
      width = 960;
      height = 480;
    }

    return GraphLayout(
      nodes: placed,
      edges: edges,
      bands: bands,
      width: width,
      height: height,
    );
  }

  List<_Seat> _scatter({
    required Catalogue catalogue,
    required ResearchNode root,
    required List<ResearchStage> stages,
    required Set<String> visibleIds,
    required Set<String> expandedIds,
    required Offset problemCenter,
  }) {
    final visible = [
      for (final stage in stages)
        if (visibleIds.contains(StageGroup.idFor(root.candidateId, stage)))
          stage,
    ];
    if (visible.isEmpty) return const [];
    final groups = <ScatterGroup>[];
    final membersOf = <ResearchStage, List<ResearchNode>>{};
    for (final stage in visible) {
      final members = GraphQueries.nodesInStage(
        catalogue,
        root.candidateId,
        stage,
      );
      membersOf[stage] = members;
      groups.add(
        ScatterGroup(
          child: ScatterChild.of(
            StageGroup.idFor(root.candidateId, stage),
            stage,
          ),
          members: [
            for (final member in members)
              ScatterChild.of(member.id, member.stage),
          ],
        ),
      );
    }
    final centers = LooseScatter.place(
      parent: problemCenter,
      parentShape: ScatterChild.of(root.id, root.stage),
      groups: groups,
    );
    final seats = <_Seat>[];
    for (final stage in visible) {
      final members = membersOf[stage]!;
      final groupId = StageGroup.idFor(root.candidateId, stage);
      final open = expandedIds.contains(groupId);
      seats.add(
        _Seat(
          id: groupId,
          candidateId: root.candidateId,
          stage: stage,
          title: stage.label,
          summary: '',
          center: centers[groupId]!,
          childCount: members.length,
          expanded: open,
          linkFrom: root.id,
          drawn: true,
        ),
      );
      for (final member in members) {
        seats.add(
          _Seat(
            id: member.id,
            candidateId: member.candidateId,
            stage: member.stage,
            title: member.title,
            summary: member.summary,
            center: centers[member.id]!,
            childCount: 0,
            expanded: false,
            linkFrom: groupId,
            drawn: open && visibleIds.contains(member.id),
          ),
        );
      }
    }
    return seats;
  }

  List<_Seat> _shift(List<_Seat> seats, double floorX, double floorY) {
    var minX = double.infinity;
    var minY = double.infinity;
    void include(double left, double top) {
      if (left < minX) minX = left;
      if (top < minY) minY = top;
    }

    for (final seat in seats) {
      include(
        seat.center.dx - LatticeMetrics.widthFor(seat.stage) / 2,
        seat.center.dy - LatticeMetrics.diameterFor(seat.stage) / 2,
      );
    }
    final dx = math.max(0.0, floorX - minX);
    final dy = math.max(0.0, floorY - minY);
    if (dx == 0 && dy == 0) return seats;
    final delta = Offset(dx, dy);
    return [for (final seat in seats) seat.moved(seat.center + delta)];
  }

  LayoutNode _atCenter(_Seat seat) {
    final width = LatticeMetrics.widthFor(seat.stage);
    final diameter = LatticeMetrics.diameterFor(seat.stage);
    return _placed(
      id: seat.id,
      candidateId: seat.candidateId,
      stage: seat.stage,
      title: seat.title,
      summary: seat.summary,
      x: seat.center.dx - width / 2,
      y: seat.center.dy - diameter / 2,
      childCount: seat.childCount,
      expanded: seat.expanded,
    );
  }

  LayoutNode _placed({
    required String id,
    required String candidateId,
    required ResearchStage stage,
    required String title,
    required String summary,
    required double x,
    required double y,
    required int childCount,
    required bool expanded,
  }) {
    return LayoutNode(
      id: id,
      candidateId: candidateId,
      stage: stage,
      title: title,
      summary: summary,
      x: x,
      y: y,
      width: LatticeMetrics.widthFor(stage),
      height: LatticeMetrics.heightFor(stage),
      childCount: childCount,
      expanded: expanded,
    );
  }
}

class _Seat {
  const _Seat({
    required this.id,
    required this.candidateId,
    required this.stage,
    required this.title,
    required this.summary,
    required this.center,
    required this.childCount,
    required this.expanded,
    required this.linkFrom,
    required this.drawn,
  });

  final String id;
  final String candidateId;
  final ResearchStage stage;
  final String title;
  final String summary;
  final Offset center;
  final int childCount;
  final bool expanded;
  final String? linkFrom;

  /// Closed records stay in the list so the group does not jump when they
  /// are opened. They are not drawn.
  final bool drawn;

  _Seat moved(Offset center) {
    return _Seat(
      id: id,
      candidateId: candidateId,
      stage: stage,
      title: title,
      summary: summary,
      center: center,
      childCount: childCount,
      expanded: expanded,
      linkFrom: linkFrom,
      drawn: drawn,
    );
  }
}
