# Architecture

The Thesis Topic Explorer is a client-side Flutter app. It reads a versioned JSON catalogue, validates it, lays the valid candidates out as circles, and lets a person inspect, search, filter, and compare them. Nothing is scored and nothing is fetched from a citation service.

## Layers

- **Domain** (`lib/domain`): models, the Appendix A enums, and pure services for validation, graph queries, search, and comparison. These files do not import Flutter.
- **Data** (`lib/data`): `LocalJsonDataSource` reads `assets/data/manifest.json`, then the candidate and publication files it lists. `CatalogueRepository` validates that parse and returns a `Catalogue`.
- **Layout** (`lib/graph/layout`): `HierarchicalLayoutEngine` places a thesis problem's stages at irregular distances and gaps around it. An open stage's records use that same placement, not a ring or a fan. `EdgeRouter` joins related circles with one straight line from rim to rim. A circle slides aside when that line would cross it or another line. The layout code is pure Dart.
- **Application** (`lib/features/*/application`): `CatalogueCubit` loads the catalogue. `ExplorerBloc` holds selection, expansion, filters, and the current `GraphLayout`. `SearchCubit` and `ComparisonCubit` stay separate. Pan and zoom live on `ViewportController`, which is a `ChangeNotifier`, not a bloc, because they change every frame.
- **Presentation**: Forui widgets and plain Flutter widgets. The canvas is an `InteractiveViewer`. Nodes are widgets. Edges and the dot grid are `CustomPainter`s.

`ThesisApp` provides the theme, comparison, and catalogue cubits above the router. Once the catalogue has loaded, one `ExplorerBloc`, one `SearchCubit`, and one `ViewportController` are created and kept above the routes, so opening `/compare` does not reset the canvas.

## What causes a relayout

Expansion, path reveal, filters, and reset recompute the layout. Selecting a node that is already open reuses the same `GraphLayout` instance. The catalogue starts collapsed: only the thesis-problem circles are on the lattice until a parent is opened. Those circles open in a loose cluster, near one another rather than in a column. Opening a thesis problem eases its research stages out around that problem at uneven gaps, close enough to trace without a large zoom. Opening a stage eases that stage's records out the same way, not as a fan around the stage. Circles and lines already on the canvas ease aside for the new one. Each straight line grows with the child it belongs to. The camera frames the group that just opened. Closing a stage eases its records back in, then drops them from the canvas. While a thesis problem is open, the other thesis-problem circles fade out and are left out of the layout. Choosing a thesis problem in a different candidate folds the open branch away and shows that problem's stages. Closing the popup eases the camera out to the group that remains. The flight moves the scale and the point under the middle of the screen together, over about half a second, and the popup fades in once that flight is mostly there. Dragging a circle leaves it where it is dropped, and its children move with it so the straight lines between them move too. Nearby circles ease aside while it moves. When it is released, a circle that would be covered, or that would leave a straight line across another circle or line, slides clear. Every link is one straight line. There is no stage-label row.

## Validation and failure

`schemaVersion` must be `1.0.0`. Any other version replaces the canvas with an error screen. A candidate with a blocking error is left off the canvas and listed in the report with the record ids. The other candidates still render. A bad DOI or URL is reported and does not drop the candidate.

## URL

`go_router` keeps the explorer on `/?candidate=&node=&q=&stage=&evidence=&verification=&priority=&tag=&hide=&superseded=&literature=` and comparison on `/compare?ids=`. State is written back with `replace`, so browsing the tree does not fill the session history. The launch URL is applied once, after the first frame.

## Responsive layout

- Choosing a node opens a popup beside that circle. Below 600px the same popup sits along the bottom.
- Below 600px, the canvas is the default view, and an Outline control replaces it with the same tree.

Reduced motion is read from `MediaQuery.disableAnimations`. Viewport moves then jump instead of easing, and node positions are not animated. A leaf selection zooms the camera in. Opening a parent frames that parent and its children. Closing the popup eases back out to the surrounding group.
