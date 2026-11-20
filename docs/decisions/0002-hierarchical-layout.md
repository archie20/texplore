# 0002. Hierarchical layout

## Decision

Nodes are placed irregularly, and a child stays within a short reach of its parent so the line between them can be followed without a large zoom. A thesis problem's stages take uneven distances and gaps around that problem. An open stage's records use that same placement: they are not set on a ring or a fan around the stage. Circles already on the canvas ease aside when a new one needs the room. The same ids always land in the same places. A collapsed problem is a single circle. Candidate groups stack downward, and the first non-primary candidate is labelled "Alternative / exploratory".

## Why

The research stages of one thesis problem are a group. Opening the problem places those stage circles at irregular distances and gaps around it. Opening a stage places that stage's records the same way, not as a web around the stage, and does not move the other stages. The thesis-problem circles open in a loose cluster when nothing is expanded. After that every circle is free: it can be dragged anywhere on the canvas and it stays there. There is no stage-label row.

## What it does not do

The layout does not run on pan or zoom. Cross-links and optional literature links stay dashed and do not create extra nodes. Every link is one straight line between circle rims, with no bend and no curve. A circle slides aside when a straight line would cross it or another line. Edges do not participate in cycle detection. The catalogue opens collapsed. Opening a thesis problem reveals its stage circles, and opening a stage reveals that stage's records. A thesis problem in a different candidate folds the open branch away first. Collapsing a stage eases its records back in before they leave the canvas. While one thesis problem is open, the other thesis-problem circles fade out and are omitted from the layout so they are not rendered. The camera frames the parent and the children that just opened, and closing the popup eases out to the group that remains. Dragging a circle eases its neighbours aside and then leaves the circle where it was dropped. Clearance is settled on release. A parent’s move carries its children by the same amount, and the straight lines move with them. A neighbour that would be covered stays aside, so two nodes never rest on top of each other. A new circle keeps the place it was given, and the circles already on the canvas ease clear of it. A later expand does not pull a dropped circle back into a column.
