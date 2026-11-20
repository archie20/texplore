# Lattice visualization spec

A platform-neutral description of the thesis-topic lattice: circles, straight links, camera, and the circle speaking. Times are milliseconds. Lengths are logical pixels. Colors are sRGB. The same identifiers always produce the same resting places.

This document describes behavior. It does not name a toolkit, renderer, or state library.

## 1. Purpose

Show one or more thesis problems as a living map.

- A thesis problem is one circle.
- Opening it reveals one circle per research stage that has records.
- Opening a stage reveals that stage’s records.
- Related circles are joined by one straight line from rim to rim.
- Selecting a circle frames it, emphasizes the path back to its thesis problem, and the circle speaks under its label.

The map is a workspace for reading. It does not rank topics, invent citations, or score novelty.

## 2. What the view consumes

The view needs a catalogue already validated. It does not fetch or repair records.

### 2.1 Thesis problem (candidate)

- Stable id.
- Root record id (the thesis-problem node).
- Optional priority: primary, or alternative / exploratory.
- The first non-primary problem may carry the banner “Alternative / exploratory”.

### 2.2 Record (node)

- Stable id, unique in the catalogue.
- Candidate id.
- Stage, one of the nine stages in section 3.
- Title. The thesis-problem title is the research problem statement.
- Optional short summary.
- Parent id and ordered child ids. The parent is a content parent. On the canvas the visible parent of a record is its stage circle, not necessarily this content parent.
- Evidence status (section 5.4).
- Sort order, used only to break ties.

### 2.3 Stage circle

A stage circle is not a catalogue record. Its id is:

```text
stage:{candidateId}:{stageWire}
```

It exists only while that candidate has at least one record in that stage. It is the visible parent of those records.

### 2.4 Link

- Structural link: from a thesis problem to each of its stage circles, and from a stage circle to each of its records. Solid. These define parent and child on the canvas.
- Cross-link: a dashed relation that does not define parent or child and does not move children when a circle is dragged.
- Optional literature overlay: dashed lines between records that share a publication. Drawn only when that overlay is on. Not part of layout, clearance, or drag.

Every drawn link is one straight segment between two circle rims. No bends. No curves. No arrowheads.

## 3. Stages

Canonical order:

| Order | Wire | Short label on the circle |
| --- | --- | --- |
| 1 | `thesis_problem` | the problem statement, not the stage name |
| 2 | `thesis_question` | Thesis question |
| 3 | `relevance` | Relevance |
| 4 | `expected_outcomes` | Expected outcome |
| 5 | `thesis_areas` | Thesis area |
| 6 | `current_status_quo` | Status quo |
| 7 | `literature_gaps` | Literature gap |
| 8 | `potential_topics` | Potential topic |
| 9 | `research_questions` | Research question |

A content parent may keep a child on the same stage, move one stage forward, or use these skips: thesis question may parent expected outcomes or thesis areas; thesis areas may parent literature gaps. The canvas does not draw that content tree directly. It draws problem, then stage circles, then records.

## 4. What is on the canvas

Children start collapsed.

- With every problem collapsed, every thesis-problem circle is visible, in one loose cluster. Nothing else is drawn.
- Opening a problem shows that problem and one circle for each of its stages that has records. Other thesis-problem circles fade out in place and are omitted from layout and rendering.
- Opening a stage shows that stage’s records. Other stages of the same problem stay as they are.
- Closing a stage eases its records back into the stage circle, then removes them.
- Choosing a thesis problem while another problem is open collapses the open branch first, then opens the new problem’s stages.
- A filter may hide non-matching records, or dim them to 32% opacity. Stage circles and the problem stay if any kept record needs them. Superseded records stay visible unless a filter removes them. They are also drawn at 50% opacity.
- Reset returns to the collapsed cluster. Circles that remain keep the homes they were dragged to. Expanded children are removed. Their stored positions are forgotten and, if opened again, they bloom from the parent’s current home.

Hidden circles are not hit-tested and do not affect placement.

## 5. Visual language

White paper by default. A dark paper is allowed; the roles below stay the same. Stage color is the only strong hue. Ink is a warm neutral, not a blue accent.

### 5.1 Color roles

