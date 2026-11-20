# 0003. Local JSON content

## Decision

The catalogue is versioned JSON in the app's assets. A manifest lists per-candidate files and publication files. The loader merges them into one in-memory catalogue. There is no database, no account, and no live citation lookup.

Models use hand-written `fromJson`. There is no `build_runner`.

## Why

The research text has to be reviewable in git, editable without a backend, and available offline. One file per candidate stays small enough to author. The manifest is what the app actually loads, so a file that is not listed is not part of the catalogue.

## Failure policy

An unsupported `schemaVersion` stops the whole app. A candidate that fails validation is omitted and reported. The remaining candidates still render. Parse errors are turned into that same report rather than an uncaught exception.
