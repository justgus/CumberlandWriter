Requirements: MurderBoardView
Spec Version: 1.3
Last Updated: 2025-10-20

Authoritative Specification (verbatim - this is the source of truth for all implementation details)

 Definitions and Invariants (non-numbered, normative where referenced)
 - Coordinate spaces:
   - View space: origin at the View Window’s top-left; +x to the right; +y downward.
   - World space: an independent, conceptually unbounded Cartesian plane measured in points; +x to the right; +y downward.
 - Transform:
   - World→View mapping is v = w*S + T, where S is the scalar zoom factor and T = (Tx, Ty) is the view-space translation (pan).
   - The View Canvas Rectangle is the exact inverse image of the View Window’s bounds under the current transform (see 0080, 0110).
 - Z-ordering (0232):
   1) Grid background (bottommost), 2) Edges, 3) CardViews (nodes), 4) selection/interaction overlays (topmost).
 - Reset operation:
   - A reset is an explicit action that removes all nodes from the board. During and immediately after reset, primary presence enforcement is suspended (0286).
 - Primary enforcement:
   - When enforcement is active and a Primary is set, the Primary must be present as a node; the system may auto-create a BoardNode if missing.

 The Murderboard View
  0010 - The View shall be a Window to a View Canvas
  0020 - The View Window shall have a rounded rectangular border around it at least 10 points thick that separates its contents from the enclosing application.
  0030 - The View Window Border shall have a visible inner drop shadow. so that it appears above the view it is showing and the View Canvas appears inside the border.
  0040 - The View Window and its border shall fill the contents of its parent view
  0050 - The View Window shall provide a view of its content called the View Canvas.
  0052 - The View Window and its border shall appear on top of all View Canvas content
  0054 - The View Canvas shall be clipped by both the View Window and its border.
  
  View Canvas
  0060 - There shall be view inside the View Window called the View Canvas.
  0061 - The View Canvas shall appear infinite in size.  That is, at no time will the border of the View Canvas be visible in the View Window.
  0065 - The View Canvas shall define an independent, unbounded world coordinate system.
  0066 - The pan translation T may be clamped to an implementation-defined range large enough to cover the Nodes Extents (0150) plus the margin defined in 0405 under all expected pans/zooms.
  0070 - The View Window shall present a rectangular viewport into this world. The visible region of the world is called the View Canvas Rectangle.
  0080 - The View Canvas Rectangle shall be defined as the exact inverse image of the View Window’s bounds under the current pan and zoom transform; i.e., after applying the world-to-view transform, the View Canvas Rectangle maps exactly to the View Window’s bounds, so it always fills the View Window regardless of pan or zoom. The inverse mapping shall be computed analytically from the current transform.
  0090 - As the zoom factor decreases (zooming out), the View Canvas Rectangle shall increase in size while keeping its center locked to the View Window's center (see 0330).
  0100 - The zoom factor expansion shall not move or resize the View Window in its parent; only the mapping changes.
  0110 - The View Canvas shall continuously recompute the View Canvas Rectangle whenever the View Window size, pan, or zoom changes. The recomputed rectangle shall be consistent with the current transform and shall remain the unique world-space rectangle that maps exactly to the View Window’s bounds.
  0120 - The View Canvas shall display nodes and edges.
  0130 - The View Canvas nodes shall be Cards that are displayed using a CardView.
  0140 - The View Canvas shall maintain a point in world coordinates representing the center of the View Window’s position.
  0150 - Node, their positions in the View Canvas, and their size, will be used to calculate a Nodes Extents rectangle that encompasses all Nodes currently in the View Canvas
  0160 - The Nodes Extents rectangle shall take into consideration the size of the CardView when calculating the area to enclose, using each CardView’s world-space bounding box, including any necessary padding for shadows and selection borders.
  0170 - When new nodes are added to the view, nodes are moved to new positions, or removed from the view, the Nodes Extents Rectangle shall be recalculated.
  0180 - There shall be an optional “primary” node that will be a Card selected from a list in the Main App’s Content List.
  0190 - Edges in the View Canvas shall be line segments representing a CardEdge source to target relationship between two Cards that have been added to the view.
  0200 - Even if the Cards have more than one relationship between them, only one line segment shall represent the relationship between the two Cards in the View Canvas.
  0202 - If multiple relationships exist between the same two Cards, the single displayed edge shall be chosen deterministically (e.g., by a RelationType priority list; if tied, by earliest creation date; if unavailable, by a stable UUID order). Unless otherwise specified, the edge is visually undirected and carries no label.
  0210 - Edges shall be straight line segments that span from the center of the source CardView to the center of the target CardView.
  0220 - Edges shall be at least three points thick and shall remain clearly visible against the View Canvas background in both light and dark appearances.
  0222 - Edges shall be colored using a three color gradient.
  0224 - From source node to target node the Edge colors shall be 1 - the border color of the taget node, 2 - the grid contrast color (dark or light depending on the display mode), and 3 - the border color of the source node.
  0225 - Edges and selection borders shall maintain sufficient contrast in both light and dark appearances; colors shall adapt to system appearance.
  0230 - Edges on the murder board shall be displayed just behind the CardViews.
  0232 - Z-order shall be: (1) the Grid background (bottommost), (2) Edges, (3) CardViews (nodes), and (4) selection/interaction overlays (topmost).
  
  Behavior
  0240 - On first display of the MurderBoardView, if a target node exists (the Primary if present, otherwise the first node), the View Canvas shall automatically pan so that the target node’s world position is projected to the geometric center of the View Window.
  0241 - On first display, apply 0405 so the View Canvas Grid is sized such that its edges are not visible in the View Window.
  0250 - The initial recentering shall occur once per initial display and shall not change the zoom level.
  0260 - If the Primary or first node’s stored world position is uninitialized (e.g., nullable coordinates or an explicit “uninitialized” flag), its position shall first be set to the center of the current View Canvas Rectangle.
  0270 - Once the uninitialized position is reset, the View Window shall be panned so that this position is centered in the View Window.
  0280 - Except during a reset operation (0284), the Primary, if present, shall not be removed from the View Canvas. If not present, then all nodes may be removed from the board.
  0282 - If the Primary is changed, the View Canvas shall update the display.
  0284 - If the view is reset (i.e., all nodes removed), then the Primary may be removed and the Board’s primaryCard may be cleared.
  0286 - During and immediately after a reset operation, automatic primary presence enforcement shall be suspended until a new Primary is explicitly assigned. If the Primary card is deleted from the database, the board’s primaryCard is cleared and enforcement suspended until a new Primary is assigned.
  0300 - Zoom shall not change node world positions; only the mapping between world and view coordinates changes.
  0310 - When the parent view’s size changes, the View Window shall resize to fill its parent (0040), recompute the View Canvas Rectangle (0110), and preserve the current zoom/pan mapping semantics.
  0330 - When Zooming, the View Canvas's center point will remain fixed to the View Window's Center point; pan shall be adjusted analytically to maintain this invariant.
  0340 - Nodes in the View Canvas shall be selectable.
  0350 - When selected, the Card’s CardView shall display a border over it in the accent color of the Cumberland App.
  0360 - Nodes shall be able to be dragged via a standard click drag gesture on the Node
  0362 - Node hit-testing for selection and drag shall be limited to the CardView’s visual card-shape bounds as reported by the CardView (excluding outer padding, shadows, and adornments).
  0364 - The hit rectangle shall not exceed these visual bounds.
  0365 - The hit rectangle shall be scaled by the current zoom factor and centered on the node’s world position projected into view space. If a visual size has not yet been reported, a measured layout size may be used as a temporary fallback.
  0370 - When a node in the View Canvas is dragged, its position shall be updated based on the pointer's location over the View Canvas Rectangle, taking zoom and pan into account, and preserving the initial grab offset so the node follows the pointer smoothly.
  0380 - The View Canvas shall be able to be panned via a standard click drag operation on the View Canvas surface
  0390 - When the background area of the View Canvas is dragged it shall allow the whole view to be panned
  0400 - Per 0040, the View Canvas shall always resize itself to fill the View Window regardless of the pan or zoom factor.
  0402 - The View Canvas shall have a background surface called the View Canvas Grid, consisting of a low-contrast grid (bottommost) and the Edges (above the grid, but below the nodes).
  0405 - The View Canvas Grid shall be sized in world space to fully cover the union of (a) the current View Canvas Rectangle (0080) and (b) the Nodes Extents Rectangle (0150), inflated on all sides by a zoom-aware margin M sufficient to prevent drawing-surface edges from becoming visible during pan or zoom. M shall be at least one View Window diagonal expressed in world units (windowDiagonal / S), or 2×tileSize, whichever is larger.
  
  Controls
  0410 - The View Window shall have a toolbar.
  0420 - The View Window toolbar shall include a zoom control.
  0430 - The zoom control shall allow the specification of zoom percentages from 1% to 200% with 100% being the default.
  0435 - The zoom factor S shall be clamped to the inclusive range [0.01, 2.0]. Text entry shall clamp to [1, 200]% and round to the nearest integer; non-numeric input is ignored.
  0440 - The toolbar shall have a “recenter” button.
  0450 - the recenter button shall pan the View Canvas so that the first node, or the primary node if one is present, is in the center of the View Window.
  0452 - If the target node’s position is uninitialized, it shall be initialized per 0260 prior to recentering. Recenter shall not change the zoom level (0250).
  0460 - The toolbar shall have a “shuffle” button.
  0470 - the shuffle button shall gather all the nodes around the first node, or the primary node if one is present in a random arrangement.
  0475 - Shuffle shall preserve the Primary’s position (if present) and reposition all other nodes in world coordinates. New positions shall be persisted; edges shall update automatically from node centers.
  0480 - repeated clicks of the shuffle button will change the position of all the nodes in the arrangement.
  
 Persistence
  0490 - The Murderboards shall persist in the database using the Board model object
  0500 - There shall be a helper object, called a BoardNode
  0510 - The BoardNode shall bridge the relationship between Cards and Boards
  0520 - The relationship between Cards and Boards shall be a many-to-many relationship
  0530 - Cards shall be able to have no Boards that they appear in.
  0540 - Boards shall be able to be displayed with no Cards as nodes unless a Primary is set; during a reset operation, the Primary may be removed and/or cleared.
  0550 - Nodes in the View Canvas shall be persisted in the database using a fully inverted relationship between Card and Board.
  0560 - Selection of a Card in the View Canvas shall persist until the operator clicks on another Card, at which point selection shall switch to the card clicked.
  0570 - Selection of a Card in the View Canvas shall persist until the operator clicks in the Canvas area of the View Canvas, at which point the selection shall be dropped and no Card is selected.
  0572 - Node centers shall be stored in the backing model in world coordinates. Edge endpoints shall be derived at render-time from node centers; explicit endpoint persistence is not required.
  0574 - Absolute or zoom-derived node sizes shall not be stored in the backing model; an optional categorical size override may be persisted per node.
  0575 - If the selected node is removed from the board or becomes non-visible, the selection shall be cleared.
  
 The Sidebar
  0580 - The View shall have a floating Sidebar list, called the Backlog
  0590 - The Backlog Sidebar panel shall be semi translucent, so that content behind it can still be made out.
  0600 - The Backlog shall potentially consist of every Card in the Database
  0610 - The Backlog shall not include any Cards that are currently included in the Murderboard View Canvas backing store.
  0620 - The Backlog shall include a drop down picker allowing the list to be filtered by Kind.
  0630 - The drop down picker in the Backlog shall consist of items in the Kind enum and equate to Card.kind
  0640 - Selecting an item in the Backlog’s Drop Down Picker shall cause the Backlog to be filtered by the selected Card.kind
  0650 - The Backlog rows shall display Card names, the Kind icon, and, if available, small image thumbnails.
  0660 - There shall be a button next to the floating Sidebar panel
  0670 - The floating Sidebar Panel Button shall be visible even if the Sidebar is hidden
  0680 - Clicking or tapping the Sidebar Panel Button shall toggle the visibility of the Backlog
  0690 - Cards shown in the Backlog shall be able to be dragged onto the Murderboard View Canvas.
  0700 - When a Card is dragged from the Backlog into the Murderboard View Canvas, a new node shall be added to the Murderboard View Canvas
  0710 - During the drag operation from the Backlog to the View Canvas, when the cursor is hovering over the View Canvas, a blue Drop Target indicator shall appear indicating to the operator that the Canvas is a valid Drop Target for the Selected Backlog Card.

  Requriements Proposed Changes (keep this section)
  - Incorporated changes into the Authoritative Specification above (Spec Version 1.3). Summary:
    - Added Definitions and Invariants for coordinate spaces, transform, Z-order, reset, and primary enforcement.
    - Clarified grid “infinite” behavior and sizing (0241 references 0405; 0405 adds quantified margin M).
    - Clarified pan policy with implementation-defined clamping tied to Nodes Extents + margin (0066).
    - Made center-locked zoom canonical (0330) and referenced by 0090; added zoom factor clamping and input rules (0435).
    - Clarified “reshape” semantics on parent size change (0310); made 0400 reference 0040.
    - Clarified uninitialized node position (0260) without relying on a specific (0,0) sentinel; recenter button handles it (0452).
    - Clarified Primary presence vs reset exceptions and DB deletion handling (0280, 0286).
    - Added accessibility/contrast requirement (0225).
    - Clarified nodes extents to include padding for shadows/borders (0160).
    - Clarified edge determinism (0202) and removed need to persist edge endpoints (0572).
    - Added selection clearing on removal/non-visibility (0575).
    - Sidebar clarifications retained; DnD indicator behavior unchanged.
    - Added 0362 to limit node hit-testing to the CardView’s visual card-shape bounds (excluding padding/shadows), scaled by zoom, with a temporary fallback to measured layout size until the visual size is available.

  Acceptance Criteria
  - View Window and Border
    - A1: ✓ The MurderBoardView fills its parent view and is clipped to a rounded rectangle with a border at least 10 pt thick.
    - A2: ✓ The View Window shows a visible inner drop shadow that reads above underlying content in light and dark appearances.
    - A3: ✓ The View Canvas is entirely inside the border; resizing the parent resizes the window and canvas without changing pan/zoom semantics.
  - View Canvas, Transform, and View Canvas Rectangle
    - B1: ✓ The world→view transform is v = w*S + T with scalar S and translation T = (Tx, Ty) in view points.
    - B2: ✓ The View Canvas Rectangle is computed analytically as the inverse image of the View Window bounds and exactly fills the window at all times.
    - B3: ✓ Zooming changes only S and T (to keep the world point under the window center fixed by adjusting T analytically); node world positions do not change.
    - B4: ✓ Zoom is clamped to [0.01, 2.0]; pan is clamped within implementation-defined limits large enough to cover Nodes Extents + margin M under all expected pans/zooms.
  - Grid Background (View Canvas Grid)
    - C1: ✓ A low-contrast grid renders behind edges and nodes (bottommost layer).
    - C2: ✓ The grid coverage includes the union of the current View Canvas Rectangle and the Nodes Extents, inflated by margin M ≥ max(windowDiagonal / S, 2×tileSize).
    - C3: ✓ Grid/line colors maintain adequate contrast in both light and dark appearances.
  - Nodes and Nodes Extents
    - D1: ✓ Nodes render as CardViews centered at their world-space positions transformed to view space.
    - D2: ✓ Selection is indicated by an accent-colored border on the selected CardView.
    - D3: Nodes Extents is computed from each node’s world-space bounding box with padding for shadows/selection; it updates when nodes are added, moved, or removed.
  - Edges
    - E1: A single straight segment is displayed for each Card pair with one or more relationships, chosen deterministically (priority, then creation date, then stable UUID).
    - E2: Edges connect node centers and render above the grid and below nodes; thickness is at least 3 pt with sufficient contrast in both appearances.
    - E3: ✓ Each edge is stroked with a three‑color linear gradient aligned from source to target; the color stops (in order along the segment) are: target node border color, grid contrast color (light/dark aware), and source node border color (0222, 0224).
    - E4: ✓ The “border color” used for edges matches the CardView border color for that node; if it cannot be resolved, a deterministic fallback (AccentColor) is used. The grid contrast color adapts to appearance and maintains legibility (0225).
    - E5: ✓ Gradient edges preserve z‑order (grid < edges < nodes < overlays), maintain ≥ 3 pt thickness, and render without performance regressions for dozens to low hundreds of edges.
  - Initial Display and Recenter
    - F1: ✓ On first display, the canvas recenters on the Primary node if present, otherwise on the first node; no zoom change occurs.
    - F2: ✓ If the target node’s position is uninitialized, it is set to the center of the current View Canvas Rectangle before recentering.
  - Selection and Interaction
    - G1: ✓ Clicking a node selects it; clicking the canvas background clears selection.
        Root cause: Short click motions are sometimes captured by the unified DragGesture on the canvas before the CardView’s tap gesture, so the drag path wins the gesture arena and prevents selection. This is more likely at higher zoom and before nodeSizes are measured, making edge hits marginal.
        Corrective actions taken: Standardized hit testing using world-space rects derived from measured CardView sizes; added a clear contentShape on the canvas to reduce ambiguity; tuned DragGesture minimumDistance to reduce false drags. Additional queued refinement: add highPriorityGesture for CardView taps so taps win over a competing drag start.
        CA-6 Standardized world-space hit testing using CardView visual bounds; clearer canvas contentShape; reduced DragGesture minimumDistance; added highPriorityGesture so card taps win.
        CA-7 Non-interfering click overlay logs/visualizes hit rects; confirms hit-test math without affecting gestures.
        Rejection (new): Clicks/hit-tests look correct, but selection still doesn’t change; short clicks that remain .pending or lock to .pan never assign selection.
        CA-8 Unified drag onEnded now treats short clicks (distance < tapThreshold) in .pan/.pending as selection/clear via hitTestNode(at:).
        CA-9 Shortened summary — added selection diagnostics and one-tick suppression so a CardView tap can’t be immediately cleared by the canvas short‑click path; logs make selection assignment/clears explicit.
        CA-10 Added a simultaneous SpatialTapGesture on the canvas to handle pure taps that never trigger DragGesture. On tap, if hitTestNode(at:) finds a node, select it; otherwise clear selection. Respects suppressBackgroundClickClear so a CardView’s highPriority tap can’t be immediately overridden. Logs “[MB] Canvas tap: select …” or “… clear selection.”
        CA-11 Diagnostic overlays draw (a) the View Canvas rectangle in view space inset by 5 pt, and (b) the Nodes Extents rectangle computed in world space from CardView visual bounds with padding for shadows/selection, transformed to view space for display.
        CA-12 We have enough of your project to fix this precisely. The most robust remedy is to make hit testing use the exact same view-space rectangles that your debug overlay draws, instead of mixing a view-space point with a world-space rectangle. That eliminates any chance of a small world/view mismatch (padding, rounding, transform ordering, etc.) causing quadrant-specific mis-selections or preventing deselection.
        Proposed root causes (G1):
        RC-1 Gesture arbitration and sequencing: a short click that routes through DragGesture’s .onEnded (short‑click path) can be immediately superseded by the simultaneous canvas SpatialTapGesture, which may clear selection if it interprets the same click as a background tap. Ordering/race varies by region, producing an apparent quadrant effect even when hit-test rects are correct.
        RC-2 Coordinate-space inconsistency for gesture locations: while the hit-test rectangles and debug overlays are correct, the SpatialTapGesture’s value.location can be resolved in a slightly different local space than the one used to compute rects (due to padding/clip/overlay layers around the canvas). This yields a consistent offset whose sign flips around the View Canvas center, so taps in one quadrant are misinterpreted as background.
        RC-3 Suppression scope: suppressBackgroundClickClear is applied for CardView’s highPriority tap, but not for the DragGesture short‑click selection path. When selection is assigned by the drag’s .onEnded handler, the canvas tap may still run and clear it in the same event turn.
        CA-13 Normalize gesture locations and serialize selection handling:
            - CA-13.1 Explicitly convert all gesture points (DragGesture start/location and SpatialTapGesture location) into the named canvasCoordSpace using GeometryProxy.convert(…, from: .global, to: .named(canvasCoordSpace)) before hit testing.
            - CA-13.2 Attach both gestures at the same view that defines coordinateSpace(name: canvasCoordSpace) after the border padding/clip so their locations are measured in the exact same space as the rects.
            - CA-13.3 Extend suppressBackgroundClickClear to the drag short‑click selection path: set it when assigning selection in .onEnded for distance < tapThreshold and clear it on the next runloop tick. This prevents the canvas tap from immediately clearing a just‑assigned selection.
            - CA-13.4 Prefer a single path to assign/clear selection for taps (the SpatialTapGesture), and keep the drag short‑click as a fallback only. Guard the fallback with the same suppression flag to avoid double‑processing.
            - CA-13.5 Add concise logs showing converted points and which handler ultimately set/cleared selection to verify that only one path wins per click.    - G2: ✓ Nodes can be dragged with standard click-drag; the node follows the pointer preserving the initial grab offset in world coordinates.
        RC-4 Conflicting dual tap paths: both the canvas SpatialTapGesture and a highPriority TapGesture on each CardView independently assign selection. Ordering varies, so the child tap can override a correct canvas decision or re-select after a canvas clear, matching the observed logs.
        CA-13 Normalize gesture locations and serialize selection handling (C13.1–C13.5).
        CA-14 Single-source tap selection from the canvas: remove CardView’s highPriority tap; keep drag short‑click fallback guarded by suppression. Also remove the broad contentShape on the transformed nodes container to reduce parent over‑hittability. This eliminates the race so only one authoritative selection decision runs per click.
    - G3: ✓ Panning occurs via click-drag on the canvas background.
        RC-0: Fixed — gesture state machine moved the initially hit node even when the lock decided on background pan. The .pending branch updated node.posX/posY unconditionally after lock decision, causing “click anywhere and one node drags.”
        CA-1: In .pending, move the node only if we lock to .node; if we lock to .pan, do not modify any node. Seed grab offset only when locking to node; seed panGestureStart when locking to pan.
        CA-2: Instrumented the unified drag state machine with per-drag diagnostics: record startHit node ID (or nil), the first lock decision (.node or .pan) and lock distance, and which node ID actually moves (if any). This exposes cases where a node moves after a pan lock or where hit testing is overly permissive (e.g., .node chosen unexpectedly). Expect concise logs per drag such as “[MB] Drag start … / Lock=pan at dist=6.0” or “Lock=node(id=…) at dist=5.2,” plus a final summary line.
        CA-3: Added a short‑lived visual debug overlay at drag start that outlines each node’s computed view‑space rect and marks the startLocation with a dot. This immediately reveals oversized/incorrect rects (e.g., wrong coordinate space) and visually validates the world→view projection; the start point should only fall inside a rect when pressing over a card.
        CA-4: Revised hit-rectangle computation to use a helper nodeSizeInViewPoints(for:) that returns measured size × zoomScale (with clamping). All view-space rects now use this helper in computeAllNodeRectsInView(), hitTestNode(at:), and isPoint(_:insideNodeWithID:). Added a tiny CGSize.scaled(by:) helper to support this.
        CA-5: Hit rectangles now use CardView-reported visual card-shape size (excluding outer padding for tabs/shadows). MurderBoardView consumes CardViewVisualSizeKey and scales by current zoom; falls back to legacy layout size until available. This removes apparent padding around hit rects and improves drag lock precision at all zooms.
    - G4: Selection is cleared if the selected node is removed or becomes non-visible in the board.
 - Zoom Controls
    - H1: ✓ Toolbar includes Zoom Out button, slider (1%–200%), Zoom In button, and percent text field.
    - H2: ✓ Percent entry clamps to [1, 200], ignores non-numeric input, and rounds to the nearest integer; zooming keeps the world point under the window center fixed by adjusting T analytically.
 - Shuffle
    - I1: “Shuffle” arranges all nodes except the Primary (if present) around the Primary (or first) in world space using a ring layout with random jitter.
      RC-5: Fixed-radius rings ignored actual CardView sizes expressed in world units, so circumference-per-node was too small at typical zooms. Because node sizes scale inversely with zoom in world space, a constant radius causes overlaps regardless of zoom percentage.
      CA-15: Make ring radii and per-ring capacity adaptive in world space:
        - Compute each node’s world-space size using the same CardView visual bounds used for hit testing (nodeSizeInWorldPoints).
        - Choose a base radius from the anchor’s world size plus margin.
        - For each ring, compute desired arc spacing = avg node width × spacingMultiplier (e.g., 1.25).
        - Capacity = floor(2πr / desiredSpacing). If remaining nodes exceed capacity, increase r until capacity ≥ remaining for that ring.
        - Use a zoom‑independent ring separation based on max node span in world units to avoid cross‑ring overlaps.
        - Place nodes evenly with small jitter; persist immediately.
    - I2: Repeated shuffles produce different arrangements; the Primary’s position does not change.
    - I3: New positions persist immediately; edges update automatically.
  - Primary Enforcement and Reset
    - J1: When enforcement is active and a Primary is set, the Primary must be present as a node; if missing, it is auto-created.
    - J2: During and immediately after a reset (all nodes removed), enforcement is suspended; the Primary may be removed and primaryCard may be cleared.
    - J3: If the Primary card is deleted from the database, primaryCard is cleared and enforcement remains suspended until a new Primary is assigned.
  - Persistence
    - K1: Murderboards persist via Board; nodes via BoardNode bridging many-to-many Cards↔Boards.
    - K2: Node centers persist in world coordinates; edge endpoints are derived at render time.
    - K3: Absolute/zoom-derived node sizes are not persisted; an optional categorical size override may be persisted per node.
    - K4: Selection persists until the user clicks another node or the canvas; it is cleared if the selected node is removed or becomes non-visible.
  - Sidebar Backlog and Drag & Drop
    - L1: A floating, semi-translucent Backlog panel lists Cards not on the board and supports filtering by Kind.
    - L2: Backlog rows display Card name, Kind icon, and thumbnail if available.
    - L3: A toggle button is always visible to show/hide the Backlog.
    - L4: Dragging a Backlog Card over the canvas shows a blue drop target indicator; dropping creates a new node at the drop location mapped to world coordinates and persists it.
  - Accessibility, Appearance, and Performance
    - M1: Colors and contrasts for edges, selection borders, and grid adapt to light/dark appearances.
    - M2: Panning/zooming and dragging remain responsive for dozens to low hundreds of nodes/edges.
    - M3: Coordinate-space math is deterministic and stable across window resizes.
    - M4: No visible grid-edge tearing occurs during pan/zoom due to 0405-compliant margin sizing.

  Implementation Plan
   - Phase 0: Data Model and Utilities
    - Confirm models Card, CardEdge, RelationType, Board, BoardNode with many-to-many bridging; Board has primaryCard, zoomScale, panX, panY, nodes.
    - Add Board static limits: minZoom = 0.01, maxZoom = 2.0; minPan/maxPan large enough to cover Nodes Extents + margin M.
    - Implement Board helpers: fetchOrCreatePrimaryBoard(for:in:), node(for:createIfMissing:defaultPosition:), ensurePrimaryPresence(in:), clampState().
    - Implement deterministic edge selection policy (RelationType priority; tie-breakers).
 
    - Add numeric clamp helpers and transform helper (v = w*S + T, inverse).
  - Phase 1: View Window Shell and Border
    - Build rounded border (≥ 10 pt) and inner drop shadow as an overlay that works in light and dark.
    - Ensure the canvas sits fully inside the border and the view fills its parent.
 
  - Phase 2: Transform State and View Canvas Rectangle
    - Store live zoomScale/panX/panY in @State and mirror changes to Board with clamping and debounced persistence.
    - Compute the View Canvas Rectangle analytically as the inverse mapping of window bounds.
    - Maintain worldCenter(forWindowSize:) helper.
 
  - Phase 3: Grid Background
    - Implement a grid view sized to cover union(View Canvas Rectangle, Nodes Extents) + margin M.
    - For a first pass, render a sufficiently large surface so edges are never visible; later refine to exact 0405 coverage.
 
  - Phase 4: Nodes and Selection
    - Render nodes as CardViews positioned by world centers using a layer transform (scale+offset).
    - Add selection overlay (accent border) and rules (click to select, background click to clear, clear on removal/non-visibility).
    - Track node frames in a named coordinate space for hit-testing.
 
  - Phase 5: Edges Rendering
    - Collapse CardEdge relations to one per pair using deterministic rule.
    - Render edges between node centers with correct z-order (grid < edges < nodes < overlays) and thickness ≥ 3 pt.
    - New (0222/0224): Stroke each displayed segment with a three-stop linear gradient aligned from source→target with stops [target border color, grid contrast color (light/dark aware), source border color]. Derive node border colors from the same source used by CardView (Kinds.accentColor(for:)); fall back to AccentColor if unavailable. Cache per-node colors during a pass to avoid redundant lookups.
 
  - Phase 6: Gestures and Interaction
    - Add a unified drag gesture: if the gesture starts over a node (prefer selected on overlap) then node-drag; else pan.
    - Node drag updates node.posX/posY in world coordinates preserving initial grab offset; persist during/after drag.
    - Pan drag updates panX/panY in view points; clamp and persist on end (debounce optional).
 
  - Phase 7: Initial Recenter and Recenter Control
    - On initial display, ensure primary presence (unless in reset), initialize uninitialized target position to View Canvas Rectangle center, then pan to center without zoom change.
    - Add toolbar “Recenter” button to perform the same logic.
 
    - Phase 8: Zoom Controls
    - Toolbar: Zoom Out, Slider (1%–200%), Zoom In, and percent text field.
    - Implement center-locked zoom by recomputing T to keep the window center mapped to the same world point.
    - Clamp and persist S and T; ignore non-numeric input; round percent to nearest integer.
 
  - Phase 9: Shuffle
    - Arrange all non-anchor nodes around the Primary (or first) in rings with jitter; increase ring radius/capacity for larger counts.
    - Persist new positions; edges update automatically.
 
  - Phase 10: Primary Enforcement and Reset
    - Enforce Primary presence when set and not in reset; auto-create missing node.
    - Reset removes all nodes and suspends enforcement; allow clearing primaryCard; resume enforcement only after a new Primary is assigned.
    - If the Primary card is deleted, clear primaryCard and suspend enforcement until reassigned.
 
  - Phase 11: Sidebar Backlog and Drag & Drop
    - Implement floating, semi-translucent Backlog with Kind filter; exclude Cards already on the board.
    - Provide a persistent toggle button to show/hide the Backlog.
    - Drag a Card from Backlog to canvas: show blue drop target indicator; on drop create BoardNode at world-mapped location and persist.
 
  - Phase 12: Accessibility, Appearance, and Performance
    - Ensure contrast and adaptive colors; use Canvas for grid/edges for performance.
    - Debounce model saves during drags; batch save on end where appropriate.
    - Cache node frames to optimize hit-testing and gesture routing.
 
  - Phase 13: Testing and Verification
    - Unit-test transform helpers: worldToView, viewToWorld, viewCanvasRect, center-locked zoom, clamping.
    - UI-verification tests for initial recenter, selection/clearing, node drag behavior, pan/zoom invariants, shuffle anchor preservation, and edge determinism.
 
  - Phase 14: Migration and Persistence Safety
    - Define schema migrations for any future model changes.
    - Verify autosave and explicit save points after shuffle, reset, and recenter.
    - Guard against nil Card references on BoardNodes and handle cleanup.
 
  - Risks and Mitigations
    - Large graphs: batch Canvas drawing and consider level-of-detail for grid at extreme zooms.
    - Precision drift: keep world coordinates in Double; clamp values; minimize conversions.
    - Gesture ambiguity: prefer selected node on overlap; fall back to topmost by stable board order.
    - Reset/enforcement race: gate enforcement during/after reset; ensure ensurePrimaryPresence is idempotent.
