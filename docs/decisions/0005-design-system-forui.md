# 0005. Research-notebook design, with Forui

## Decision

The interface is a white constellation, not a Material app. Light mode is a white field with a faint dot grid. Dark mode stays slate. Nodes are circles. A candidate's colour is the circle's stroke. The selected circle uses the ink accent (`#1E3A5F` in light mode). Details open in a floating popup, not a docked panel.

Forui supplies the controls: buttons, select, text field, tabs, popover, resizable regions, accordion-style sections, and the bottom sheet. The app shell is `WidgetsApp.router` plus `FTheme`. Material widgets are not used for layout or styling. `uses-material-design` stays false. Forui still depends on the Material and Cupertino packages, which is why the web build mentions those icon families. See `docs/deployment.md`.

## Type

Newsreader, Inter, and JetBrains Mono are bundled under `assets/fonts/` from the SIL Open Font License. They are not loaded from Google at runtime, so the app works offline and makes no font request. Newsreader is used for titles. Inter is used for the interface, summaries, and labels. JetBrains Mono is used for ids, DOIs, and stage keys.

## Evidence, drawn and written

Verified, abstract-checked, and metadata-checked claims have a solid circle stroke. Unverified, hypothesis, and needs-literature claims have a dashed stroke. Superseded claims have a dotted, faded stroke. Every circle also prints the status in words under its title.

Hierarchy edges are solid straight lines. Cross-links and the optional literature overlay are dashed straight lines. Neither bends. The path to the selection is drawn in the accent, with one short bright segment travelling along it after the selection changes.

## Motion

The camera eases toward the next frame over about half a second, moving scale and the point under the centre of the screen together. Opening a parent frames that parent and its children. A leaf zooms in. Closing the popup eases out to the surrounding group. A new child eases out of its parent, and a collapsed child eases back in. The selected circle pulses once, then holds still. `MediaQuery.disableAnimations` jumps straight to the settled frame.