| Role | Light | Dark | Use |
| --- | --- | --- | --- |
| Paper | `#FFFFFF` | `#16181D` | Canvas |
| Card | `#FFFFFF` | `#1E2128` | Circle fill base |
| Hairline | `#E6E6E6` | `#2C3038` | Minimap border |
| Ink | `#2C2622` | `#E7E0D4` | Selected circle, path, labels of the selected circle |
| Ink, soft | ink at 13% | ink at 20% | Quiet washes |
| Edge | `#D0D0D0` | `#3A404C` | Resting links |
| Edge, muted | `#E3E3E3` | `#2A303A` | Cross-links and literature lines |
| Dot | `#C4C4C4` | `#2A2E36` | Background dots |
| Banner | `#8A8A8A` | `#A39E96` | “Alternative / exploratory” |

Stage ticks, one per candidate, in order, then repeating:

Light: `#2B4C7E`, `#3E6B5A`, `#8A5A2B`, `#5C4D7A`, `#3D6A78`, `#7A4E4E`.

Dark: `#8EAFD6`, `#7DAB96`, `#D0A06A`, `#B3A4D4`, `#7EB4C2`, `#D4A0A0`.

A circle’s resting stroke is its candidate’s tick. Fill is the card mixed with that tick at 10% (20% was used earlier; the selected fill uses 46%). Selected and path circles use ink, as in section 11.

### 5.2 Circle sizes

| Kind | Diameter | Caption height under the circle | Layout width |
| --- | --- | --- | --- |
| Thesis problem | 84 | 72, up to 4 lines | 168 |
| Thesis question, research question | 68 | 36, up to 2 lines | 148 |
| Every other stage and record | 58 | 36, up to 2 lines | 148 |

The layout box is the width above and `diameter + caption height` tall. The circle sits at the top of the box, horizontally centered. The label sits 6 px under the circle. Edges attach to the circle, never to the label.

Labels: thesis problem shows the problem statement. A stage circle shows the short stage label. A record shows its title. Overflow is ellipsis. Do not put evidence status, year, or venue on the circle.

Icon inside the circle: a small stage glyph, 20 px on a thesis problem and 16 px otherwise. It stays upright. It moves with the circle’s drift and scale. It does not spin.

### 5.3 Stroke

Resting and selected strokes are the same weight: 1 px. Do not thicken the stroke to show selection.

- Solid: verified, abstract checked, metadata checked. Also stage circles and the thesis problem, which have no evidence status.
- Dashed: unverified, hypothesis, needs literature. Dash 5, gap 3.5. Only while the circle is not selected.
- Dotted: superseded. Dot 1.6, gap 3. The circle is also at 50% opacity. Only while not selected.

A selected circle is drawn solid even if its status is dashed or dotted. The status remains available in the words under the circle and to assistive text.

### 5.4 Background

A square lattice of dots, spacing 34, radius 0.9, in the dot color. The grid does not pan independently of the paper; it is part of the canvas and moves with pan and zoom. It is not a node and is not hit-tested.

## 6. Placement

### 6.1 Homes

Each visible circle has a home: the place it returns to when it is not being dragged. A home is either the seeded scatter position or the last place the person dropped it.

A later layout must not pull a dropped circle back to the seeded spot. Children that appear for the first time are placed relative to the parent’s current home. Children that were hidden lose their stored position.

### 6.2 Seeded scatter

Seed a deterministic hash from the circle’s id (FNV-1a, 32-bit, nonzero). From that seed, pick an angle and a distance. The same ids always land in the same places.

Rules:

- Thesis-problem circles, when all are collapsed, form a loose cluster. They are not in a column and not on a ring.
- Stage circles scatter around their thesis problem. Distances and gaps are uneven. They are not on a ring, a fan, or a fixed step.
- Records scatter the same way around their stage circle, biased toward the outer side of the stage (about 3.6 radians of sweep), not as a web, fan, or chain.
- Extra distance past a clear gap is at most 150. A child must stay close enough that the line to its parent can be followed without a large zoom. A practical check: every child center within 580 of its parent center.
- Clearance between layout boxes is 16. Line-to-circle padding is 12.
- Circles already on the canvas ease aside to make room. They are not pushed onto a huge ring.

