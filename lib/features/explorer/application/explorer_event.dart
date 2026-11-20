import 'package:equatable/equatable.dart';

import 'explorer_filters.dart';

sealed class ExplorerEvent extends Equatable {
  const ExplorerEvent();

  @override
  List<Object?> get props => [];
}

class CandidateSelected extends ExplorerEvent {
  const CandidateSelected(this.candidateId);

  final String candidateId;

  @override
  List<Object?> get props => [candidateId];
}

class NodeSelected extends ExplorerEvent {
  const NodeSelected(this.nodeId, {this.centre = false});

  final String nodeId;
  final bool centre;

  @override
  List<Object?> get props => [nodeId, centre];
}

class NodeToggled extends ExplorerEvent {
  const NodeToggled(this.nodeId);

  final String nodeId;

  @override
  List<Object?> get props => [nodeId];
}

class PathRevealed extends ExplorerEvent {
  const PathRevealed(this.nodeId);

  final String nodeId;

  @override
  List<Object?> get props => [nodeId];
}

class FiltersChanged extends ExplorerEvent {
  const FiltersChanged(this.filters);

  final ExplorerFilters filters;

  @override
  List<Object?> get props => [filters];
}

class FiltersCleared extends ExplorerEvent {
  const FiltersCleared();
}

class InspectorClosed extends ExplorerEvent {
  const InspectorClosed();
}

class ViewReset extends ExplorerEvent {
  const ViewReset();
}

class OutlineToggled extends ExplorerEvent {
  const OutlineToggled();
}

class MinimapToggled extends ExplorerEvent {
  const MinimapToggled();
}
