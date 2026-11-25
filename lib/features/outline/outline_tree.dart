import '../../domain/models/catalogue.dart';
import '../../domain/models/research_node.dart';
import '../../domain/services/graph_queries.dart';
import '../explorer/application/explorer_filters.dart';

/// One row in the hierarchy outline. Stage hubs are never parents here.
class OutlineRow {
  const OutlineRow({
    required this.node,
    required this.depth,
    required this.contextOnly,
  });

  final ResearchNode node;
  final int depth;
  final bool contextOnly;
}

/// Builds outline rows from actual parent/child relationships.
class OutlineTree {
  const OutlineTree._();

  static const maxIndentDepth = 8;

  static List<OutlineRow> build({
    required Catalogue catalogue,
    required Set<String> expandedIds,
    ExplorerFilters filters = ExplorerFilters.empty,
  }) {
    final matching = <String>{};
    final constrains = filters.constrainsNodes;
    if (constrains) {
      for (final node in catalogue.nodes.values) {
        if (filters.matchesNode(catalogue, node)) matching.add(node.id);
      }
      if (matching.isEmpty) return const [];
    }

    final forceOpen = <String>{};
    if (constrains) {
      for (final id in matching) {
        forceOpen.addAll(GraphQueries.ancestorIds(catalogue, id));
      }
    }

    final rows = <OutlineRow>[];
    for (final candidate in catalogue.candidates) {
      final root = catalogue.nodes[candidate.rootNodeId];
      if (root == null) continue;
      if (constrains &&
          !matching.contains(root.id) &&
          !GraphQueries.descendantIds(catalogue, root.id).any(matching.contains)) {
        continue;
      }
      _walk(
        catalogue: catalogue,
        node: root,
        depth: 0,
        expandedIds: expandedIds,
        forceOpen: forceOpen,
        constrains: constrains,
        matching: matching,
        hideNonMatching: filters.hideNonMatching,
        rows: rows,
      );
    }
    return rows;
  }

  static void _walk({
    required Catalogue catalogue,
    required ResearchNode node,
    required int depth,
    required Set<String> expandedIds,
    required Set<String> forceOpen,
    required bool constrains,
    required Set<String> matching,
    required bool hideNonMatching,
    required List<OutlineRow> rows,
  }) {
    final isMatch = !constrains || matching.contains(node.id);
    final hasMatchingDescendant = constrains &&
        GraphQueries.descendantIds(catalogue, node.id).any(matching.contains);
    if (constrains && hideNonMatching) {
      if (!isMatch && !hasMatchingDescendant) return;
    }

    rows.add(
      OutlineRow(
        node: node,
        depth: depth,
        contextOnly: constrains && !isMatch,
      ),
    );

    final open =
        expandedIds.contains(node.id) || forceOpen.contains(node.id);
    if (!open) return;
    for (final child in GraphQueries.children(catalogue, node)) {
      if (constrains && hideNonMatching) {
        final childMatch = matching.contains(child.id);
        final childHasMatch = GraphQueries.descendantIds(
          catalogue,
          child.id,
        ).any(matching.contains);
        if (!childMatch && !childHasMatch) continue;
      }
      _walk(
        catalogue: catalogue,
        node: child,
        depth: depth + 1,
        expandedIds: expandedIds,
        forceOpen: forceOpen,
        constrains: constrains,
        matching: matching,
        hideNonMatching: hideNonMatching,
        rows: rows,
      );
    }
  }

  static int cappedDepth(int depth) =>
      depth > maxIndentDepth ? maxIndentDepth : depth;
}
