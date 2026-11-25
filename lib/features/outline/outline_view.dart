import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import '../../app/theme/app_theme.dart';
import '../../domain/models/catalogue.dart';
import '../../domain/models/research_node.dart';
import '../../domain/services/graph_queries.dart';
import '../explorer/application/catalogue_cubit.dart';
import '../explorer/application/explorer_bloc.dart';
import '../explorer/application/explorer_event.dart';
import '../explorer/application/explorer_state.dart';
import 'outline_tree.dart';

/// Accessible tree of the actual research hierarchy for each candidate.
class OutlineView extends StatelessWidget {
  const OutlineView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExplorerBloc, ExplorerState>(
      buildWhen: (previous, next) =>
          previous.selectedNodeId != next.selectedNodeId ||
          previous.expandedIds != next.expandedIds ||
          previous.filters != next.filters ||
          previous.dimmedIds != next.dimmedIds,
      builder: (context, state) {
        final catalogue = context.read<CatalogueCubit>().state;
        if (catalogue is! CatalogueLoaded) return const SizedBox.shrink();
        final rows = OutlineTree.build(
          catalogue: catalogue.catalogue,
          expandedIds: state.expandedIds,
          filters: state.filters,
        );
        return DecoratedBox(
          decoration: BoxDecoration(
            color: context.theme.colors.card,
            border: Border(
              right: BorderSide(color: context.theme.colors.border),
            ),
          ),
          child: rows.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No nodes match these filters.',
                    style: context.theme.typography.body.sm,
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    for (final row in rows)
                      _OutlineRow(
                        node: row.node,
                        depth: row.depth,
                        catalogue: catalogue.catalogue,
                        selected: state.selectedNodeId == row.node.id,
                        expanded: state.expandedIds.contains(row.node.id),
                        dimmed: row.contextOnly ||
                            state.dimmedIds.contains(row.node.id),
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class _OutlineRow extends StatelessWidget {
  const _OutlineRow({
    required this.node,
    required this.depth,
    required this.catalogue,
    required this.selected,
    required this.expanded,
    required this.dimmed,
  });

  final ResearchNode node;
  final int depth;
  final Catalogue catalogue;
  final bool selected;
  final bool expanded;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final childCount = GraphQueries.children(catalogue, node).length;
    final title = node.title;
    final colors = context.theme.colors;
    final indent = 8.0 + OutlineTree.cappedDepth(depth) * 12;
    return Opacity(
      opacity: dimmed ? 0.4 : 1,
      child: Padding(
        padding: EdgeInsets.only(left: indent),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (childCount > 0)
              Semantics(
                button: true,
                expanded: expanded,
                label: '${expanded ? 'Collapse' : 'Expand'} $title',
                child: GestureDetector(
                  onTap: () =>
                      context.read<ExplorerBloc>().add(NodeToggled(node.id)),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      expanded ? '–' : '+',
                      style: context.theme.typography.body.sm,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(width: 22),
            Expanded(
              child: Semantics(
                button: true,
                selected: selected,
                label: '${node.stage.label}. $title',
                child: GestureDetector(
                  onTap: () => context.read<ExplorerBloc>().add(
                    NodeSelected(node.id, centre: true),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: selected
                          ? context.notebook.inkSoft
                          : const Color(0x00000000),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 6,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            node.stage.label,
                            style: context.theme.typography.body.xs.copyWith(
                              color: colors.mutedForeground,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            title,
                            style: context.theme.typography.body.sm.copyWith(
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
