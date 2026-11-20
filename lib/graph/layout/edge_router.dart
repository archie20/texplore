import 'layout_node.dart';

class EdgeRouter {
  const EdgeRouter();

  RoutedEdge hierarchy(LayoutNode source, LayoutNode target) {
    final sourceCenter = LatticeMetrics.centerOf(source);
    final targetCenter = LatticeMetrics.centerOf(target);
    final start = LatticeMetrics.rim(source, targetCenter);
    final end = LatticeMetrics.rim(target, sourceCenter);
    return RoutedEdge(
      id: '${source.id}->${target.id}',
      sourceId: source.id,
      targetId: target.id,
      start: start,
      control1: start,
      control2: end,
      end: end,
      dashed: false,
      crossLink: false,
    );
  }

  RoutedEdge cross(String id, LayoutNode source, LayoutNode target) {
    final edge = hierarchy(source, target);
    return RoutedEdge(
      id: id,
      sourceId: source.id,
      targetId: target.id,
      start: edge.start,
      control1: edge.start,
      control2: edge.end,
      end: edge.end,
      dashed: true,
      crossLink: true,
    );
  }
}
