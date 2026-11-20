# Manual checks

Automated tests cover validation, layout, bloc transitions, search exclusion of superseded nodes, the comparison labels, and a widget pass that loads the catalogue, opens a node, and switches to the outline at a narrow width. These still need a person and a browser.

## C14 scenarios to confirm by hand

1. Load the built site and see all six candidate roots in a loose cluster, with every child collapsed. The "Alternative / exploratory" label sits by the first alternative circle.
2. Select each candidate from the menu and confirm the overview replaces the previous one.
3. Open a thesis problem and confirm its research stages sit near that problem at uneven gaps, close enough that the line can be followed without zooming far out, and that the other thesis-problem circles fade away. Open one stage and confirm only that stage's records sit near the stage at uneven gaps, not in a fan and not a long way out, while circles already on the canvas ease aside. Open a thesis problem in a different candidate and confirm the first problem's stages fold away. Click empty canvas and confirm the popup closes and the camera eases out to the surrounding group. The popup itself waits until that flight is mostly there. Drag a circle anywhere and confirm it stays there, with nearby circles and lines easing aside while it moves, and confirm it does not come to rest on top of another circle. Drag a parent and confirm its children, and the straight lines to them, move with it. Open a parent and confirm the circles already on the canvas ease aside for the new ones. Confirm every link is a straight line, and that a circle slides aside instead of letting a line cross a circle or another line. The stage names are not drawn in a row across the canvas. A selected circle pulses once, and the bright segment travels the path once.
4. Select a descendant, collapse its ancestor, and confirm the selection moves to that ancestor.
5. Open a Kente literature-gap node and open each linked publication. Every one should read as unverified, with no invented DOI.
6. From a research question, use the path or the parent control to reach its topic and its gap.
7. Search for a word that appears in a publication title, and one that appears only in a node's detail. Choosing a result should reveal the path, fly the camera to that circle, and open its popup.
8. Turn on "Include superseded" and confirm a superseded record can appear. Turn it off and confirm it leaves the results.
9. Set a stage filter and an evidence filter together, then clear them. Dim is the default. Hide removes non-matching nodes but keeps their ancestors.
10. Add two candidates to comparison, open Compare, and confirm an empty field says "Not specified". Narrow the window and confirm the columns stack.
11. Point the loader at a candidate that is missing a required evidence link and confirm the report names it and the other candidates still draw. The unit tests already cover the rule.
12. Change `schemaVersion` to something other than `1.0.0` and confirm the error screen replaces the canvas.
13. Use only the keyboard: Tab to a circle, Enter to select it, Right arrow to expand a problem or a stage, Left arrow to collapse or move to the stage or problem, and Cmd-K or Ctrl-K to focus search. Escape closes the popup. Opening a problem frames its stages. Opening a stage frames that stage and its records. Collapsing, or closing the popup, eases the camera out to the group that remains.
14. At a width below 600px, use the Outline control, then select a node and confirm the detail is a bottom sheet rather than a side column.
15. Enable "reduce motion" in the operating system and confirm fit and expand do not ease.

## Also worth a look

- Trackpad scroll pans, pinch or the zoom control changes scale, and the minimap recentres.
- A screen reader announces the stage, the title, the evidence status, and whether a branch is expanded.
- Firefox and Safari each paint the tree. Chrome 157 already did: the default load used WebAssembly, and a forced JavaScript load painted the same catalogue. See `docs/deployment.md`.
