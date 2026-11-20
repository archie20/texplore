import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/stage_style.dart';
import '../../domain/models/catalogue.dart';
import '../../domain/services/stage_group.dart';
import '../../graph/layout/layout_node.dart';
import '../explorer/application/catalogue_cubit.dart';
import '../explorer/application/explorer_bloc.dart';
import '../explorer/application/explorer_event.dart';
import '../explorer/application/explorer_state.dart';

/// The same nodes the canvas is showing, in reading order, for keyboard use.
class OutlineView extends StatelessWidget {
  const OutlineView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExplorerBloc, ExplorerState>(
      buildWhen: (previous, next) =>
          previous.layout != next.layout ||
          previous.selectedNodeId != next.selectedNodeId ||
          previous.expandedIds != next.expandedIds ||
          previous.dimmedIds != next.dimmedIds,
      builder: (context, state) {
        final catalogue = context.read<CatalogueCubit>().state;
        if (catalogue is! CatalogueLoaded) return const SizedBox.shrink();
        final nodes = state.layout.nodes;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: context.theme.colors.card,
            border: Border(
              right: BorderSide(color: context.theme.colors.border),
            ),
          ),
          child: nodes.isEmpty
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
                    for (final node in nodes)
                      _OutlineRow(
                        node: node,
                        catalogue: catalogue.catalogue,
                        selected: state.selectedNodeId == node.id,
                        expanded: state.expandedIds.contains(node.id),
                        dimmed: state.dimmedIds.contains(node.id),
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
    required this.catalogue,
    required this.selected,
    required this.expanded,
    required this.dimmed,
  });

  final LayoutNode node;
  final Catalogue catalogue;
  final bool selected;
  final bool expanded;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final research = catalogue.nodes[node.id];
    final group = StageGroup.parse(node.id);
    final childCount = node.childCount;
    final title = group != null
        ? StageStyle.of(node.stage).label
        : (research?.title ?? node.title);
    final colors = context.theme.colors;
    return Opacity(
      opacity: dimmed ? 0.4 : 1,
      child: Padding(
        padding: EdgeInsets.only(left: 8.0 + (node.stage.order - 1) * 10),
        child: Row(
          children: [
            if (childCount > 0)
              Semantics(
                button: true,
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
                label: group == null ? '${node.stage.label}. $title' : title,
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
                          if (group == null)
                            Text(
                              node.stage.label,
                              style: context.theme.typography.body.xs.copyWith(
                                color: colors.mutedForeground,
                                fontSize: 10,
                              ),
                            ),
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
