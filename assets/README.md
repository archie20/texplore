# Thesis Topic Explorer — Research Data Update (25 November 2026)

This archive contains the complete `assets/data/` directory for the existing Thesis Topic Explorer application. Replace the repository's `assets/data/` directory with this one. No Flutter source code, UI, routing, layout, or schema version has been changed.

## What changed

- Updated the crop-disease candidate to focus on cross-domain confidence calibration and selective prediction under geographic/acquisition shift. Leakage-resistant splitting is retained as an experimental control.
- Added checked literature/data records for the PaddyDoctor calibration study, PALM-Net, EffiToRag, ARTEN, SAGE, the Gookyi Ghana field-trial dataset, and updated CCMT metadata.
- Explicitly records that Gookyi's dataset description does not provide disease labels, and ARTEN is a derivative dataset rather than new field observations.
- Updated the Kente candidate around a Kente-specific formal representation linking motif, weave structure and loom operations for one specified loom context.
- Added the 2024 and 2026 Vigbedor et al. Ghanaian indigenous-loom studies. The data explicitly distinguishes modified two-heddle/countershaft and four-to-six-shaft systems from the traditional Bonwire narrow-strip loom.
- Preserved all six candidates, all pre-existing records and all existing unverified literature leads. The four candidates not directly affected by the latest research remain unchanged.

## Research integrity

- New source records are marked `verified_abstract` or `metadata_verified`, not `verified_full_text`, because this update checked publisher/author pages and abstracts rather than independently auditing every full text and experiment.
- Reported experimental values are attributed to the source authors; they are not independently reproduced here.
- Candidate gaps remain hypotheses unless a systematic review establishes them.
- No DOI, venue, page range, or author was invented.

## Files

The archive preserves the application's existing layout:

- `assets/data/manifest.json`
- `assets/data/candidates/*.json`
- `assets/data/publications/*.json`

## Validation performed

All JSON files parse; schema versions remain `1.0.0`; node, parent/child, evidence-link and publication references were checked; stage progression and global ID uniqueness were checked. This is a data-level validation, not a Flutter runtime or browser test.
