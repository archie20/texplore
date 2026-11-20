import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/enums/research_stage.dart';
import '../../../domain/models/catalogue.dart';
import '../../../domain/models/research_node.dart';
import '../../../domain/services/graph_queries.dart';
import '../../../domain/services/stage_group.dart';
import '../../../graph/layout/hierarchical_layout_engine.dart';
import '../../../graph/layout/layout_node.dart';
import 'explorer_event.dart';
import 'explorer_filters.dart';
import 'explorer_state.dart';

class ExplorerBloc extends Bloc<ExplorerEvent, ExplorerState> {
  ExplorerBloc({
    required Catalogue catalogue,
    HierarchicalLayoutEngine? layoutEngine,
    ExplorerFilters? initialFilters,
    String? initialCandidateId,
    String? initialNodeId,
    Set<String>? initialExpanded,
  }) : _catalogue = catalogue,
       _layoutEngine = layoutEngine ?? HierarchicalLayoutEngine(),
       super(
         _seed(
           catalogue: catalogue,
           engine: layoutEngine ?? HierarchicalLayoutEngine(),
           initialFilters: initialFilters,
           initialCandidateId: initialCandidateId,
           initialNodeId: initialNodeId,
           initialExpanded: initialExpanded,
         ),
       ) {
    on<CandidateSelected>(_onCandidate);
    on<NodeSelected>(_onNode);
    on<NodeToggled>(_onToggle);
    on<PathRevealed>(_onPath);
    on<FiltersChanged>(_onFilters);
    on<FiltersCleared>(_onClearFilters);
    on<InspectorClosed>(_onCloseInspector);
    on<ViewReset>(_onReset);
    on<OutlineToggled>(_onOutline);
    on<MinimapToggled>(_onMinimap);
  }

  final Catalogue _catalogue;
  final HierarchicalLayoutEngine _layoutEngine;

  static ExplorerState _seed({
    required Catalogue catalogue,
    required HierarchicalLayoutEngine engine,
    ExplorerFilters? initialFilters,
    String? initialCandidateId,
    String? initialNodeId,
    Set<String>? initialExpanded,
  }) {
    final base = _initial(catalogue, engine);
    if (initialFilters == null &&
        initialCandidateId == null &&
        initialNodeId == null &&
        initialExpanded == null) {
      return base;
    }
    final expanded = initialExpanded ?? base.expandedIds;
    final filters = initialFilters ?? ExplorerFilters.empty;
    final view = _View.compute(catalogue, engine, expanded, filters);
    return base.copyWith(
      expandedIds: expanded,
      filters: filters,
      selectedCandidateId: initialCandidateId ?? base.selectedCandidateId,
      selectedNodeId: initialNodeId,
      clearNode: initialNodeId == null,
      inspectorOpen: initialNodeId != null || initialCandidateId != null,
      layout: view.layout,
      dimmedIds: view.dimmed,
    );
  }

  static ExplorerState _initial(
    Catalogue catalogue,
    HierarchicalLayoutEngine engine,
  ) {
    const expanded = <String>{};
    final view = _View.compute(
      catalogue,
      engine,
      expanded,
      ExplorerFilters.empty,
    );
    final first = catalogue.primaryCandidates.isNotEmpty
        ? catalogue.primaryCandidates.first.id
        : (catalogue.candidates.isEmpty ? null : catalogue.candidates.first.id);
    return ExplorerState(
      selectedCandidateId: first,
      selectedNodeId: null,
      expandedIds: expanded,
      filters: ExplorerFilters.empty,
      inspectorOpen: false,
      layout: view.layout,
      dimmedIds: view.dimmed,
      focusTick: 1,
      focusKind: FocusKind.fitAll,
      outlineVisible: false,
      minimapVisible: true,
    );
  }

  void _onCandidate(CandidateSelected event, Emitter<ExplorerState> emit) {
    final candidate = _catalogue.candidateById(event.candidateId);
    if (candidate == null) return;
    final open = _openRootIds(state.expandedIds);
    final leaving = open.isNotEmpty && !open.contains(candidate.rootNodeId);
    final expanded = leaving ? <String>{} : null;
    final view = leaving ? _view(const {}, state.filters) : null;
    emit(
      state.copyWith(
        selectedCandidateId: event.candidateId,
        clearNode: true,
        inspectorOpen: true,
        expandedIds: expanded,
        layout: view?.layout,
        dimmedIds: view?.dimmed,
        focusTick: state.focusTick + 1,
        focusKind: FocusKind.fitCandidate,
      ),
    );
  }

  Set<String> _openRootIds(Set<String> expanded) {
    return {
      for (final candidate in _catalogue.candidates)
        if (expanded.contains(candidate.rootNodeId)) candidate.rootNodeId,
    };
  }

