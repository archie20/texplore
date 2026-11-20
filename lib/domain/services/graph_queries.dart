import '../enums/research_stage.dart';
import '../models/catalogue.dart';
import '../models/research_node.dart';
import 'stage_group.dart';

class GraphQueries {
  const GraphQueries._();

  static List<ResearchNode> children(Catalogue catalogue, ResearchNode node) {
    final kids = [
      for (final id in node.childIds)
        if (catalogue.nodes[id] != null) catalogue.nodes[id]!,
    ];
    kids.sort((a, b) {
      final order = a.sortOrder.compareTo(b.sortOrder);
      if (order != 0) return order;
      return a.id.compareTo(b.id);
    });
    return kids;
  }

  static List<ResearchNode> siblings(Catalogue catalogue, ResearchNode node) {
    if (node.parentId == null) return const [];
    final parent = catalogue.nodes[node.parentId!];
    if (parent == null) return const [];
    return children(catalogue, parent);
  }

  static List<ResearchNode> pathToRoot(Catalogue catalogue, String nodeId) {
    final path = <ResearchNode>[];
    final seen = <String>{};
    var current = catalogue.nodes[nodeId];
    while (current != null && seen.add(current.id)) {
      path.add(current);
      current = current.parentId == null
          ? null
          : catalogue.nodes[current.parentId!];
    }
    return path.reversed.toList();
  }

  static List<String> ancestorIds(Catalogue catalogue, String nodeId) {
    return [
      for (final node in pathToRoot(catalogue, nodeId))
        if (node.id != nodeId) node.id,
    ];
  }

  static Set<String> descendantIds(Catalogue catalogue, String nodeId) {
    final result = <String>{};
    void walk(String id) {
      final node = catalogue.nodes[id];
      if (node == null) return;
      for (final childId in node.childIds) {
        if (result.add(childId)) walk(childId);
      }
    }

    walk(nodeId);
    return result;
  }

  /// Stages that have at least one record for [candidateId], in canonical order.
  /// The thesis problem itself is the root, not a stage group.
  static List<ResearchStage> stagesOf(Catalogue catalogue, String candidateId) {
    final present = <ResearchStage>{};
    for (final node in catalogue.nodes.values) {
      if (node.candidateId != candidateId) continue;
      if (node.stage == ResearchStage.thesisProblem) continue;
      present.add(node.stage);
    }
    final stages = present.toList()..sort((a, b) => a.order.compareTo(b.order));
    return stages;
  }

  static List<ResearchNode> nodesInStage(
    Catalogue catalogue,
    String candidateId,
    ResearchStage stage,
  ) {
    final nodes = [
      for (final node in catalogue.nodes.values)
        if (node.candidateId == candidateId && node.stage == stage) node,
    ];
    nodes.sort((a, b) {
      final order = a.sortOrder.compareTo(b.sortOrder);
      if (order != 0) return order;
      return a.id.compareTo(b.id);
    });
    return nodes;
  }

  /// The circle a keyboard user moves to when leaving [id].
  static String? canvasParentId(Catalogue catalogue, String id) {
    final group = StageGroup.parse(id);
    if (group != null) {
      return catalogue.candidateById(group.candidateId)?.rootNodeId;
    }
    final node = catalogue.nodes[id];
    if (node == null || node.stage == ResearchStage.thesisProblem) return null;
    return StageGroup.idFor(node.candidateId, node.stage);
  }

  /// Thesis problem, stage group, and record on the way to [nodeId].
  static Set<String> routeIds(Catalogue catalogue, String nodeId) {
    final group = StageGroup.parse(nodeId);
    if (group != null) {
      final root = catalogue.candidateById(group.candidateId)?.rootNodeId;
      return {?root, nodeId};
    }
    final node = catalogue.nodes[nodeId];
    if (node == null) return const {};
    if (node.stage == ResearchStage.thesisProblem) return {node.id};
    final root = catalogue.candidateById(node.candidateId)?.rootNodeId;
    return {
      ?root,
      StageGroup.idFor(node.candidateId, node.stage),
      node.id,
    };
  }

  /// [routeIds] plus every circle at the same level as [nodeId].
  static Set<String> focusIds(Catalogue catalogue, String nodeId) {
    final route = routeIds(catalogue, nodeId);
    final group = StageGroup.parse(nodeId);
    if (group != null) {
      return {
        ...route,
        for (final stage in stagesOf(catalogue, group.candidateId))
          StageGroup.idFor(group.candidateId, stage),
      };
    }
    final node = catalogue.nodes[nodeId];
    if (node == null || node.stage == ResearchStage.thesisProblem) {
      return route;
    }
    return {
      ...route,
      for (final sibling in nodesInStage(
        catalogue,
        node.candidateId,
        node.stage,
      ))
        sibling.id,
    };
  }

  /// Nodes revealed by expanding [expandedIds].
  ///
  /// With every thesis problem collapsed, each problem circle is included.
  /// Opening a problem shows one circle per research stage, grouped under
  /// that problem. Opening a stage shows the records in that stage. Once any
  /// problem is open, the other problem circles are omitted so they are not
  /// laid out or drawn.
  static Set<String> structurallyVisible(
    Catalogue catalogue,
    Set<String> expandedIds,
  ) {
    final roots = <ResearchNode>[];
    for (final candidate in catalogue.candidates) {
      final root = catalogue.nodes[candidate.rootNodeId];
      if (root != null) roots.add(root);
    }
    final open = [
      for (final root in roots)
        if (expandedIds.contains(root.id)) root,
    ];
    final visible = <String>{};
    for (final root in open.isEmpty ? roots : open) {
      visible.add(root.id);
      if (!expandedIds.contains(root.id)) continue;
      for (final stage in stagesOf(catalogue, root.candidateId)) {
        final groupId = StageGroup.idFor(root.candidateId, stage);
        visible.add(groupId);
        if (!expandedIds.contains(groupId)) continue;
        for (final node in nodesInStage(catalogue, root.candidateId, stage)) {
          visible.add(node.id);
        }
      }
    }
    return visible;
  }
}
