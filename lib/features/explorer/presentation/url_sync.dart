import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/enums/evidence_status.dart';
import '../../../domain/enums/relationship_type.dart';
import '../../../domain/enums/research_stage.dart';
import '../../../domain/enums/verification_status.dart';
import '../../search/search_cubit.dart';
import '../application/explorer_bloc.dart';
import '../application/explorer_event.dart';
import '../application/explorer_filters.dart';
import '../application/explorer_state.dart';

/// Reads the launch URL once, then writes selection, search, and filters back
/// with [GoRouter.replace] so the browser history does not fill up.
class ExplorerUrlSync extends StatefulWidget {
  const ExplorerUrlSync({required this.child, super.key});

  final Widget child;

  @override
  State<ExplorerUrlSync> createState() => _ExplorerUrlSyncState();
}

class _ExplorerUrlSyncState extends State<ExplorerUrlSync> {
  var _applied = false;
  String? _written;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_applied) return;
    _applied = true;
    final uri = GoRouterState.of(context).uri;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _apply(uri);
    });
  }

  void _apply(Uri uri) {
    final params = uri.queryParameters;
    final filters = filtersFromQuery(params);
    final bloc = context.read<ExplorerBloc>();
    final search = context.read<SearchCubit>();
    if (filters != ExplorerFilters.empty) {
      bloc.add(FiltersChanged(filters));
      search.setIncludeSuperseded(filters.includeSuperseded);
    }
    final query = params['q'] ?? '';
    if (query.isNotEmpty) search.queryChanged(query);
    final node = params['node'];
    final candidate = params['candidate'];
    if (node != null && node.isNotEmpty) {
      bloc.add(PathRevealed(node));
      bloc.add(NodeSelected(node, centre: true));
    } else if (candidate != null && candidate.isNotEmpty) {
      bloc.add(CandidateSelected(candidate));
    }
    _written = _location(bloc.state, query);
  }

  void _write(ExplorerState state, String query) {
    final next = _location(state, query);
    if (next == _written) return;
    final current = GoRouterState.of(context).uri;
    if (current.path != '/') return;
    _written = next;
    context.replace(next);
  }

  String _location(ExplorerState state, String query) {
    return Uri(
      path: '/',
      queryParameters: queryFromState(state, query),
    ).toString();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ExplorerBloc, ExplorerState>(
          listener: (context, state) =>
              _write(state, context.read<SearchCubit>().state.query),
        ),
        BlocListener<SearchCubit, SearchState>(
          listenWhen: (previous, next) => previous.query != next.query,
          listener: (context, state) =>
              _write(context.read<ExplorerBloc>().state, state.query),
        ),
      ],
      child: widget.child,
    );
  }
}

Map<String, String> queryFromState(ExplorerState state, String query) {
  final params = <String, String>{};
  void put(String key, String value) {
    if (value.isNotEmpty) params[key] = value;
  }

  put('candidate', state.selectedCandidateId ?? '');
  put('node', state.selectedNodeId ?? '');
  put('q', query.trim());
  put('stage', state.filters.stages.map((stage) => stage.wire).join(','));
  put(
    'evidence',
    state.filters.evidenceStatuses.map((status) => status.wire).join(','),
  );
  put(
    'verification',
    state.filters.verificationStatuses.map((status) => status.wire).join(','),
  );
  put(
    'priority',
    state.filters.priorities.map((priority) => priority.wire).join(','),
  );
  put('tag', state.filters.tags.join(','));
  if (state.filters.hideNonMatching) params['hide'] = '1';
  if (state.filters.includeSuperseded) params['superseded'] = '1';
  if (state.filters.showLiterature) params['literature'] = '1';
  return params;
}

ExplorerFilters filtersFromQuery(Map<String, String> params) {
  Set<T> parse<T>(String key, T? Function(String) read) {
    final raw = params[key];
    if (raw == null || raw.isEmpty) return {};
    return {
      for (final part in raw.split(','))
        if (read(part) != null) read(part) as T,
    };
  }

  return ExplorerFilters(
    stages: parse('stage', ResearchStage.parse),
    evidenceStatuses: parse('evidence', EvidenceStatus.parse),
    verificationStatuses: parse('verification', VerificationStatus.parse),
    priorities: parse('priority', CandidatePriority.parse),
    tags: {
      for (final tag in (params['tag'] ?? '').split(','))
        if (tag.isNotEmpty) tag,
    },
    hideNonMatching: params['hide'] == '1',
    includeSuperseded: params['superseded'] == '1',
    showLiterature: params['literature'] == '1',
  );
}