Two straight links that share an endpoint are not a crossing. A line through a circle, or a line crossing another line, is. When a new circle or a released drag would cause that, slide the circles apart inside the short reach. Do not bend the line.

Packing every stage of a large problem open at once, inside the short reach, cannot always be both overlap-free and line-clear. Single-stage layouts and short chains must stay overlap-free and line-clear. The fully open case only has to keep children inside the short reach.

### 6.3 Drag

- A circle can be dragged anywhere and stays where it is dropped.
- While it moves, neighbors ease aside so it does not rest on them.
- On release, if it would cover another circle, or leave a straight line across a circle or another line, it slides clear. Clearance is 16.
- Dragging a parent translates its visible descendants by the same delta. Structural links move with them. Cross-links and literature lines do not define descendants.
- The drag should feel continuous. A movement under about 20 px is still the idle wander, not a drag.

## 7. Links

For each structural or cross edge, compute the two circle centers, then the point on each rim in the direction of the other center, then inset by about 3 px so the stroke does not bury the rim. Draw one straight segment.

If the circles carry a wander offset (section 9.4), add that offset to each endpoint before drawing. The segment stays straight. Each end stays on its circle.

Style:

- Structural, resting: edge color, width 1.15, round caps.
- On the emphasized path: ink, width 1.8.
- Cross-link or literature: muted edge, dashed (dash 7, gap 5).
- A link is on the emphasized path only when both ends are on the route (section 11.2) and it is not a cross-link. Sibling links are ink as well when both ends are in the focus set, but the traveling comet runs only on the route.

## 8. Camera

The camera stores a scale and the scene point under the center of the viewport. Pan and zoom change every frame and are not part of the layout.

- Scale limits: 0.02 to 3.2.
- Fit a rectangle with 56 px of padding, then clamp the scale. When a circle is speaking, leave about 96 px more at the bottom so the words clear the toolbar.
- A flight interpolates scale and the scene point under the viewport center together, with an ease-out cubic, over 450 to 700 ms. Duration grows with the change in scale and the pan distance, inside that range.
- Opening a problem frames that problem and the stage circles that just appeared, at their resting homes.
- Opening a stage frames that problem’s open circles for that stage.
- Selecting a deeper record may zoom by about `1.58` per step along the path.
- Closing the spoken reading eases back out to the group that remains.
- Zoom in and zoom out keep the scene point under the center fixed.
- The scene may extend above and to the left of the layout origin. Hit testing and drawing must include that region. A practical approach is a large empty margin (on the order of 16000) around the scene, with the camera compensated so the origin still appears where it did. A circle dragged more than that margin past the left or top may miss hits. The right and bottom grow with the live extents.

The spoken reading waits until the flight is at least 70% complete, then fades in.

## 9. Motion

Respect a user setting for reduced motion (section 13). Otherwise:

### 9.1 Bloom and fold

- A new child starts at its parent’s center, invisible, and eases out to its home. Opacity and scale go from about 0.2 to 1 as it travels. It does not receive presses until it has arrived (presence at least 0.98, and within about 0.6 px of home).
- Siblings stagger by 45 ms times their ordinal.
- Closing eases the child back into the parent over the same kind of travel, then removes it.
- Thesis problems that leave because another problem opened fade in place. They remember their homes.
- Presence ramps in about 320 ms.

### 9.2 Idle life

One shared clock. Do not give each circle its own ticker.

- Ring rotation: one full turn every 14.5 s, the same angular speed for every circle, including the thesis problem. A larger circle’s mark travels farther along the rim and can look quicker. Phase is a hash of the id in `[0, 1)`, so circles do not share a start angle.
- The thing that turns is the circle’s own stroke. A dashed or dotted ring turns its dashes or dots. A solid ring is rotationally symmetric, so one stretch of the same stroke is lighter (about 82% toward white) and that stretch travels with the circle. Do not paint a second highlight on top of a dashed or dotted ring.
- The icon and the label do not rotate.
- Drift: a smooth wander unique to the id, amplitude about 5.2 px, built from several sine waves whose phases and tempos come from a hash of the id. It does not breathe (no idle scale pulse). The circle, the icon, and the label share one offset. Link endpoints use the same offset. The path should not look like one shared oval.
- Hover scale 1.07. Keyboard focus scale 1.09. Both ease over 240 ms, ease-out cubic. They stay smaller than the selected scale.

