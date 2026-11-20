import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import '../../domain/services/search_index.dart';
import '../explorer/application/catalogue_cubit.dart';
import '../explorer/application/explorer_bloc.dart';
import '../explorer/application/explorer_event.dart';
import '../explorer/presentation/detail_focus.dart';
import 'search_cubit.dart';

class SearchPalette extends StatefulWidget {
  const SearchPalette({super.key});

  @override
  State<SearchPalette> createState() => SearchPaletteState();
}

class SearchPaletteState extends State<SearchPalette>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _field;
  late final FPopoverController _popover;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _field = TextEditingController(
      text: context.read<SearchCubit>().state.query,
    );
    _popover = FPopoverController(vsync: this);
    _focus.addListener(() {
      if (_focus.hasFocus) _popover.show();
    });
  }

  @override
  void dispose() {
    _field.dispose();
    _popover.dispose();
    _focus.dispose();
    super.dispose();
  }

  void open() {
    _focus.requestFocus();
    _popover.show();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SearchCubit, SearchState>(
      listenWhen: (previous, next) => previous.query != next.query,
      listener: (context, state) {
        if (_field.text != state.query) {
          _field.value = TextEditingValue(
            text: state.query,
            selection: TextSelection.collapsed(offset: state.query.length),
          );
        }
        if (state.query.trim().isEmpty) {
          _popover.hide();
        } else {
          _popover.show();
        }
      },
      child: FPopover(
        control: .managed(controller: _popover),
        constraints: const FPortalConstraints(maxWidth: 440, maxHeight: 420),
        popoverAnchor: .bottomCenter,
        childAnchor: .topCenter,
        hideRegion: .excludeChild,
        popoverBuilder: (context, _) => const _Results(),
        child: SizedBox(
          width: 280,
          child: FTextField(
            focusNode: _focus,
            control: .managed(
              controller: _field,
              onChange: (value) =>
                  context.read<SearchCubit>().queryChanged(value.text),
            ),
            hint: 'Search',
          ),
        ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchCubit, SearchState>(
      builder: (context, state) {
        final colors = context.theme.colors;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(10),
          ),
          child: SizedBox(
            width: 420,
            height: 360,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          state.includeSuperseded
                              ? 'Including superseded'
                              : 'Superseded hidden',
                          style: context.theme.typography.body.xs.copyWith(
                            color: colors.mutedForeground,
                          ),
                        ),
                      ),
                      FButton(
                        variant: .ghost,
                        size: .xs,
                        onPress: () => context
                            .read<SearchCubit>()
                            .setIncludeSuperseded(!state.includeSuperseded),
                        child: Text(
                          state.includeSuperseded
                              ? 'Hide superseded'
                              : 'Include superseded',
                        ),
                      ),
                      FButton(
                        variant: .ghost,
                        size: .xs,
                        onPress: () {
                          context.read<SearchCubit>().clear();
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _HitList(state: state)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HitList extends StatelessWidget {
  const _HitList({required this.state});

  final SearchState state;

  @override
  Widget build(BuildContext context) {
    if (state.query.trim().isEmpty) {
      return const _Message(
        'Type to search candidates, nodes, publications, and claims.',
      );
    }
    if (state.hits.isEmpty) {
      return const _Message(
        'No results. Try another word, or clear the query.',
      );
    }
    final groups = <String, List<SearchHit>>{};
    for (final hit in state.hits) {
      final catalogue = context.read<CatalogueCubit>().state;
      final name = catalogue is CatalogueLoaded
          ? (catalogue.catalogue.candidateById(hit.candidateId)?.shortTitle ??
                hit.candidateId)
          : hit.candidateId;
      groups.putIfAbsent('$name · ${hit.groupLabel}', () => []).add(hit);
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 8),
      children: [
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Text(
              entry.key,
              style: context.theme.typography.body.xs.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
          ),
          for (final hit in entry.value) _HitTile(hit: hit),
        ],
      ],
    );
  }
}

class _HitTile extends StatelessWidget {
  const _HitTile({required this.hit});

  final SearchHit hit;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _choose(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hit.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.theme.typography.body.sm,
            ),
            Text(
              '${hit.matchedIn}: ${hit.snippet}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.theme.typography.body.xs.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _choose(BuildContext context) {
    final catalogueState = context.read<CatalogueCubit>().state;
    if (catalogueState is! CatalogueLoaded) return;
    final catalogue = catalogueState.catalogue;
    var nodeId = hit.nodeId;
    if (nodeId == null && hit.publicationId != null) {
      for (final link in catalogue.evidenceLinks.values) {
        if (link.publicationId == hit.publicationId) {
          final node = catalogue.nodes[link.nodeId];
          if (node != null && node.candidateId == hit.candidateId) {
            nodeId = node.id;
            break;
          }
        }
      }
    }
    final bloc = context.read<ExplorerBloc>();
    if (nodeId != null) {
      bloc.add(PathRevealed(nodeId));
      bloc.add(NodeSelected(nodeId, centre: true));
      DetailScope.of(context)
          .open(nodeId: nodeId, publicationId: hit.publicationId);
    } else {
      bloc.add(CandidateSelected(hit.candidateId));
    }
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        text,
        style: context.theme.typography.body.sm.copyWith(
          color: context.theme.colors.mutedForeground,
        ),
      ),
    );
  }
}