  void _onNode(NodeSelected event, Emitter<ExplorerState> emit) {
    final group = StageGroup.parse(event.nodeId);
    if (group != null) {
      _onStage(group, event, emit);
      return;
    }
    final node = _catalogue.nodes[event.nodeId];
    if (node == null) return;
    final expanded = node.stage == ResearchStage.thesisProblem
        ? _expandedForProblem(node)
        : _expandedForRecord(node);
    final changed = !_sameIds(expanded, state.expandedIds);
    final view = changed ? _view(expanded, state.filters) : null;
    emit(
      state.copyWith(
        selectedNodeId: node.id,
        selectedCandidateId: node.candidateId,
        expandedIds: changed ? expanded : null,
        inspectorOpen: true,
        layout: view?.layout,
        dimmedIds: view?.dimmed,
        focusTick: event.centre ? state.focusTick + 1 : state.focusTick,
        focusKind: event.centre ? FocusKind.centreNode : state.focusKind,
      ),
    );
  }

  void _onStage(
    StageGroup group,
    NodeSelected event,
    Emitter<ExplorerState> emit,
  ) {
    final candidate = _catalogue.candidateById(group.candidateId);
    if (candidate == null) return;
    final active = _openCandidateId();
    final expanded = active != null && active != group.candidateId
        ? <String>{}
        : {...state.expandedIds};
    expanded
      ..add(candidate.rootNodeId)
      ..add(group.id);
    final changed = !_sameIds(expanded, state.expandedIds);
    final view = changed ? _view(expanded, state.filters) : null;
    emit(
      state.copyWith(
        selectedNodeId: group.id,
        selectedCandidateId: group.candidateId,
        expandedIds: changed ? expanded : null,
        inspectorOpen: false,
        layout: view?.layout,
        dimmedIds: view?.dimmed,
        focusTick: event.centre ? state.focusTick + 1 : state.focusTick,
        focusKind: event.centre ? FocusKind.centreNode : state.focusKind,
      ),
    );
  }

  /// Opens the stage circles under this thesis problem. A problem in another
  /// candidate closes the one that was open.
  Set<String> _expandedForProblem(ResearchNode node) {
    final active = _openCandidateId();
    final expanded = active != null && active != node.candidateId
        ? <String>{}
        : {...state.expandedIds};
    expanded.add(node.id);
    return expanded;
  }

  /// Opens the problem and the stage that contains this record.
  Set<String> _expandedForRecord(ResearchNode node) {
    final active = _openCandidateId();
    final expanded = active != null && active != node.candidateId
        ? <String>{}
        : {...state.expandedIds};
    final root = _catalogue.candidateById(node.candidateId)?.rootNodeId;
    if (root != null) expanded.add(root);
    expanded.add(StageGroup.idFor(node.candidateId, node.stage));
    return expanded;
  }

  String? _openCandidateId() {
    final selected = state.selectedNodeId;
    if (selected != null) {
      final group = StageGroup.parse(selected);
      if (group != null) return group.candidateId;
      final node = _catalogue.nodes[selected];
      if (node != null) return node.candidateId;
    }
    for (final id in state.expandedIds) {
      final group = StageGroup.parse(id);
      if (group != null) return group.candidateId;
      final candidateId = _catalogue.nodes[id]?.candidateId;
      if (candidateId != null) return candidateId;
    }
    return null;
  }

  bool _inCandidate(String id, String candidateId) {
    final group = StageGroup.parse(id);
    if (group != null) return group.candidateId == candidateId;
    return _catalogue.nodes[id]?.candidateId == candidateId;
  }

  bool _sameIds(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    for (final id in a) {
      if (!b.contains(id)) return false;
    }
    return true;
  }

  void _onToggle(NodeToggled event, Emitter<ExplorerState> emit) {
    final group = StageGroup.parse(event.nodeId);
    if (group != null) {
      _toggleStage(group, emit);
      return;
    }
    final node = _catalogue.nodes[event.nodeId];
    if (node == null || node.stage != ResearchStage.thesisProblem) return;
    final opening = !state.expandedIds.contains(node.id);
    final expanded = {...state.expandedIds};
    String? selected = state.selectedNodeId;
    if (opening) {
      final active = _openCandidateId();
      if (active != null && active != node.candidateId) expanded.clear();
      expanded.add(node.id);
      selected = node.id;
    } else {
      expanded.remove(node.id);
      expanded.removeWhere((id) => _inCandidate(id, node.candidateId));
      if (selected != null && _inCandidate(selected, node.candidateId)) {
        selected = node.id;
      }
    }
    final view = _view(expanded, state.filters);
    emit(
      state.copyWith(
        expandedIds: expanded,
        selectedNodeId: selected,
        layout: view.layout,
        dimmedIds: view.dimmed,
        focusTick: state.focusTick + 1,
        focusKind: opening ? FocusKind.centreNode : FocusKind.zoomOut,
      ),
    );
  }

