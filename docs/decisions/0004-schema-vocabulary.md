# 0004. Schema vocabulary

## Decision

Where the specification disagrees with itself, Appendix A wins. It is the section titled canonical.

- Stage keys are the Appendix A3 keys: `thesis_problem`, `thesis_question`, `relevance`, `expected_outcomes`, `thesis_areas`, `current_status_quo`, `literature_gaps`, `potential_topics`, `research_questions`. The names in section 3.3 are not stored.
- A node's `evidenceStatus` uses the Appendix A7 values, including `abstract_checked`, `metadata_checked`, `needs_literature`, and `superseded`.
- A publication's and an evidence link's `verificationStatus` uses the Appendix A5 values. The `metadata_unverified` string from the functional requirements is stored as `unverified`.
- `relationship` and `evidenceStrength` use the Appendix A5 values. The gap labels `strong`, `moderate`, `weak`, and `unconfirmed` are an optional `gapStrength` on literature-gap nodes only.
- Assumptions, risks, validation requirements, and decisions are arrays on the node, not extra nodes. That keeps the nine-stage spine intact.

## Stage order

A child's stage is strictly later than its parent's, or the same stage when a group is being split, except three skips the research tree needs:

- `thesis_question` to `expected_outcomes`
- `thesis_question` to `thesis_areas`
- `thesis_areas` to `literature_gaps`

Any other skip, and any backwards edge, is an error. Cross-links are not part of this order and are not part of cycle detection.

## Why these exceptions exist

Section 3.2 branches relevance, outcomes, and areas from the question, and it lets an area point at a gap. A rule that allowed only the next stage would reject that tree. The skips are named so the validator still rejects an accidental jump.
