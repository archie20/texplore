import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import '../../domain/enums/evidence_status.dart';
import '../../domain/enums/relationship_type.dart';
import '../../domain/enums/research_stage.dart';
import '../../domain/enums/verification_status.dart';
import '../../domain/models/catalogue.dart';
import '../explorer/application/catalogue_cubit.dart';
import '../explorer/application/explorer_bloc.dart';
import '../explorer/application/explorer_event.dart';
import '../explorer/application/explorer_filters.dart';
import '../explorer/application/explorer_state.dart';
import '../search/search_cubit.dart';

class FilterBar extends StatefulWidget {
  const FilterBar({super.key});

  @override
  State<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<FilterBar>
    with SingleTickerProviderStateMixin {
  late final FPopoverController _popover = FPopoverController(vsync: this);

  @override
  void dispose() {
    _popover.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExplorerBloc, ExplorerState>(
      buildWhen: (previous, next) => previous.filters != next.filters,
      builder: (context, state) {
        final active =
            state.filters.constrainsNodes ||
            state.filters.hideNonMatching ||
            state.filters.showLiterature ||
            state.filters.includeSuperseded;
        return FPopover(
          control: .managed(controller: _popover),
          constraints: const FPortalConstraints(maxWidth: 360, maxHeight: 480),
          popoverBuilder: (context, controller) =>
              _FilterSheet(filters: state.filters),
          child: FButton(
            variant: active ? .secondary : .outline,
            size: .sm,
            onPress: _popover.toggle,
            child: Text(
              active ? 'Filters · ${_summary(state.filters)}' : 'Filters',
            ),
          ),
        );
      },
    );
  }

  String _summary(ExplorerFilters filters) {
    final parts = <String>[
      if (filters.stages.isNotEmpty)
        filters.stages.map((stage) => stage.label).join(' or '),
      if (filters.evidenceStatuses.isNotEmpty) 'evidence',
      if (filters.verificationStatuses.isNotEmpty) 'verification',
      if (filters.priorities.isNotEmpty) 'priority',
      if (filters.tags.isNotEmpty) 'tags',
      if (filters.hideNonMatching) 'hidden',
      if (filters.showLiterature) 'literature',
    ];
    return parts.isEmpty ? 'on' : parts.join(', ');
  }
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({required this.filters});

  final ExplorerFilters filters;

  @override
  Widget build(BuildContext context) {
    final catalogue = context.read<CatalogueCubit>().state;
    final loaded = catalogue is CatalogueLoaded ? catalogue.catalogue : null;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.theme.colors.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: SizedBox(
        width: 340,
        height: 460,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Filters',
                    style: context.theme.typography.display.sm.copyWith(
                      fontSize: 16,
                    ),
                  ),
                ),
                FButton(
                  variant: .ghost,
                  size: .xs,
                  onPress: () {
                    context.read<ExplorerBloc>().add(const FiltersCleared());
                    context.read<SearchCubit>().setIncludeSuperseded(false);
                  },
                  child: const Text('Clear all'),
                ),
              ],
            ),
            Text(
              filters.hideNonMatching
                  ? 'Non-matching nodes are hidden.'
                  : 'Non-matching nodes are dimmed.',
              style: context.theme.typography.body.xs.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                _choice(
                  context,
                  'Dim',
                  !filters.hideNonMatching,
                  () => _update(
                    context,
                    filters.copyWith(hideNonMatching: false),
                  ),
                ),
                _choice(
                  context,
                  'Hide',
                  filters.hideNonMatching,
                  () =>
                      _update(context, filters.copyWith(hideNonMatching: true)),
                ),
                _choice(
                  context,
                  'Literature links',
                  filters.showLiterature,
                  () {
                    _update(
                      context,
                      filters.copyWith(showLiterature: !filters.showLiterature),
                    );
                  },
                ),
                _choice(
                  context,
                  'Superseded in search',
                  filters.includeSuperseded,
                  () {
                    final next = !filters.includeSuperseded;
                    _update(context, filters.copyWith(includeSuperseded: next));
                    context.read<SearchCubit>().setIncludeSuperseded(next);
                  },
                ),
              ],
            ),
            if (loaded != null) ...[
              _group<ResearchStage>(
                context,
                'Stage',
                ResearchStage.values,
                filters.stages,
                (stage) => stage.label,
                (next) => filters.copyWith(stages: next),
              ),
              _group<EvidenceStatus>(
                context,
                'Evidence',
                EvidenceStatus.values,
                filters.evidenceStatuses,
                (status) => status.label,
                (next) => filters.copyWith(evidenceStatuses: next),
              ),
              _group<VerificationStatus>(
                context,
                'Publication check',
                VerificationStatus.values,
                filters.verificationStatuses,
                (status) => status.label,
                (next) => filters.copyWith(verificationStatuses: next),
              ),
              _group<CandidatePriority>(
                context,
                'Priority',
                CandidatePriority.values,
                filters.priorities,
                (priority) => priority.label,
                (next) => filters.copyWith(priorities: next),
              ),
              _group<String>(
                context,
                'Tag',
                _tags(loaded),
                filters.tags,
                (tag) => tag,
                (next) => filters.copyWith(tags: next),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _update(BuildContext context, ExplorerFilters next) {
    context.read<ExplorerBloc>().add(FiltersChanged(next));
  }

  Widget _choice(
    BuildContext context,
    String label,
    bool on,
    VoidCallback press,
  ) {
    return FButton(
      variant: on ? .secondary : .ghost,
      size: .xs,
      onPress: press,
      child: Text(label),
    );
  }

  Widget _group<T>(
    BuildContext context,
    String title,
    List<T> values,
    Set<T> selected,
    String Function(T) label,
    ExplorerFilters Function(Set<T>) apply,
  ) {
    if (values.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.theme.typography.body.xs.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final value in values)
                FButton(
                  variant: selected.contains(value) ? .secondary : .outline,
                  size: .xs,
                  onPress: () {
                    final next = {...selected};
                    if (!next.add(value)) next.remove(value);
                    _update(context, apply(next));
                  },
                  child: Text(label(value)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<String> _tags(Catalogue catalogue) {
    final tags = {
      for (final candidate in catalogue.candidates) ...candidate.tags,
      for (final node in catalogue.nodes.values) ...node.tags,
    }.toList()..sort();
    return tags;
  }
}