  void _toggleStage(StageGroup group, Emitter<ExplorerState> emit) {
    final candidate = _catalogue.candidateById(group.candidateId);
    if (candidate == null) return;
    final opening = !state.expandedIds.contains(group.id);
    final expanded = {...state.expandedIds};
    String? selected = state.selectedNodeId;
    if (opening) {
      final active = _openCandidateId();
      if (active != null && active != group.candidateId) expanded.clear();
      expanded
        ..add(candidate.rootNodeId)
        ..add(group.id);
      selected = group.id;
    } else {
      expanded.remove(group.id);
      if (selected != null) {
        final node = _catalogue.nodes[selected];
        if (node != null &&
            node.candidateId == group.candidateId &&
            node.stage == group.stage) {
          selected = group.id;
        }
      }
    }
    final view = _view(expanded, state.filters);
    emit(
      state.copyWith(
        expandedIds: expanded,
        selectedNodeId: selected,
        inspectorOpen: opening || selected == group.id ? false : null,
        layout: view.layout,
        dimmedIds: view.dimmed,
        focusTick: state.focusTick + 1,
        focusKind: opening ? FocusKind.centreNode : FocusKind.zoomOut,
      ),
    );
  }

  void _onPath(PathRevealed event, Emitter<ExplorerState> emit) {
    final node = _catalogue.nodes[event.nodeId];
    if (node == null) return;
    final expanded = {...state.expandedIds};
    final root = _catalogue.candidateById(node.candidateId)?.rootNodeId;
    if (root != null) expanded.add(root);
    if (node.stage != ResearchStage.thesisProblem) {
      expanded.add(StageGroup.idFor(node.candidateId, node.stage));
    }
    final view = _view(expanded, state.filters);
    emit(
      state.copyWith(
        expandedIds: expanded,
        layout: view.layout,
        dimmedIds: view.dimmed,
      ),
    );
  }

  void _onFilters(FiltersChanged event, Emitter<ExplorerState> emit) {
    final view = _view(state.expandedIds, event.filters);
    emit(
      state.copyWith(
        filters: event.filters,
        layout: view.layout,
        dimmedIds: view.dimmed,
      ),
    );
  }

  void _onClearFilters(FiltersCleared event, Emitter<ExplorerState> emit) {
    final view = _view(state.expandedIds, ExplorerFilters.empty);
    emit(
      state.copyWith(
        filters: ExplorerFilters.empty,
        layout: view.layout,
        dimmedIds: view.dimmed,
      ),
    );
  }

  void _onCloseInspector(InspectorClosed event, Emitter<ExplorerState> emit) {
    if (!state.inspectorOpen) return;
    emit(
      state.copyWith(
        inspectorOpen: false,
        focusTick: state.focusTick + 1,
        focusKind: FocusKind.zoomOut,
      ),
    );
  }

  void _onReset(ViewReset event, Emitter<ExplorerState> emit) {
    final fresh = _initial(_catalogue, _layoutEngine);
    emit(
      fresh.copyWith(
        focusTick: state.focusTick + 1,
        focusKind: FocusKind.fitAll,
        outlineVisible: state.outlineVisible,
        minimapVisible: state.minimapVisible,
      ),
    );
  }

  void _onOutline(OutlineToggled event, Emitter<ExplorerState> emit) {
    emit(state.copyWith(outlineVisible: !state.outlineVisible));
  }

  void _onMinimap(MinimapToggled event, Emitter<ExplorerState> emit) {
    emit(state.copyWith(minimapVisible: !state.minimapVisible));
  }

  _View _view(Set<String> expanded, ExplorerFilters filters) {
    return _View.compute(_catalogue, _layoutEngine, expanded, filters);
  }
}

class _View extends Equatable {
  const _View(this.layout, this.dimmed);

  final GraphLayout layout;
  final Set<String> dimmed;

  static _View compute(
    Catalogue catalogue,
    HierarchicalLayoutEngine engine,
    Set<String> expanded,
    ExplorerFilters filters,
  ) {
    final structural = GraphQueries.structurallyVisible(catalogue, expanded);
    final dimmed = <String>{};
    var visible = structural;
    if (filters.constrainsNodes) {
      final matching = <String>{
        for (final id in structural)
          if (catalogue.nodes[id] != null &&
              filters.matchesNode(catalogue, catalogue.nodes[id]!))
            id,
      };
      if (filters.hideNonMatching) {
        final keep = <String>{};
        for (final id in matching) {
          final node = catalogue.nodes[id];
          if (node == null) continue;
          keep.add(id);
          final root = catalogue.candidateById(node.candidateId)?.rootNodeId;
          if (root != null) keep.add(root);
          if (node.stage != ResearchStage.thesisProblem) {
            keep.add(StageGroup.idFor(node.candidateId, node.stage));
          }
        }
        visible = keep.where(structural.contains).toSet();
      } else {
        dimmed.addAll(
          structural.where((id) {
            final node = catalogue.nodes[id];
            return node != null && !matching.contains(id);
          }),
        );
      }
    }
    return _View(
      engine.layout(
        catalogue: catalogue,
        visibleIds: visible,
        expandedIds: expanded,
      ),
      dimmed,
    );
  }

  @override
  List<Object?> get props => [layout, dimmed];
}
