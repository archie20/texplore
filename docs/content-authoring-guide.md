# Content authoring

The app reads JSON. It does not contain the thesis text in widgets. Edit the files under `assets/data/`, then run the tests. `tool/seed_catalogue.py` can regenerate those files; running it overwrites hand edits, so treat the JSON as the source of truth after you have started editing it.

## Files

`assets/data/manifest.json` lists the catalogue title, `schemaVersion` (`1.0.0`), `lastReviewed`, and the candidate and publication files to load.

Each candidate file has `schemaVersion`, `candidate`, `nodes`, `evidenceLinks`, and `crossLinks`. Publication files have `schemaVersion` and `publications`. Ids are unique across the whole catalogue.

## Stages

Use these keys, in this order: `thesis_problem`, `thesis_question`, `relevance`, `expected_outcomes`, `thesis_areas`, `current_status_quo`, `literature_gaps`, `potential_topics`, `research_questions`.

A child must be the parent's next stage, the same stage (a grouping), or one of these skips: question to expected outcomes, question to thesis areas, thesis areas to literature gaps. Any other skip, or any edge back to an earlier stage, is an error. `parentId` and `childIds` must agree. There is one root, its stage is `thesis_problem`, and its id is `rootNodeId`.

Assumptions, risks, validation requirements, and decisions are lists on the node. They are not extra stages.

## Evidence

A literature gap needs an evidence link, or an `evidenceStatus` of `needs_literature` or `hypothesis`. A potential topic needs a literature-gap ancestor, unless it is marked exploratory (the tag `exploratory`, or status `hypothesis`). A research question needs a potential-topic ancestor.

`gapStrength` (`strong`, `moderate`, `weak`, `unconfirmed`) is optional and only meaningful on a gap. It is not a score.

Node `evidenceStatus` is one of `verified`, `abstract_checked`, `metadata_checked`, `unverified`, `hypothesis`, `needs_literature`, `superseded`. Publication and evidence-link `verificationStatus` is one of `verified_full_text`, `verified_abstract`, `metadata_verified`, `unverified`, `not_accessible`, `disputed`.

## What not to invent

Leave `doi`, `url`, `venue`, and `pages` null unless a source you have actually checked states them. The seeded catalogue marks every publication `unverified` and leaves DOIs null. If a title is a paraphrase, say so in `verificationNotes`. Do not write a novelty claim. Readiness checks are booleans with a note. Feasibility is a planning assessment and must be labelled that way in the text.

## Checks

`flutter test` loads the seeded catalogue and fails if a candidate is excluded or a publication is given a DOI. After editing, run that test and read the in-app report for warnings.
