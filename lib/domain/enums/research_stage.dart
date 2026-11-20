/// The nine research stages. Order is the canonical sequence from Appendix A.
enum ResearchStage {
  thesisProblem('thesis_problem', 'Thesis problem', 1),
  thesisQuestion('thesis_question', 'Thesis question', 2),
  relevance('relevance', 'Relevance and contribution', 3),
  expectedOutcomes('expected_outcomes', 'Expected outcomes', 4),
  thesisAreas('thesis_areas', 'Thesis areas', 5),
  currentStatusQuo('current_status_quo', 'Current status quo', 6),
  literatureGaps('literature_gaps', 'Literature gaps', 7),
  potentialTopics('potential_topics', 'Potential topics', 8),
  researchQuestions('research_questions', 'Research questions', 9);

  const ResearchStage(this.wire, this.label, this.order);

  final String wire;
  final String label;
  final int order;

  static ResearchStage? parse(String? value) {
    if (value == null) return null;
    for (final stage in values) {
      if (stage.wire == value) return stage;
    }
    return null;
  }

  /// A child may stay on the same stage (grouping), move one stage forward,
  /// or use one of the skips the research hierarchy needs.
  bool canParent(ResearchStage child) {
    if (child.order == order) return true;
    if (child.order < order) return false;
    if (child.order == order + 1) return true;
    if (this == thesisQuestion &&
        (child == expectedOutcomes || child == thesisAreas)) {
      return true;
    }
    if (this == thesisAreas && child == literatureGaps) return true;
    return false;
  }
}
