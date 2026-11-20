import 'package:equatable/equatable.dart';

import '../../../graph/layout/layout_node.dart';
import 'explorer_filters.dart';

enum FocusKind { none, fitCandidate, centreNode, fitAll, zoomOut }

class ExplorerState extends Equatable {
  const ExplorerState({
    required this.selectedCandidateId,
    required this.selectedNodeId,
    required this.expandedIds,
    required this.filters,
    required this.inspectorOpen,
    required this.layout,
    required this.dimmedIds,
    required this.focusTick,
    required this.focusKind,
    required this.outlineVisible,
    required this.minimapVisible,
  });

  final String? selectedCandidateId;
  final String? selectedNodeId;
  final Set<String> expandedIds;
  final ExplorerFilters filters;
  final bool inspectorOpen;
  final GraphLayout layout;
  final Set<String> dimmedIds;
  final int focusTick;
  final FocusKind focusKind;
  final bool outlineVisible;
  final bool minimapVisible;

  ExplorerState copyWith({
    String? selectedCandidateId,
    bool clearCandidate = false,
    String? selectedNodeId,
    bool clearNode = false,
    Set<String>? expandedIds,
    ExplorerFilters? filters,
    bool? inspectorOpen,
    GraphLayout? layout,
    Set<String>? dimmedIds,
    int? focusTick,
    FocusKind? focusKind,
    bool? outlineVisible,
    bool? minimapVisible,
  }) {
    return ExplorerState(
      selectedCandidateId: clearCandidate
          ? null
          : (selectedCandidateId ?? this.selectedCandidateId),
      selectedNodeId: clearNode
          ? null
          : (selectedNodeId ?? this.selectedNodeId),
      expandedIds: expandedIds ?? this.expandedIds,
      filters: filters ?? this.filters,
      inspectorOpen: inspectorOpen ?? this.inspectorOpen,
      layout: layout ?? this.layout,
      dimmedIds: dimmedIds ?? this.dimmedIds,
      focusTick: focusTick ?? this.focusTick,
      focusKind: focusKind ?? this.focusKind,
      outlineVisible: outlineVisible ?? this.outlineVisible,
      minimapVisible: minimapVisible ?? this.minimapVisible,
    );
  }

  @override
  List<Object?> get props => [
    selectedCandidateId,
    selectedNodeId,
    expandedIds,
    filters,
    inspectorOpen,
    layout,
    dimmedIds,
    focusTick,
    focusKind,
    outlineVisible,
    minimapVisible,
  ];
}