Rasterize the icon and the label once and move those layers. Do not redraw and re-hint the glyphs on every tick, or the motion looks like it is snapping.

### 9.3 Selection grow

When selected, the circle scales about its center by `(84 + 6) / 58`, about 1.55. The smallest circle becomes 90 px across, larger than any unselected child (the largest unselected child is 68). Larger circles grow by the same factor.

The label is not scaled by that factor. It drops by half the growth, `(scale − 1) × diameter / 2`, so the 6 px gap under the grown circle remains. The circle’s layout slot grows by that drop so the label is not clipped and is not covered. Animate the grow and the drop together, 240 ms, ease-out cubic.

On selection, also play one pulse of about 8% over 320 ms, then settle at the selected scale. Fill mixes the tick into the card at 46%. A soft ink shadow sits just outside the rim: ink at 16% opacity, blurred about 22 px, only a few pixels beyond the stroke. The shadow must stay subtle. The label under the selected circle is one step larger (12 px, or 13 on a problem) and heavier.

### 9.4 Path comet

While a circle is selected, one bright segment, about 32 px long and 2.6 px wide, in ink, travels the structural route from the thesis problem to that circle. It wraps from the end back to the start with no pause. Sibling links do not carry this segment. The loop is about 1.2 s.

Order the route by walking from the circle that is only a source (the thesis problem) along structural links whose both ends are on the route.

## 10. Hit testing and pointer

- The whole circle-and-label stack is one press target, including while the circle is scaled.
- Pressing a circle selects it and does not also count as a press on empty canvas.
- Empty paper and Escape close the spoken reading and ease the camera out. A press on the words does not.
- The reading does not dim the paper. A circle elsewhere can still be selected. An empty press still dismisses.
- Drag and tap are distinct. A small wander must not count as a drag.

## 11. Selection and emphasis

### 11.1 Route

The route is the chain from the thesis problem to the selected circle.

- Thesis problem: only itself.
- Stage circle: the problem and that stage.
- Record: the problem, that record’s stage circle, and the record.

### 11.2 Focus set

The focus set is the route plus every circle at the same level as the selection.

- A selected stage circle focuses every stage circle of that problem, and the problem.
- A selected record focuses every record in that same stage, the stage circle, and the problem.
- A selected thesis problem focuses only itself.

Focused circles that are not selected use a stroke 45% of the way from their tick color to ink. They do not grow. The selected circle is full ink, grown, with the soft shadow and the stronger label.

Structural links with both ends in the focus set use the ink link style. The comet runs only along the route.

## 12. The circle speaks

Selecting a record makes that circle speak under its label. There is no second surface: no card, no tether, no docked panel. Stage circles do not speak. Selecting a thesis problem from outside the canvas, with no record chosen, makes that problem’s circle speak when the circle is on the layout.

### 12.1 Reading

The words are about 236 wide, centered under the circle, and they drift with it. They begin just below the label.

In order:

- The title, in the serif, about 18 px, in ink.
- A 1 px rule in that problem’s tick color. The rule uses the record’s evidence stroke: solid, dashed (5 on, 3.5 off), or dotted (1.6 on, 3 off). A problem-level reading is solid.
- The stage’s short label, the evidence status in words, and a gap strength when the record has one, separated by a middot.
- One paragraph: the summary, in the sans, about 14 px. An empty summary is omitted.
- When a literature gap, or any record that still needs literature, has no linked publication: “Evidence still being reviewed. No publication is linked to this record yet.”
- The word More, when there is more to read. Add to comparison stays with these first words for a problem-level reading.

The first words stay within about 188 of the label, so the circle can still be read as the speaker. More stays at the bottom of that block. More blooms the longer note inside the same reading, the way a child blooms from a parent: the extra paragraphs grow from their top, from about 0.2 scale and opacity to 1, over about 320 ms. The block may grow to about 300 and then scrolls. Less folds the extra paragraphs away. They hold the explanation, assumptions, risks, validation, notes, evidence claims, the content parent (“Follows from …”), content children (“Leads to …”), and the review date. A claim’s citation replaces those paragraphs with the publication; Back returns to the record. Missing venue, DOI, pages, and authors stay missing. A problem-level longer note holds contribution, relevance, data, evaluation, feasibility, risks, readiness, and open decisions. Feasibility is described as a planning assessment, not a measured score. Readiness is described as a checklist, not a score.

