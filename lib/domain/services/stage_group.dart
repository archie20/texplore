import '../enums/research_stage.dart';

/// A circle that stands for one research stage of one thesis problem.
///
/// The id is not a catalogue record. Opening it reveals the records in that
/// stage.
class StageGroup {
  const StageGroup({required this.candidateId, required this.stage});

  static const prefix = 'stage:';

  final String candidateId;
  final ResearchStage stage;

  String get id => idFor(candidateId, stage);

  static String idFor(String candidateId, ResearchStage stage) =>
      '$prefix$candidateId:${stage.wire}';

  static StageGroup? parse(String id) {
    if (!id.startsWith(prefix)) return null;
    final rest = id.substring(prefix.length);
    final split = rest.lastIndexOf(':');
    if (split <= 0) return null;
    final stage = ResearchStage.parse(rest.substring(split + 1));
    if (stage == null || stage == ResearchStage.thesisProblem) return null;
    return StageGroup(candidateId: rest.substring(0, split), stage: stage);
  }
}
