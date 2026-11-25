import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import '../../domain/enums/research_stage.dart';

/// Sizes for the circle lattice. The layout box is a little taller than the
/// circle so the label fits under it. A thesis problem uses its problem
/// statement, which needs more room than a stage name. Edges attach to the
/// circle.
class LatticeMetrics {
  const LatticeMetrics._();

  static const columnPitch = 220.0;
  static const nodeWidth = 148.0;
  static const rootWidth = 168.0;
  static const nodeDiameter = 58.0;
  static const questionDiameter = 68.0;
  static const rootDiameter = 84.0;
  static const caption = 36.0;
  static const problemCaption = 72.0;
  static const siblingGap = 22.0;
  static const candidateGap = 112.0;
  static const originX = 64.0;
  static const originY = 78.0;
  static const padding = 96.0;

  static const nodeHeight = nodeDiameter + caption;
  static const rootHeight = rootDiameter + problemCaption;

  static double diameterFor(ResearchStage stage) {
    return switch (stage) {
      ResearchStage.thesisProblem => rootDiameter,
      ResearchStage.thesisQuestion ||
      ResearchStage.researchQuestions => questionDiameter,
      _ => nodeDiameter,
    };
  }

  static double captionFor(ResearchStage stage) {
    return stage == ResearchStage.thesisProblem ? problemCaption : caption;
  }

  static double heightFor(ResearchStage stage) =>
      diameterFor(stage) + captionFor(stage);

  /// Selected circles grow by this factor, past every other child.
  static const selectedScale = (rootDiameter + 6) / nodeDiameter;

  /// How far a center-scaled selected circle extends below its resting box.
  static double selectedDrop(ResearchStage stage) =>
      (selectedScale - 1) * diameterFor(stage) / 2;

  static double widthFor(ResearchStage stage) {
    return stage == ResearchStage.thesisProblem ? rootWidth : nodeWidth;
  }

  static GraphPoint centerOf(LayoutNode node) {
    return GraphPoint(
      node.x + node.width / 2,
      node.y + diameterFor(node.stage) / 2,
    );
  }

  /// A point on the circle's rim, toward [toward].
  static GraphPoint rim(LayoutNode node, GraphPoint toward) {
    final center = centerOf(node);
    final dx = toward.x - center.x;
    final dy = toward.y - center.y;
    final len = math.sqrt(dx * dx + dy * dy);
    final radius = diameterFor(node.stage) / 2 + 3;
    if (len <= 0.001) return center;
    final scale = radius / len;
    return GraphPoint(center.x + dx * scale, center.y + dy * scale);
  }
}

class GraphPoint extends Equatable {
  const GraphPoint(this.x, this.y);

  final double x;
  final double y;

  @override
  List<Object?> get props => [x, y];
}

class LayoutNode extends Equatable {
  const LayoutNode({
    required this.id,
    required this.candidateId,
    required this.stage,
    required this.title,
    required this.summary,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.childCount,
    required this.expanded,
  });

  final String id;
  final String candidateId;
  final ResearchStage stage;
  final String title;
  final String summary;
  final double x;
  final double y;
  final double width;
  final double height;
  final int childCount;
  final bool expanded;

  bool contains(double px, double py) {
    return px >= x && px <= x + width && py >= y && py <= y + height;
  }

  bool overlaps(LayoutNode other) {
    if (id == other.id) return false;
    return x < other.x + other.width &&
        other.x < x + width &&
        y < other.y + other.height &&
        other.y < y + height;
  }

  @override
  List<Object?> get props => [
    id,
    candidateId,
    stage,
    title,
    summary,
    x,
    y,
    width,
    height,
    childCount,
    expanded,
  ];
}

class RoutedEdge extends Equatable {
  const RoutedEdge({
    required this.id,
    required this.sourceId,
    required this.targetId,
    required this.start,
    required this.control1,
    required this.control2,
    required this.end,
    required this.dashed,
    required this.crossLink,
    this.navigation = false,
    this.points = const [],
  });

  final String id;
  final String sourceId;
  final String targetId;
  final GraphPoint start;
  final GraphPoint control1;
  final GraphPoint control2;
  final GraphPoint end;
  final bool dashed;
  final bool crossLink;

  /// Root-to-stage hub link. Not a content parent-child edge.
  final bool navigation;

  /// The drawn polyline, including both ends. Empty means the straight
  /// segment from [start] to [end].
  final List<GraphPoint> points;

  List<GraphPoint> get route => points.length >= 2 ? points : [start, end];

  bool get structural => !crossLink && !navigation;

  @override
  List<Object?> get props => [
    id,
    sourceId,
    targetId,
    start,
    control1,
    control2,
    end,
    dashed,
    crossLink,
    navigation,
    points,
  ];
}

class CandidateBand extends Equatable {
  const CandidateBand({
    required this.candidateId,
    required this.top,
    required this.bottom,
    this.banner,
  });

  final String candidateId;
  final double top;
  final double bottom;
  final String? banner;

  @override
  List<Object?> get props => [candidateId, top, bottom, banner];
}

class GraphLayout extends Equatable {
  const GraphLayout({
    required this.nodes,
    required this.edges,
    required this.bands,
    required this.width,
    required this.height,
  });

  static const empty = GraphLayout(
    nodes: [],
    edges: [],
    bands: [],
    width: 0,
    height: 0,
  );

  final List<LayoutNode> nodes;
  final List<RoutedEdge> edges;
  final List<CandidateBand> bands;
  final double width;
  final double height;

  LayoutNode? nodeById(String id) {
    for (final node in nodes) {
      if (node.id == id) return node;
    }
    return null;
  }

  GraphLayout boundsOf(Set<String> ids) {
    final picked = [
      for (final node in nodes)
        if (ids.contains(node.id)) node,
    ];
    if (picked.isEmpty) return this;
    var left = picked.first.x;
    var top = picked.first.y;
    var right = picked.first.x + picked.first.width;
    var bottom = picked.first.y + picked.first.height;
    for (final node in picked.skip(1)) {
      left = left < node.x ? left : node.x;
      top = top < node.y ? top : node.y;
      final nodeRight = node.x + node.width;
      final nodeBottom = node.y + node.height;
      right = right > nodeRight ? right : nodeRight;
      bottom = bottom > nodeBottom ? bottom : nodeBottom;
    }
    return GraphLayout(
      nodes: picked,
      edges: const [],
      bands: const [],
      width: right - left,
      height: bottom - top,
    );
  }

  @override
  List<Object?> get props => [nodes, edges, bands, width, height];
}
