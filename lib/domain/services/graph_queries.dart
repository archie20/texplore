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

  /// Records in [stage] whose parent is absent or belongs to a different stage.
  static List<ResearchNode> stageEntries(
    Catalogue catalogue,
    String candidateId,
    ResearchStage stage,
  ) {
    final entries = <ResearchNode>[];
    for (final node in nodesInStage(catalogue, candidateId, stage)) {
      if (node.parentId == null) {
        entries.add(node);
        continue;
      }
      final parent = catalogue.nodes[node.parentId!];
      if (parent == null || parent.stage != stage) {
        entries.add(node);
      }
    }
    return entries;
  }

  /// The circle a keyboard user moves to when leaving [id].
  static String? canvasParentId(Catalogue catalogue, String id) {
    final group = StageGroup.parse(id);
    if (group != null) {
      return catalogue.candidateById(group.candidateId)?.rootNodeId;
    }
    final node = catalogue.nodes[id];
    if (node == null) return null;
    if (node.parentId != null && catalogue.nodes.containsKey(node.parentId)) {
      return node.parentId;
    }
    if (node.stage == ResearchStage.thesisProblem) return null;
    return StageGroup.idFor(node.candidateId, node.stage);
  }

  /// Actual ancestor path from the candidate root to [nodeId].
  static Set<String> routeIds(Catalogue catalogue, String nodeId) {
    final group = StageGroup.parse(nodeId);
    if (group != null) {
      final root = catalogue.candidateById(group.candidateId)?.rootNodeId;
      return {?root, nodeId};
    }
    final node = catalogue.nodes[nodeId];
    if (node == null) return const {};
    return {for (final step in pathToRoot(catalogue, nodeId)) step.id};
  }

  /// [routeIds] plus siblings at the same structural level as [nodeId].
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
    if (node == null) return route;
    if (node.stage == ResearchStage.thesisProblem) return route;
    return {
      ...route,
      for (final sibling in siblings(catalogue, node)) sibling.id,
    };
  }

  /// Nodes revealed by expanding [expandedIds].
  ///
  /// Roots stay collapsed until opened. Opening a problem shows stage hubs.
  /// Opening a stage shows only stage-entry records. Expanding a research
  /// record reveals its actual children. Ancestors of any visible record are
  /// auto-revealed without expanding sibling branches.
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
        for (final entry in stageEntries(catalogue, root.candidateId, stage)) {
          visible.add(entry.id);
        }
      }
    }

    // Thesis-problem expansion only unlocks stage hubs. Record expansion
    // reveals actual children, including cross-stage ones.
    var grew = true;
    while (grew) {
      grew = false;
      final snapshot = visible.toList();
      for (final id in snapshot) {
        if (!expandedIds.contains(id)) continue;
        final node = catalogue.nodes[id];
        if (node == null) continue;
        if (node.stage == ResearchStage.thesisProblem) continue;
        for (final child in children(catalogue, node)) {
          if (visible.add(child.id)) grew = true;
        }
      }
    }

    final researchIds = [
      for (final id in visible.toList())
        if (catalogue.nodes.containsKey(id)) id,
    ];
    for (final id in researchIds) {
      for (final ancestor in ancestorIds(catalogue, id)) {
        visible.add(ancestor);
      }
    }
    return visible;
  }

  /// Expansion ids that make [nodeId] reachable without opening off-path siblings.
  ///
  /// Opens the candidate root and the target's stage hub. Same-stage ancestors
  /// are expanded so nested records under a stage entry become reachable.
  /// Cross-stage ancestors are left collapsed; [structurallyVisible] auto-reveals
  /// them without expanding their other children.
  static Set<String> expansionForPath(Catalogue catalogue, String nodeId) {
    final node = catalogue.nodes[nodeId];
    if (node == null) return const {};
    final expanded = <String>{};
    final root = catalogue.candidateById(node.candidateId)?.rootNodeId;
    if (root != null) expanded.add(root);
    if (node.stage != ResearchStage.thesisProblem) {
      expanded.add(StageGroup.idFor(node.candidateId, node.stage));
    }
    var current = node;
    while (current.parentId != null) {
      final parent = catalogue.nodes[current.parentId!];
      if (parent == null) break;
      if (parent.stage == current.stage) {
        expanded.add(parent.id);
      }
      current = parent;
    }
    return expanded;
  }
}
