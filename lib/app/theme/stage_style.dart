import 'package:flutter/widgets.dart';
import 'package:forui_lucide/forui_lucide.dart';

import '../../domain/enums/research_stage.dart';

class StageStyle {
  const StageStyle(this.label, this.icon);

  final String label;
  final IconData icon;

  static StageStyle of(ResearchStage stage) {
    return switch (stage) {
      ResearchStage.thesisProblem => const StageStyle(
        'Thesis problem',
        FLucideIcons.target,
      ),
      ResearchStage.thesisQuestion => const StageStyle(
        'Thesis question',
        FLucideIcons.circleQuestionMark,
      ),
      ResearchStage.relevance => const StageStyle(
        'Relevance',
        FLucideIcons.scale,
      ),
      ResearchStage.expectedOutcomes => const StageStyle(
        'Expected outcome',
        FLucideIcons.fileText,
      ),
      ResearchStage.thesisAreas => const StageStyle(
        'Thesis area',
        FLucideIcons.layers,
      ),
      ResearchStage.currentStatusQuo => const StageStyle(
        'Status quo',
        FLucideIcons.bookOpen,
      ),
      ResearchStage.literatureGaps => const StageStyle(
        'Literature gap',
        FLucideIcons.triangleAlert,
      ),
      ResearchStage.potentialTopics => const StageStyle(
        'Potential topic',
        FLucideIcons.tag,
      ),
      ResearchStage.researchQuestions => const StageStyle(
        'Research question',
        FLucideIcons.circleQuestionMark,
      ),
    };
  }
}