The path is already drawn on the canvas, so the reading does not repeat it as controls.

### 12.2 Camera

The camera holds the spoken words in frame together with the circle. Opening a problem still frames that problem’s circles, and the frame also includes the words under the problem. A deeper record keeps its zoom and shifts the focal point downward so the paragraph stays in view. The words follow the circle’s drift and its drag.

### 12.3 Chrome

There is no border, shadow, radius, veil, tab bar, badge, or traveling highlight. The paper color sits behind the words so the dot grid does not run through the type. The entrance waits until the camera flight is at least 70% done, then fades the words from opacity 0 to 1 over 280 ms, ease-out cubic. The first words do not scale. The longer note does, because it is blooming.

### 12.4 Dismiss

Escape, and a press on empty paper, close the reading and ease the camera out. A press on another circle selects that circle instead. A press on the words does not close them.

## 13. Reduced motion

When the person has asked for reduced motion:

- Camera jumps. The spoken reading appears at full opacity. The longer note does not bloom.
- Circles do not rotate, wander, bloom, or fold. They appear and disappear at their homes.
- No path comet.
- Selection still grows, without the pulse, or the grow is instant. Prefer instant.

## 14. Keyboard and assistive text

- The circle is a button. Its accessible name is richer than the visible label: stage, title, evidence status, and whether it is expanded.
- Enter or Space selects. Arrow right opens a collapsed parent. Arrow left closes an expanded parent, or moves to the visible parent.
- Visible parent of a record is its stage circle. Visible parent of a stage circle is the thesis problem.
- Focus ring is a 2 px ink circle around the whole stack, separate from the stroke.
- The canvas itself is one landmark. Do not expose every circle as its own accessible node if that overwhelms the platform; keep names on the spoken reading and on an optional text outline of the same tree.

## 15. Text outline

Below 600 px, offer a control that replaces the canvas with the same visible circles in reading order. Indent by stage order. The same selection, expansion, and dimming apply. This is a reading aid, not a second layout.

## 16. Invariants

- A circle never rests on another circle, except the known limit when every stage of a large problem is open inside the short reach.
- A structural line is straight, meets both rims, and does not cross another circle or another line when the layout can prevent it.
- Dashed and dotted rings rotate their own pattern. Nothing else is animated on top of those strokes.
- The icon and the label do not rotate. They do wander with their circle.
- The selected circle is larger than the other children, without a heavier stroke.
- A selected circle speaks under its own label. The longer note blooms from that circle.
- The view does not invent a DOI, venue, page, or author. Missing fields stay missing.

## 17. Reference constants

| Name | Value |
| --- | --- |
| Box clearance | 16 |
| Line padding | 12 |
| Max extra child distance | 150 |
| Child-within-parent check | 580 |
| Sibling bloom stagger | 45 ms |
| Bloom / fold presence | about 320 ms |
| Camera flight | 450–700 ms, ease-out cubic |
| Spoken width | about 236 |
| Spoken entrance | 280 ms fade, ease-out cubic, after flight ≥ 0.7 |
| Longer-note bloom | 320 ms, from 0.2 scale and opacity |
| Selection grow | 240 ms, ease-out cubic, scale (84 + 6) / 58 |
| Selection pulse | 320 ms, +8%, once |
| Hover / focus scale | 1.07 / 1.09 |
| Ring turn | 14.5 s |
| Drift amplitude | 5.2 |
| Path comet | about 32 × 2.6, loop about 1.2 s |
| Stroke | 1 |
| Dot spacing / radius | 34 / 0.9 |
| Label gap under circle | 6 |
| Gap under the label before the words | 8 |
| First words, max height | about 188 |
| Longer note, max height | about 300 |
| Speech clearance above the toolbar | about 96 |
| Viewport inset | 12 |
| Narrow breakpoint | 600 |
