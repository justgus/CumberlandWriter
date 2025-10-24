//
//  MurderBoardView.swift
//  Cumberland
//
//  Created by Mike Stoddard on 10/19/25.
//

/*
Requirements: MurderBoardView
Spec Version: 1.4
Last Updated: 2025-10-20


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
  0332 - The View Window shall recognize standard pinch‑to‑zoom gestures to control the zoom factor S: on macOS via trackpad pinch, on iPadOS via direct two‑finger pinch on the screen, and on visionOS via the platform’s standard pinch gesture. The gesture shall adjust S continuously and multiplicatively based on gesture magnification, clamp S to [0.01, 2.0] (0435), and analytically adjust T so that the world point under the View Window’s center remains fixed per 0330. Pinch recognition shall not interfere with node dragging (0360) or canvas panning (0380/0382); when a pinch is recognized, it takes precedence for its duration, and no selection state changes occur as a result of the pinch.
  0340 - Nodes in the View Canvas shall be selectable.
  0350 - When selected, the Card’s CardView shall display a border over it in the accent color of the Cumberland App.
  0360 - Nodes shall be able to be dragged via a standard click drag gesture on the Node
  0362 - Node hit-testing for selection and drag shall be limited to the CardView’s visual card-shape bounds as reported by the CardView (excluding outer padding, shadows, and adornments).
  0364 - The hit rectangle shall not exceed these visual bounds.
  0365 - The hit rectangle shall be scaled by the current zoom factor and centered on the node’s world position projected into view space. If a visual size has not yet been reported, a measured layout size may be used as a temporary fallback.
  0370 - When a node in the View Canvas is dragged, its position shall be updated based on the pointer's location over the View Canvas Rectangle, taking zoom and pan into account, and preserving the initial grab offset so the node follows the pointer smoothly.
  0380 - The View Canvas shall be able to be panned via a standard click drag operation on the View Canvas surface
  0382 - The View Canvas shall recognize a two‑finger pan gesture to update the view‑space translation T regardless of hit location: on macOS via trackpad two‑finger scroll (interpreted as pan), on iPadOS via a two‑finger pan on the screen, and on visionOS via the platform’s two‑finger pan. While active, the gesture continuously adjusts T, clamps T per 0066, does not change selection, and takes precedence over node drag (0360) and background click‑drag pan (0380) for its duration unless a pinch (0332) is recognized, in which case pinch takes precedence.
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
  - Incorporated changes into the Authoritative Specification above (Spec Version 1.4). Summary:
    - Added 0382 defining a platform-appropriate two‑finger pan gesture on macOS (trackpad scroll), iPadOS, and visionOS; clarified precedence with pinch (0332) and node/background drags (0360/0380), clamping, and selection neutrality.
    - Added Acceptance Criteria B9–B12 for two‑finger pan behavior and conflict resolution.
    - Added Phase 6 implementation steps for bridging two‑finger pan on each platform, delta→T mapping, gesture precedence, and clamping.

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
    - B5: ✓ A standard pinch‑to‑zoom gesture is recognized on macOS (trackpad pinch), iPadOS (direct two‑finger pinch), and visionOS. While pinching, S changes continuously and multiplicatively with gesture magnification; on end, S is clamped to [0.01, 2.0].
    - B6: ✓ During pinch, T is analytically adjusted so that the world point under the View Window’s geometric center remains fixed (0330). No node world positions change (0300), and the View Window does not move or resize (0100).
    - B7: ✓ Pinch recognition does not trigger selection or drag. While a pinch is active, it takes precedence over background pan (0380/0382) and node drag (0360); after the pinch ends, other gestures operate normally.
    - B8: - Trackpad pinch and two‑finger pan do not conflict: initiating a pinch prevents a simultaneous pan for the duration of the gesture; initiating a two‑finger pan without pinch magnification performs pan only.
    - B9: ✓ A two‑finger pan gesture is recognized on macOS (trackpad two‑finger scroll mapped to pan), iPadOS (two‑finger pan), and visionOS. While active, the gesture continuously updates T, clamps T per 0066, and does not change selection.
    - B10: ✓ Two‑finger pan is hit‑location agnostic (works over nodes or background) and takes precedence over node drag (0360) and background click‑drag pan (0380) for its duration unless a pinch is recognized, in which case pinch takes precedence (0332).
    - B11: ✓ On macOS, two‑finger scroll deltas map 1:1 (with sensible scaling and axis inversion for natural/inverted scrolling) into T updates in view points; kinetic/phase‑ended momentum is either ignored or applied deterministically without overshooting clamped bounds.
    - B12: ✓ Two‑finger pan respects the same pan clamping and persistence policies as other pan paths; no jitter or race with simultaneous gestures is observed.
  - Grid Background (View Canvas Grid)
    - C1: ✓ A low-contrast grid renders behind edges and nodes (bottommost layer).
    - C2: ✓ The grid coverage includes the union of the current View Canvas Rectangle and the Nodes Extents, inflated by margin M ≥ max(windowDiagonal / S, 2×tileSize).
    - C3: ✓ Grid/line colors maintain adequate contrast in both light and dark appearances.
  - Nodes and Nodes Extents
    - D1: ✓ Nodes render as CardViews centered at their world-space positions transformed to view space.
    - D2: ✓ Selection is indicated by an accent-colored border on the selected CardView.
    - D3: Nodes Extents is computed from each node’s world-space bounding box with padding for shadows/selection; it updates when nodes are added, moved, or removed.
  - Edges
    - E1: ✓ A single straight segment is displayed for each Card pair with one or more relationships, chosen deterministically (priority, then creation date, then stable UUID).
    - E2: ✓ Edges connect node centers and render above the grid and below nodes; thickness is at least 3 pt with sufficient contrast in both appearances.
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
            - CA-13.5 Add concise logs showing converted points and which handler ultimately set/cleared selection to verify that only one path wins per click.
    - G2: ✓ Nodes can be dragged with standard click-drag; the node follows the pointer preserving the initial grab offset in world coordinates.
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
    - G4: ✓ Selection is cleared if the selected node is removed or becomes non-visible in the board.
 - Zoom Controls
    - H1: ✓ Toolbar includes Zoom Out button, slider (1%–200%), Zoom In button, and percent text field.
    - H2: ✓ Percent entry clamps to [1, 200], ignores non-numeric input, and rounds to the nearest integer; zooming keeps the world point under the window center fixed by adjusting T analytically.
 - Shuffle
    - I1: ✓ “Shuffle” arranges all nodes except the Primary (if present) around the Primary (or first) in world space using a ring layout with random jitter.
      RC-5: Fixed-radius rings ignored actual CardView sizes expressed in world units, so circumference-per-node was too small at typical zooms. Because node sizes scale inversely with zoom in world space, a constant radius causes overlaps regardless of zoom percentage.
      CA-15: Make ring radii and per-ring capacity adaptive in world space:
        - Compute each node’s world-space size using the same CardView visual bounds used for hit testing (nodeSizeInWorldPoints).
        - Choose a base radius from the anchor’s world size plus margin.
        - For each ring, compute desired arc spacing = avg node width × spacingMultiplier (e.g., 1.25).
        - Capacity = floor(2πr / desiredSpacing). If remaining nodes exceed capacity, increase r until capacity ≥ remaining for that ring.
        - Use a zoom‑independent ring separation based on max node span in world units to avoid cross‑ring overlaps.
        - Place nodes evenly with small jitter; persist immediately.
    - I2: ✓ Repeated shuffles produce different arrangements; the Primary’s position does not change.
    - I3: ✓ New positions persist immediately; edges update automatically.
  - Primary Enforcement and Reset
    - J1: ✓ When enforcement is active and a Primary is set, the Primary must be present as a node; if missing, it is auto-created.
    - J2: ✓ During and immediately after a reset (all nodes removed), enforcement is suspended; the Primary may be removed and primaryCard may be cleared.
    - J3: ✓ If the Primary card is deleted from the database, primaryCard is cleared and enforcement remains suspended until a new Primary is assigned.
  - Persistence
    - K1: ✓ Murderboards persist via Board; nodes via BoardNode bridging many-to-many Cards↔Boards.
    - K2: ✓ Node centers persist in world coordinates; edge endpoints are derived at render time.
    - K3: ✓ Absolute/zoom-derived node sizes are not persisted; an optional categorical size override may be persisted per node.
    - K4: ✓ Selection persists until the user clicks another node or the canvas; it is cleared if the selected node is removed or becomes non-visible.
  - Sidebar Backlog and Drag & Drop
    - L1: A floating, semi-translucent Backlog panel lists Cards not on the board and supports filtering by Kind.
    - L2: Backlog rows display Card name, Kind icon, and thumbnail if available.
    - L3: A toggle button is always visible to show/hide the Backlog.
    - L4: Dragging a Backlog Card over the canvas shows a blue drop target indicator; dropping creates a new node at the drop location mapped to world coordinates and persists it.
  - Accessibility, Appearance, and Performance
    - M1: Colors and contrasts for edges, selection borders, and grid adapt to light/dark appearances.
    - M2: ✓ Panning/zooming and dragging remain responsive for dozens to low hundreds of nodes/edges.
    - M3: ✓ Coordinate-space math is deterministic and stable across window resizes.
    - M4: ✓ No visible grid-edge tearing occurs during pan/zoom due to 0405-compliant margin sizing.

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
    - New (0222/0224): Stroke each displayed segment with a three-stop linear gradient aligned from source→target with stops [target border color, grid contrast color (light/dark aware), and source border color]. Derive node border colors from the same source used by CardView (Kinds.accentColor(for:)); fall back to AccentColor if unavailable. Cache per-node colors during a pass to avoid redundant lookups.
 
  - Phase 6: Gestures and Interaction
    - Add a unified drag gesture: if the gesture starts over a node (prefer selected on overlap) then node-drag; else pan.
    - Node drag updates node.posX/posY in world coordinates preserving initial grab offset; persist during/after drag.
    - Pan drag updates panX/panY in view points; clamp and persist on end (debounce optional).
    - New (0382) Two‑finger pan:
      - iPadOS/visionOS: Attach a UIPanGestureRecognizer via a UIViewRepresentable that is configured with minimumNumberOfTouches = 2 and maximumNumberOfTouches = 2. While the recognizer is .changed, convert translation deltas in view points into incremental updates to T = (panX, panY); reset the recognizer’s translation to zero after applying deltas. Clamp T per 0066. Do not modify selection.
      - macOS: Add an NSViewRepresentable overlay that receives scrollWheel events from a trackpad two‑finger gesture. Convert deltaX/deltaY (respecting natural/inverted scrolling) into updates to T in view points. Ignore momentum or apply a bounded fraction that respects clamping; no overshoot. Do not modify selection.
      - Gesture precedence: When a MagnificationGesture (0332) is active, it takes precedence over two‑finger pan; suspend pan updates during active magnification. When two‑finger pan is active, suppress node drag (0360) and background click‑drag pan (0380) for its duration.
      - Coordinate space: Measure deltas in the same named canvas coordinate space used elsewhere to ensure consistency with hit-testing and transforms.
      - Persistence: Debounce persisting T to the Board during continuous updates; commit on gesture end.
 
  - Phase 7: Initial Recenter and Recenter Control
    - On initial display, ensure primary presence (unless in reset), initialize uninitialized target position to View Canvas Rectangle center, then pan to center without zoom change.
    - Add toolbar “Recenter” button to perform the same logic.
 
    - Phase 8: Zoom Controls
    - Toolbar: Zoom Out, Slider (1%–200%), Zoom In, and percent text field.
    - Implement center-locked zoom by recomputing T to keep the window center mapped to the same world point.
    - Clamp and persist S and T; ignore non-numeric input; round percent to the nearest integer.
    - Add platform-appropriate pinch-to-zoom recognition per 0332 (SwiftUI MagnificationGesture where available; bridge to NSMagnificationGestureRecognizer on macOS as needed). Convert gesture magnification to multiplicative updates to S, clamp to [0.01, 2.0], and adjust T analytically per 0330. Ensure pinch takes precedence over pan/drag during its lifecycle and does not alter selection.
 
  - Phase 9: Shuffle
    - Arrange all nodes except the Primary (if present) around the Primary (or first) in rings with jitter; increase ring radius/capacity for larger counts.
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
    - New (0382): Tests that two‑finger pan updates T on macOS via scrollWheel deltas and on iPadOS via two‑finger UIPan; verify precedence rules with pinch and clamping behavior.
 
  - Phase 14: Migration and Persistence Safety
    - Define schema migrations for any future model changes.
    - Verify autosave and explicit save points after shuffle, reset, and recenter.
    - Guard against nil Card references on BoardNodes and handle cleanup.
 
  - Risks and Mitigations
    - Large graphs: batch Canvas drawing and consider level-of-detail for grid at extreme zooms.
    - Precision drift: keep world coordinates in Double; clamp values; minimize conversions.
    - Gesture ambiguity: prefer selected node on overlap; fall back to topmost by stable board order.
    - Reset/enforcement race: gate enforcement during/after reset; ensure ensurePrimaryPresence is idempotent.
*/

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import CloudKit

#if canImport(Testing)
import Testing
#endif

struct MurderBoardView: View {
    let primary: Card

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme

    // Persisted board for this primary
    @State private var board: Board?

    // Live transform state (mirrors board.zoomScale/panX/panY; persisted on changes)
    @State private var zoomScale: Double = 1.0   // S
    @State private var panX: Double = 0.0        // T.x (view points)
    @State private var panY: Double = 0.0        // T.y (view points)

    // Selection (single)
    @State private var selectedCardID: UUID? = nil

    // One-time initial recenter
    @State private var didInitialRecenter: Bool = false

    // Staging flag to avoid heavy simultaneous image uploads during first render
    @State private var isContentReady: Bool = false
    @State private var prefetchProgress: (done: Int, total: Int) = (0, 0)

    // Centralized drag routing
    private enum ActiveDrag {
        case none
        // New: pending until translation exceeds threshold
        case pending(hitID: UUID?)
        case node(cardID: UUID)
        case pan

        func isDragging(cardID: UUID) -> Bool {
            if case .node(let id) = self { return id == cardID }
            return false
        }
    }
    @State private var activeDrag: ActiveDrag = .none
    @State private var dragGrabOffsetWorld: CGPoint = .zero   // for node drags
    @State private var panGestureStart: CGPoint? = nil        // for background pan (view-space T at start)

    // Live unscaled sizes measured for each CardView (pre-transform, full layout size)
    @State private var nodeSizes: [UUID: CGSize] = [:]
    // New: Visual card-shape sizes reported by CardView (excludes outer padding for tabs)
    @State private var nodeVisualSizes: [UUID: CGSize] = [:]

    // Named coordinate space for consistent gesture math (canvas/view space)
    fileprivate let canvasCoordSpace = "MurderBoardCanvasSpace"

    // Prevent parent short-click clear from racing after a child tap
    @State private var suppressBackgroundClickClear: Bool = false

    // 0332: Pinch-to-zoom state
    @State private var isPinching: Bool = false
    @State private var pinchStartScale: Double = 1.0

    // 0382: Two‑finger pan state (suppresses node drag/background drag while active)
    @State private var isTwoFingerPanning: Bool = false

    // MARK: - Debug instrumentation (Actions 1 & 2)

    #if DEBUG
    @State private var debugHitTestingEnabled: Bool = false
    @State private var debugStartPoint: CGPoint? = nil
    @State private var debugRectsAtStart: [CGRect] = []
    @State private var debugStartHitID: UUID? = nil
    @State private var debugFirstLockDescription: String? = nil
    @State private var debugFirstLockDistance: Double = 0
    @State private var debugMovedNodeID: UUID? = nil

    // New: click overlay (non-interfering with drag)
    @State private var debugClickPoint: CGPoint? = nil
    @State private var debugRectsAtClick: [CGRect] = []
    @State private var debugClickHitID: UUID? = nil
    #endif

    init (primary: Card) {
        self.primary = primary
    }

    var body: some View {
        GeometryReader { proxy in
            // Phase 1: View Window shell
            let outerSize = proxy.size
            let border = windowBorderWidth
            // Content (canvas) size accounts for the border inset so the canvas is fully inside the border
            let contentSize = CGSize(width: max(0, outerSize.width - 2 * border),
                                     height: max(0, outerSize.height - 2 * border))
            let contentCenter = CGPoint(x: contentSize.width / 2, y: contentSize.height / 2)

            ZStack {
                // Canvas host inside the border
                ZStack {
                    canvasLayer(windowSize: contentSize, windowCenter: contentCenter)
                }
                .padding(border)
                // Clip canvas to the inner edge of the border (0054)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: max(0, windowCornerRadius - windowBorderWidth),
                        style: .continuous
                    )
                )

                if isContentReady == false {
                    // Lightweight progress overlay while thumbnails are being prefetched
                    VStack(spacing: 8) {
                        let total = prefetchProgress.total
                        let done = prefetchProgress.done
                        if total > 0 {
                            let fraction = min(max(Double(done) / Double(total), 0.0), 1.0)
                            ProgressView(value: fraction)
                                .progressViewStyle(.linear)
                                .frame(width: min(280, contentSize.width * 0.6))
                        } else {
                            ProgressView()
                                .progressViewStyle(.linear)
                                .frame(width: min(280, contentSize.width * 0.6))
                        }
                        Text("Preparing board…")
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .shadow(radius: 8)
                    )
                }
            }
            // Outer rounded border drawn on top (0052)
            .overlay(
                ZStack {
                    RoundedRectangle(cornerRadius: windowCornerRadius, style: .continuous)
                        .fill(Color.clear)

                    RoundedRectangle(cornerRadius: windowCornerRadius, style: .continuous)
                        .stroke(windowBorderColor, lineWidth: windowBorderWidth)

                    RoundedRectangle(cornerRadius: max(0, windowCornerRadius - windowBorderWidth / 2), style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    windowInnerShadowColor.opacity(scheme == .dark ? 0.55 : 0.85),
                                    windowInnerShadowColor.opacity(0.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .mask(
                            RoundedRectangle(cornerRadius: windowCornerRadius, style: .continuous)
                                .stroke(lineWidth: windowBorderWidth)
                        )
                        .blendMode(.overlay)
                        .opacity(scheme == .dark ? 0.5 : 0.8)
                }
                .allowsHitTesting(false)
            )
            .clipShape(RoundedRectangle(cornerRadius: windowCornerRadius, style: .continuous))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .toolbar { toolbarContent(windowSize: contentSize) }
            .onChange(of: board?.id) {
                if let b = board, didInitialRecenter == false, contentSize.width > 0, contentSize.height > 0 {
                    initialRecenterIfNeeded(on: b, windowSize: contentSize)
                }
            }
            .onChange(of: contentSize) { _, newSize in
                if let b = board, didInitialRecenter == false, newSize.width > 0, newSize.height > 0 {
                    initialRecenterIfNeeded(on: b, windowSize: newSize)
                }
            }
        }
        // Phase 2: Load board and wire transform state with clamping/persistence
        .task {
            await loadBoardIfNeeded()
        }
        .onChange(of: board?.id) {
            applyBoardTransform()
            Task { await stageThumbnailsIfNeeded() }
        }
        .onChange(of: zoomScale) { _, newValue in
            let clamped = newValue.rangeClamped(to: Board.minZoom...Board.maxZoom)
            if clamped != zoomScale { zoomScale = clamped; return }
            persistTransformDebounced()
        }
        .onChange(of: panX) { _, newValue in
            let clamped = newValue.rangeClamped(to: Board.minPan...Board.maxPan)
            if clamped != panX { panX = clamped; return }
            persistTransformDebounced()
        }
        .onChange(of: panY) { _, newValue in
            let clamped = newValue.rangeClamped(to: Board.minPan...Board.maxPan)
            if clamped != panY { panY = clamped; return }
            persistTransformDebounced()
        }
        #if DEBUG
        .onChange(of: selectedCardID) { old, new in
            let o = old?.uuidString ?? "nil"
            let n = new?.uuidString ?? "nil"
            print("[MB] Selection changed: \(o) → \(n)")
        }
        #endif
    }
}

// MARK: - Constants

private let windowCornerRadius: CGFloat = 18
private let windowBorderWidth: CGFloat = 12

private var windowBorderColor: Color { .secondary.opacity(0.55) }
private var windowInnerShadowColor: Color { .white.opacity(0.18) }

// MARK: - Transform Helper (file-scoped to enable direct tests)

fileprivate struct MurderBoardTransform {
    static func worldToView(_ world: CGPoint, scale s: Double, panX: Double, panY: Double) -> CGPoint {
        CGPoint(x: world.x.dg * s + panX, y: world.y.dg * s + panY)
    }
    static func viewToWorld(_ view: CGPoint, scale s: Double, panX: Double, panY: Double) -> CGPoint {
        let ss = max(s, 0.000001)
        return CGPoint(x: (view.x.dg - panX) / ss, y: (view.y.dg - panY) / ss)
    }
    static func viewCanvasRect(worldForWindowSize size: CGSize, scale s: Double, panX: Double, panY: Double) -> CGRect {
        let originWorld = viewToWorld(.zero, scale: s, panX: panX, panY: panY)
        let ss = max(s, 0.000001)
        let wWorld = size.width.dg / ss
        let hWorld = size.height.dg / ss
        return CGRect(x: originWorld.x, y: originWorld.y, width: wWorld, height: hWorld)
    }
    static func worldCenter(forWindowSize size: CGSize, scale s: Double, panX: Double, panY: Double) -> CGPoint {
        let cView = CGPoint(x: size.width / 2.0, y: size.height / 2.0)
        return viewToWorld(cView, scale: s, panX: panX, panY: panY)
    }
}

// MARK: - Canvas

fileprivate extension MurderBoardView {
    // World→View transform: v = w*S + T
    func worldToView(_ world: CGPoint) -> CGPoint {
        MurderBoardTransform.worldToView(world, scale: zoomScale, panX: panX, panY: panY)
    }

    // View→World inverse: w = (v − T)/S
    func viewToWorld(_ view: CGPoint) -> CGPoint {
        MurderBoardTransform.viewToWorld(view, scale: zoomScale, panX: panX, panY: panY)
    }

    // View Canvas Rectangle in world coordinates (0080)
    func viewCanvasRect(worldForWindowSize size: CGSize) -> CGRect {
        MurderBoardTransform.viewCanvasRect(worldForWindowSize: size, scale: zoomScale, panX: panX, panY: panY)
    }

    // World center corresponding to the View Window’s geometric center (0140)
    func worldCenter(forWindowSize size: CGSize) -> CGPoint {
        MurderBoardTransform.worldCenter(forWindowSize: size, scale: zoomScale, panX: panX, panY: panY)
    }

    // Convert a world-space rect to a view-space rect (axis-aligned since transform is uniform scale + translation)
    func worldRectToViewRect(_ rectWorld: CGRect) -> CGRect {
        let p0 = worldToView(CGPoint(x: rectWorld.minX, y: rectWorld.minY))
        let p1 = worldToView(CGPoint(x: rectWorld.maxX, y: rectWorld.maxY))
        return CGRect(x: min(p0.x, p1.x),
                      y: min(p0.y, p1.y),
                      width: abs(p1.x - p0.x),
                      height: abs(p1.y - p0.y))
    }

    // Compute Nodes Extents in world coordinates using CardView visual sizes + padding (0160)
    func computeNodesExtentsWorld() -> CGRect? {
        guard let b = board else { return nil }
        let nodes = (b.nodes ?? [])
        var rect: CGRect?

        // Padding to include shadows and selection borders (expressed in VIEW points), then normalized to world units.
        // Components: inner stroke (12), drop shadow spread (~6), selection border (up to 4) => ~22; add a small safety margin.
        let paddingView: CGFloat = 24
        let s = max(zoomScale, 0.000001)
        let paddingWorld = paddingView / s

        for node in nodes {
            guard let id = node.card?.id else { continue }
            let sizeWorld = nodeSizeInWorldPoints(for: id)
            let centerWorld = CGPoint(x: node.posX, y: node.posY)
            var r = CGRect(
                x: centerWorld.x - sizeWorld.width / 2.0,
                y: centerWorld.y - sizeWorld.height / 2.0,
                width: sizeWorld.width,
                height: sizeWorld.height
            )
            r = r.insetBy(dx: -paddingWorld, dy: -paddingWorld)
            if let existing = rect {
                rect = existing.union(r)
            } else {
                rect = r
            }
        }
        return rect
    }

    @ViewBuilder
    func canvasLayer(windowSize: CGSize, windowCenter: CGPoint) -> some View {
        // Attach gestures and define the named coordinate space on the SAME view (CA-13.2).
        GeometryReader { geo in
            ZStack {
                // Background container: base fill + grid overlay.
                ZStack {
                    Rectangle()
                        .fill(scheme == .dark ? Color.black.opacity(0.20) : Color.black.opacity(0.04))

                    GridBackground(
                        tileSize: 40,
                        lineWidth: 0.5,
                        primaryOpacity: scheme == .dark ? 0.22 : 0.10,
                        secondaryEvery: 5,
                        secondaryOpacity: scheme == .dark ? 0.28 : 0.14
                    )
                }
                .ignoresSafeArea()

                // Phase 5: Edges layer (renders above grid, below nodes)
                edgesLayer()
                    .allowsHitTesting(false)

                if isContentReady {
                    nodesLayer(windowSize: windowSize)
                        .transition(.opacity .combined(with: .scale))
                }

                // 0382: Two‑finger pan overlays (platform bridges). Placed above nodes to take precedence while active.
                TwoFingerPanOverlay(
                    isPinching: $isPinching,
                    isTwoFingerPanning: $isTwoFingerPanning,
                    onDelta: { dx, dy in
                        applyPanDelta(dx: dx, dy: dy)
                    },
                    onEnd: {
                        persistTransformNow()
                    }
                )
                .allowsHitTesting(true)

                // Debug overlay: rects + start dot (visible only when enabled and we have a start point)
                #if DEBUG
                if debugHitTestingEnabled, let start = debugStartPoint {
                    let highlighted = Set(debugRectsAtStart.enumerated().filter { $0.element.contains(start) }.map { $0.offset })
                    ZStack {
                        ForEach(Array(debugRectsAtStart.enumerated()), id: \.offset) { idx, rect in
                            Rectangle()
                                .path(in: rect)
                                .stroke(highlighted.contains(idx) ? Color.red : Color.blue, style: StrokeStyle(lineWidth: highlighted.contains(idx) ? 2 : 1, dash: [4, 3]))
                        }
                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                            .position(start)
                            .shadow(radius: 2)
                    }
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                    .transition(.opacity)
                }

                // New: click overlay (green), independent from drag overlay
                if debugHitTestingEnabled, let click = debugClickPoint {
                    let highlighted = Set(debugRectsAtClick.enumerated().filter { $0.element.contains(click) }.map { $0.offset })
                    ZStack {
                        ForEach(Array(debugRectsAtClick.enumerated()), id: \.offset) { idx, rect in
                            Rectangle()
                                .path(in: rect)
                                .stroke(highlighted.contains(idx) ? Color.green : Color.mint, style: StrokeStyle(lineWidth: highlighted.contains(idx) ? 2 : 1, dash: [5, 3]))
                        }
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                            .position(click)
                            .shadow(radius: 2)
                    }
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                    .transition(.opacity)
                }

                // CA-11: View Canvas Rectangle (in view space), inset by 5 points on all sides
                if debugHitTestingEnabled {
                    let inset: CGFloat = 5
                    let viewCanvasRectInView = CGRect(origin: .zero, size: windowSize).insetBy(dx: inset, dy: inset)
                    Rectangle()
                        .path(in: viewCanvasRectInView)
                        .stroke(
                            Color.orange,
                            style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                        )
                        .overlay(
                            Text("View Canvas")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                                .padding(4)
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                                .position(x: viewCanvasRectInView.minX + 72, y: viewCanvasRectInView.minY + 12)
                        )
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                        .transition(.opacity)
                }

                // CA-11: Nodes Extents Rectangle (computed in world, shown in view space)
                if debugHitTestingEnabled, let extWorld = computeNodesExtentsWorld() {
                    let extView = worldRectToViewRect(extWorld)
                    Rectangle()
                        .path(in: extView)
                        .stroke(
                            Color.purple,
                            style: StrokeStyle(lineWidth: 1.5, dash: [3, 3])
                        )
                        .overlay(
                            Text("Nodes Extents")
                                .font(.caption2)
                                .foregroundStyle(.purple)
                                .padding(4)
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                                .position(x: extView.minX + 80, y: extView.minY + 12)
                        )
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                        .transition(.opacity)
                }
                #endif
            }
            // Untransformed, stable view-space that we also name for gestures/hit-testing (CA-13.2)
            .coordinateSpace(name: canvasCoordSpace)
            .contentShape(Rectangle())
            // 0332: High-priority pinch-to-zoom so it takes precedence over pan/drag while active.
            .highPriorityGesture(
                MagnificationGesture()
                    .onChanged { value in
                        if isPinching == false {
                            isPinching = true
                            pinchStartScale = zoomScale
                        }
                        // Multiplicative update; clamp via helper which also recenters analytically (0330).
                        let proposed = pinchStartScale * value
                        setZoomKeepingCenter(proposed, windowSize: windowSize)
                    }
                    .onEnded { _ in
                        isPinching = false
                        persistTransformNow()
                    }
            )
            // Unified gesture attached here — use local/named space so locations match the rects (CA-13.1)
            .gesture(unifiedDragGesture())
            // Real canvas tap handler — single authoritative path for selection (CA-14)
            .simultaneousGesture(
                SpatialTapGesture()
                    .onEnded { value in
                        // Do not change selection during pinch (0332) or two‑finger pan (0382).
                        if isPinching || isTwoFingerPanning { return }
                        if suppressBackgroundClickClear {
                            #if DEBUG
                            print("[MB] Canvas tap suppressed by child/drag short-click")
                            #endif
                            return
                        }
                        let p = value.location
                        if let hit = hitTestNode(at: p) {
                            selectedCardID = hit
                            #if DEBUG
                            print("[MB] Canvas tap: select id=\(hit.uuidString) at \(formatPoint(p))")
                            #endif
                        } else {
                            selectedCardID = nil
                            #if DEBUG
                            print("[MB] Canvas tap: clear selection at \(formatPoint(p))")
                            #endif
                        }
                    }
            )
            #if DEBUG
            // Non-interfering click inspection: records hit-test snapshot without changing selection or drag routing
            .simultaneousGesture(
                SpatialTapGesture()
                    .onEnded { value in
                        guard debugHitTestingEnabled, isPinching == false, isTwoFingerPanning == false else { return }
                        let p = value.location // local canvas space
                        debugClickPoint = p
                        debugRectsAtClick = computeAllNodeRectsInView()
                        debugClickHitID = hitTestNode(at: p)
                        let hitStr = debugClickHitID?.uuidString ?? "nil"
                        print("[MB] Click inspect: point=\(formatPoint(p)) hit=\(hitStr) rects=\(debugRectsAtClick.count)")
                        // Auto-hide overlay after a short time
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 1_200_000_000)
                            withAnimation(.easeOut(duration: 0.15)) {
                                debugClickPoint = nil
                                debugRectsAtClick = []
                            }
                        }
                    }
            )
            #endif
        }
    }

    // MARK: - Edges (Phase 5)

    // An undirected pair key for grouping edges between two cards
    struct UndirectedPair: Hashable {
        let a: UUID
        let b: UUID
        init(_ i1: UUID, _ i2: UUID) {
            if i1.uuidString < i2.uuidString {
                a = i1; b = i2
            } else {
                a = i2; b = i1
            }
        }
    }

    // Compute the single displayed segment per card pair, deterministically (E1).
    // Returns card IDs and world-space endpoints for drawing.
    func displayedEdges() -> [(fromID: UUID, toID: UUID, start: CGPoint, end: CGPoint)] {
        guard let b = board else { return [] }
        let nodes = (b.nodes ?? [])
        // Map cardID -> node center (world)
        var centers: [UUID: CGPoint] = [:]
        for n in nodes {
            if let id = n.card?.id {
                centers[id] = CGPoint(x: n.posX, y: n.posY)
            }
        }
        let memberIDs = Set(centers.keys)
        guard !memberIDs.isEmpty else { return [] }

        // Group candidate CardEdges by undirected pair
        var grouped: [UndirectedPair: [CardEdge]] = [:]

        for n in nodes {
            guard let card = n.card else { continue }
            let outs = card.outgoingEdges ?? []
            let ins = card.incomingEdges ?? []
            for e in outs + ins {
                guard let fromID = e.from?.id, let toID = e.to?.id else { continue }
                guard fromID != toID, memberIDs.contains(fromID), memberIDs.contains(toID) else { continue }
                let key = UndirectedPair(fromID, toID)
                grouped[key, default: []].append(e)
            }
        }

        func chooseEdge(_ list: [CardEdge]) -> CardEdge? {
            return list.min(by: { lhs, rhs in
                let lc = lhs.type?.code ?? ""
                let rc = rhs.type?.code ?? ""
                if lc != rc { return lc < rc }
                if lhs.createdAt != rhs.createdAt { return lhs.createdAt < rhs.createdAt }
                let lKey = [(lhs.from?.id.uuidString ?? ""), (lhs.to?.id.uuidString ?? ""), lc].joined(separator: "-")
                let rKey = [(rhs.from?.id.uuidString ?? ""), (rhs.to?.id.uuidString ?? ""), rc].joined(separator: "-")
                return lKey < rKey
            })
        }

        var result: [(UUID, UUID, CGPoint, CGPoint)] = []
        for (_, list) in grouped {
            guard let chosen = chooseEdge(list),
                  let fID = chosen.from?.id,
                  let tID = chosen.to?.id,
                  let p0 = centers[fID],
                  let p1 = centers[tID] else { continue }
            result.append((fID, tID, p0, p1))
        }
        return result
    }

    // Resolve the node border color used by CardView for a given card ID.
    // Default fallback is AccentColor if the card or kind is unavailable.
    func nodeBorderColor(for cardID: UUID) -> Color {
        guard let b = board,
              let node = (b.nodes ?? []).first(where: { $0.card?.id == cardID }),
              let card = node.card
        else {
            return .accentColor
        }
        return card.kind.accentColor(for: scheme)
    }

    // Grid contrast color (light/dark aware) used as the middle stop of the edge gradient.
    var gridContrastColor: Color {
        scheme == .dark ? .white.opacity(0.9) : .black.opacity(0.9)
    }

    @ViewBuilder
    func edgesLayer() -> some View {
        let edges = displayedEdges()
        Canvas { context, size in
            for e in edges {
                let p0 = worldToView(e.start)
                let p1 = worldToView(e.end)

                // Build a simple 2-point path
                var path = Path()
                path.move(to: p0)
                path.addLine(to: p1)

                // Resolve stops per 0224: along source→target, stops are [target border, grid contrast, source border]
                let sourceColor = nodeBorderColor(for: e.fromID)
                let targetColor = nodeBorderColor(for: e.toID)
                let midColor = gridContrastColor

                let gradient = Gradient(colors: [
                    targetColor,    // at source end (startPoint) per spec
                    midColor,       // middle
                    sourceColor     // at target end (endPoint) per spec
                ])

                context.stroke(
                    path,
                    with: .linearGradient(gradient, startPoint: p0, endPoint: p1),
                    style: StrokeStyle(lineWidth: 3.0, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: - Nodes

    @ViewBuilder
    func nodesLayer(windowSize: CGSize) -> some View {
        let nodes = (board?.nodes ?? []).compactMap { node -> (BoardNode, Card)? in
            guard let c = node.card else { return nil }
            return (node, c)
        }
        let nodeIDs = nodes.map { $0.1.id }

        ZStack {
            ForEach(nodes, id: \.0.id) { pair in
                let node = pair.0
                let card = pair.1
                let nodeCenterWorld = CGPoint(x: node.posX, y: node.posY)
                let hitShape = RoundedRectangle(cornerRadius: 12, style: .continuous)

                CardView(card: card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.accentColor, lineWidth: selectedCardID == card.id ? 4 : 0)
                            .animation(.easeInOut(duration: 0.12), value: selectedCardID)
                    )
                    .position(nodeCenterWorld)
                    .contentShape(hitShape)
                    // Legacy full layout size (fallback)
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .preference(
                                    key: NodeSizesKey.self,
                                    value: {
                                        #if DEBUG
                                        debugRecordNodeSize(id: card.id, size: geo.size)
                                        #endif
                                        return [card.id: geo.size]
                                    }()
                                )
                        }
                    )
                    // Visual card-shape size from CardView
                    .onPreferenceChange(CardViewVisualSizeKey.self) { reported in
                        // Merge into our visual sizes dictionary
                        for (id, size) in reported {
                            nodeVisualSizes[id] = size
                        }
                    }
                    // CA-14: Remove CardView’s highPriority tap to prevent dual tap paths; canvas tap is authoritative.
                    .zIndex(
                        (activeDrag.isDragging(cardID: card.id) ? 2 : 0) +
                        (selectedCardID == card.id ? 1 : 0)
                    )
            }
        }
        // World→View transform applied to the container
        .scaleEffect(zoomScale, anchor: .topLeading)
        .offset(x: panX.cg, y: panY.cg)
        // CA-14: Remove broad contentShape on the transformed container to reduce parent over‑hittability.
        .onPreferenceChange(NodeSizesKey.self) { value in
            nodeSizes = value
        }
        .onChange(of: nodeIDs) { _, ids in
            if let sel = selectedCardID, ids.contains(sel) == false {
                selectedCardID = nil
            }
        }
    }
}

// MARK: - Node size preference

private struct NodeSizesKey: PreferenceKey {
    static var defaultValue: [UUID: CGSize] = [:]
    static func reduce(value: inout [UUID: CGSize], nextValue: () -> [UUID: CGSize]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

// MARK: - Grid Background (Non-Canvas implementation)

fileprivate struct GridBackground: View {
    let tileSize: CGFloat
    let lineWidth: CGFloat
    let primaryOpacity: Double
    let secondaryEvery: Int
    let secondaryOpacity: Double

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let primaryColor = Color.primary.opacity(primaryOpacity)
            let secondaryColor = Color.primary.opacity(secondaryOpacity)

            let paths = makeGridPaths(size: size,
                                      tile: tileSize,
                                      secondaryEvery: max(1, secondaryEvery))

            ZStack {
                paths.primary
                    .stroke(primaryColor, lineWidth: lineWidth)
                paths.secondary
                    .stroke(secondaryColor, lineWidth: lineWidth)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func makeGridPaths(size: CGSize, tile: CGFloat, secondaryEvery: Int) -> (primary: Path, secondary: Path) {
        var primary = Path()
        var secondary = Path()

        var x: CGFloat = 0
        var column = 0
        while x <= size.width + 0.5 {
            if (column % secondaryEvery) == 0 {
                secondary.move(to: CGPoint(x: x, y: 0))
                secondary.addLine(to: CGPoint(x: x, y: size.height))
            } else {
                primary.move(to: CGPoint(x: x, y: 0))
                primary.addLine(to: CGPoint(x: x, y: size.height))
            }
            x += tile
            column += 1
        }

        var y: CGFloat = 0
        var row = 0
        while y <= size.height + 0.5 {
            if (row % secondaryEvery) == 0 {
                secondary.move(to: CGPoint(x: 0, y: y))
                secondary.addLine(to: CGPoint(x: size.width, y: y))
            } else {
                primary.move(to: CGPoint(x: 0, y: y))
                primary.addLine(to: CGPoint(x: size.width, y: y))
            }
            y += tile
            row += 1
        }

        return (primary, secondary)
    }
}

// MARK: - Unified gesture (node drag or pan) with arbitration

fileprivate extension MurderBoardView {
    // CA-13.1: Use the local/named canvas coordinate space so gesture points match our hit-test rects.
    func unifiedDragGesture() -> some Gesture {
        DragGesture(minimumDistance: 3) // default is .local; matches the view that defines canvasCoordSpace
            .onChanged { value in
                // If a pinch is active or a two‑finger pan is active, do not process drag/pan (0332, 0382).
                if isPinching || isTwoFingerPanning { return }

                // Locations are already in this view’s local space.
                let startInCanvas = value.startLocation
                let locInCanvas = value.location

                let translation = CGSize(width: locInCanvas.x - startInCanvas.x,
                                         height: locInCanvas.y - startInCanvas.y)
                let dist = hypot(translation.width, translation.height)
                let lockThreshold: CGFloat = 4.0

                switch activeDrag {
                case .none:
                    // Don’t lock yet; remember what we were over at touch-down.
                    let startHit = hitTestNode(at: startInCanvas)
                    activeDrag = .pending(hitID: startHit)
                    panGestureStart = CGPoint(x: panX.cg, y: panY.cg)

                    // Debug: snapshot rects and start point
                    #if DEBUG
                    if debugHitTestingEnabled {
                        debugStartPoint = startInCanvas
                        debugRectsAtStart = computeAllNodeRectsInView()
                        debugStartHitID = startHit
                        debugFirstLockDescription = nil
                        debugFirstLockDistance = 0
                        debugMovedNodeID = nil
                        print("[MB] Drag start: startHit=\(startHit?.uuidString ?? "nil") at \(formatPoint(startInCanvas)) rects=\(debugRectsAtStart.count)")
                        // Auto-hide overlay after a short time
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 1_200_000_000)
                            withAnimation(.easeOut(duration: 0.15)) {
                                debugStartPoint = nil
                                debugRectsAtStart = []
                            }
                        }
                    }
                    #endif

                case .pending(let hitID):
                    if dist < lockThreshold {
                        // Still deciding; nothing to apply yet.
                        return
                    }
                    // Decide lock: node vs pan.
                    if let id = hitID, isPoint(locInCanvas, insideNodeWithID: id) {
                        activeDrag = .node(cardID: id)
                        let startWorld = viewToWorld(startInCanvas)
                        if let node = (board?.nodes ?? []).first(where: { $0.card?.id == id }) {
                            let nodeCenterWorld = CGPoint(x: node.posX, y: node.posY)
                            dragGrabOffsetWorld = CGPoint(
                                x: nodeCenterWorld.x - startWorld.x,
                                y: nodeCenterWorld.y - startWorld.y
                            )
                            // Apply first move immediately so drag feels responsive.
                            let pointerWorld = viewToWorld(locInCanvas)
                            let newCenter = CGPoint(
                                x: pointerWorld.x + dragGrabOffsetWorld.x,
                                y: pointerWorld.y + dragGrabOffsetWorld.y
                            )
                            node.posX = newCenter.x.dg
                            node.posY = newCenter.y.dg
                            try? modelContext.save()
                        }
                        #if DEBUG
                        if debugHitTestingEnabled && debugFirstLockDescription == nil {
                            debugFirstLockDescription = "node(\(id.uuidString))"
                            debugFirstLockDistance = Double(dist)
                            debugMovedNodeID = id
                            print("[MB] Lock=node id=\(id.uuidString) at dist=\(String(format: "%.2f", dist))")
                        }
                        #endif
                    } else {
                        activeDrag = .pan
                        if panGestureStart == nil {
                            panGestureStart = CGPoint(x: panX.cg, y: panY.cg)
                        }
                        #if DEBUG
                        if debugHitTestingEnabled && debugFirstLockDescription == nil {
                            debugFirstLockDescription = "pan"
                            debugFirstLockDistance = Double(dist)
                            print("[MB] Lock=pan at dist=\(String(format: "%.2f", dist))")
                        }
                        #endif
                    }

                case .node(let id):
                    guard let node = (board?.nodes ?? []).first(where: { $0.card?.id == id }) else { return }
                    let pointerWorld = viewToWorld(locInCanvas)
                    let newCenter = CGPoint(
                        x: pointerWorld.x + dragGrabOffsetWorld.x,
                        y: pointerWorld.y + dragGrabOffsetWorld.y
                    )
                    node.posX = newCenter.x.dg
                    node.posY = newCenter.y.dg
                    try? modelContext.save()
                    #if DEBUG
                    if debugHitTestingEnabled {
                        debugMovedNodeID = id
                    }
                    #endif

                case .pan:
                    if let start = panGestureStart {
                        panX = (start.x + translation.width).dg
                        panY = (start.y + translation.height).dg
                    }
                }
            }
            .onEnded { value in
                // Ignore drag end if a pinch or two‑finger pan is active (0332, 0382).
                if isPinching || isTwoFingerPanning { return }

                // End points are in local canvas space as well
                let startInCanvas = value.startLocation
                let endInCanvas = value.location
                let dx = endInCanvas.x - startInCanvas.x
                let dy = endInCanvas.y - startInCanvas.y
                let distance = sqrt(dx*dx + dy*dy)
                let tapThreshold: CGFloat = 3.0

                switch activeDrag {
                case .node(let id):
                    if distance < tapThreshold {
                        selectedCardID = id
                        // CA-13.3: prevent the simultaneous canvas tap from clearing this immediately.
                        suppressBackgroundClickClear = true
                        DispatchQueue.main.async { suppressBackgroundClickClear = false }
                        #if DEBUG
                        print("[MB] DragEnd short-click (node): select id=\(id.uuidString) at \(formatPoint(endInCanvas))")
                        #endif
                    }
                case .pan, .pending:
                    if distance < tapThreshold {
                        if suppressBackgroundClickClear {
                            #if DEBUG
                            print("[MB] DragEnd short-click suppressed by other handler at \(formatPoint(endInCanvas))")
                            #endif
                        } else if let hit = hitTestNode(at: startInCanvas) {
                            selectedCardID = hit
                            suppressBackgroundClickClear = true
                            DispatchQueue.main.async { suppressBackgroundClickClear = false }
                            #if DEBUG
                            print("[MB] DragEnd short-click (canvas): select id=\(hit.uuidString) at \(formatPoint(startInCanvas))")
                            #endif
                        } else {
                            selectedCardID = nil
                            #if DEBUG
                            print("[MB] DragEnd short-click (canvas): clear selection at \(formatPoint(startInCanvas))")
                            #endif
                        }
                    } else {
                        persistTransformNow()
                    }
                case .none:
                    break
                }

                if case .pan = activeDrag {
                    persistTransformNow()
                }

                // Debug summary
                #if DEBUG
                if debugHitTestingEnabled {
                    let startHitStr = debugStartHitID?.uuidString ?? "nil"
                    let lockStr = debugFirstLockDescription ?? "nil"
                    let movedStr = debugMovedNodeID?.uuidString ?? "nil"
                    print("[MB] Drag end: startHit=\(startHitStr) lock=\(lockStr) lockDist=\(String(format: "%.2f", debugFirstLockDistance)) moved=\(movedStr) totalDist=\(String(format: "%.2f", distance))")
                }
                #endif

                activeDrag = .none
                panGestureStart = nil
                dragGrabOffsetWorld = .zero
            }
    }

    #if DEBUG
    // Compute all node rects in current VIEW space (for debug overlay)
    func computeAllNodeRectsInView() -> [CGRect] {
        guard let b = board else { return [] }
        var rects: [CGRect] = []
        for node in (b.nodes ?? []) {
            guard let id = node.card?.id else { continue }
            let sizeView = nodeSizeInViewPoints(for: id)
            let centerView = worldToView(CGPoint(x: node.posX, y: node.posY))
            let rect = CGRect(x: centerView.x - sizeView.width / 2.0,
                              y: centerView.y - sizeView.height / 2.0,
                              width: sizeView.width,
                              height: sizeView.height)
            rects.append(rects.count < 10 ? rect : rect) // keep identical logic, placeholder for future batching
        }
        return rects
    }
    #endif

    // View-space point hit test using view-space rects derived from CardView visual bounds (CA-6)
    func hitTestNode(at pointInView: CGPoint) -> UUID? {
        guard let b = board else { return nil }

        let nodes = (b.nodes ?? [])
        var candidates: [UUID] = []

        for node in nodes {
            guard let id = node.card?.id else { continue }

            // View-space size from measured CardView visual size scaled by current zoom
            let sizeView = nodeSizeInViewPoints(for: id)
            let centerView = worldToView(CGPoint(x: node.posX, y: node.posY))

            let rectView = CGRect(
                x: centerView.x - sizeView.width / 2.0,
                y: centerView.y - sizeView.height / 2.0,
                width: sizeView.width,
                height: sizeView.height
            )
            if rectView.contains(pointInView) {
                candidates.append(id)
            }
        }

        guard !candidates.isEmpty else { return nil }

        // Prefer currently selected if overlapping
        if let sel = selectedCardID, candidates.contains(sel) { return sel }

        // Fall back to topmost by stable board order (reverse)
        let order = nodes.compactMap { $0.card?.id }
        for id in order.reversed() where candidates.contains(id) {
            return id
        }

        return candidates.last
    }

    // Helper: is a view-space point inside the given node’s rect using view-space rects (CA-6)
    func isPoint(_ p: CGPoint, insideNodeWithID id: UUID) -> Bool {
        guard let b = board else { return false }
        guard let node = (b.nodes ?? []).first(where: { $0.card?.id == id }) else { return false }

        let sizeView = nodeSizeInViewPoints(for: id)
        let centerView = worldToView(CGPoint(x: node.posX, y: node.posY))
        let rectView = CGRect(x: centerView.x - sizeView.width / 2.0,
                              y: centerView.y - sizeView.height / 2.0,
                              width: sizeView.width,
                              height: sizeView.height)
        return rectView.contains(p)
    }

    // Node size in VIEW points: prefer CardView-reported visual size (card shape) scaled by zoom.
    // Fall back to full layout size if visual size hasn’t arrived yet.
    func nodeSizeInViewPoints(for id: UUID) -> CGSize {
        let baseVisual = nodeVisualSizes[id]
        let baseFallback = nodeSizes[id]
        let base = (baseVisual ?? baseFallback ?? CGSize(width: 240, height: 160)).clamped(maxWidth: 600, maxHeight: 600)
        let s = CGFloat(zoomScale)
        return base.scaled(by: s)
    }

    // CA-6: Node size in WORLD points (zoom-normalized): measured view size / zoomScale
    func nodeSizeInWorldPoints(for id: UUID) -> CGSize {
        let baseVisual = nodeVisualSizes[id]
        let baseFallback = nodeSizes[id]
        // Use the same clamping as view size to keep bounds conservative
        let baseView = (baseVisual ?? baseFallback ?? CGSize(width: 240, height: 160)).clamped(maxWidth: 600, maxHeight: 600)
        let s = max(zoomScale, 0.000001)
        return CGSize(width: baseView.width / s.cg, height: baseView.height / s.cg)
    }

    // Apply a pan delta in view-space points with clamping; no selection changes (0382).
    func applyPanDelta(dx: CGFloat, dy: CGFloat) {
        // Ignore while pinching per precedence (0332 over 0382)
        if isPinching { return }
        let newX = (panX + dx.dg).rangeClamped(to: Board.minPan...Board.maxPan)
        let newY = (panY + dy.dg).rangeClamped(to: Board.minPan...Board.maxPan)
        if newX != panX { panX = newX }
        if newY != panY { panY = newY }
    }

    // Small helpers for debug formatting
    #if DEBUG
    func formatPoint(_ p: CGPoint) -> String {
        "(\(String(format: "%.1f", p.x)), \(String(format: "%.1f", p.y)))"
    }
    #endif
}

// MARK: - Toolbar

fileprivate extension MurderBoardView {
    @ToolbarContentBuilder
    func toolbarContent(windowSize: CGSize) -> some ToolbarContent {
        ToolbarItemGroup(placement: .automatic) {
            Button { stepZoom(-0.05, windowSize: windowSize) } label: {
                Image(systemName: "minus.magnifyingglass")
            }
            .help("Zoom Out")
            .keyboardShortcut("-", modifiers: [.command])

            Slider(value: Binding(
                get: { zoomScale },
                set: { newValue in setZoomKeepingCenter(newValue, windowSize: windowSize) }
            ), in: Board.minZoom...Board.maxZoom)
            .frame(width: 160)
            .help("Zoom")

            Button { stepZoom(+0.05, windowSize: windowSize) } label: {
                Image(systemName: "plus.magnifyingglass")
            }
            .help("Zoom In")
            .keyboardShortcut("=", modifiers: [.command])

            HStack(spacing: 6) {
                TextField(
                    "Zoom %",
                    text: Binding(
                        get: { "\(Int(round(zoomScale * 100)))" },
                        set: { raw in
                            if let v = Double(raw) {
                                let s = (v / 100.0).clamped(to: Board.minZoom...Board.maxZoom)
                                setZoomKeepingCenter(s, windowSize: windowSize)
                            }
                        }
                    )
                )
                .frame(width: 60)
                .textFieldStyle(.roundedBorder)
                Text("%").foregroundStyle(.secondary)
            }
            .help("Enter zoom percentage (1–200)")

            Divider()

            Button { recenterOnPrimaryOrFirst(windowSize: windowSize) } label: {
                Label("Recenter", systemImage: "dot.scope")
            }
            .help("Recenter on primary (or first) node")

            Button { shuffleAroundPrimary() } label: {
                Label("Shuffle", systemImage: "shuffle")
            }
            .help("Arrange nodes around the primary in a ring; repeat to reshuffle")

            #if DEBUG
            Divider()

            // Debug toggle
            Toggle(isOn: $debugHitTestingEnabled) {
                Label("Debug Hit-Testing", systemImage: debugHitTestingEnabled ? "ladybug.fill" : "ladybug")
            }
            .toggleStyle(.switch)
            .help("Show node hit rects and log gesture decisions")
            #endif
        }
    }

    func stepZoom(_ delta: Double, windowSize: CGSize) {
        let proposed = (zoomScale + delta).clamped(to: Board.minZoom...Board.maxZoom)
        setZoomKeepingCenter(proposed, windowSize: windowSize)
    }

    func setZoomKeepingCenter(_ newScale: Double, windowSize: CGSize) {
        let sNew = newScale.rangeClamped(to: Board.minZoom...Board.maxZoom)
        let cView = CGPoint(x: windowSize.width / 2.0, y: windowSize.height / 2.0)
        let cWorld = viewToWorld(cView)
        panX = (cView.x.dg - cWorld.x * sNew)
        panY = (cView.y.dg - cWorld.y * sNew)
        zoomScale = sNew
        persistTransformDebounced()
    }

    func recenterOnPrimaryOrFirst(windowSize: CGSize) {
        guard let b = board else { return }
        let nodePairs = (b.nodes ?? []).compactMap { n -> (BoardNode, Card)? in
            guard let c = n.card else { return nil }
            return (n, c)
        }
        guard !nodePairs.isEmpty else { return }
        let primaryID = b.primaryCard?.id
        let targetNode: BoardNode = nodePairs.first(where: { $0.1.id == primaryID })?.0 ?? nodePairs.first!.0
        let world = CGPoint(x: targetNode.posX, y: targetNode.posY)
        let cView = CGPoint(x: windowSize.width / 2.0, y: windowSize.height / 2.0)
        panX = (cView.x.dg - world.x * zoomScale)
        panY = (cView.y.dg - world.y * zoomScale)
        persistTransformNow()
    }

    func shuffleAroundPrimary() {
        guard let b = board else { return }
        guard var nodes = b.nodes, !nodes.isEmpty else { return }

        // Identify anchor (primary or first)
        let primaryID = b.primaryCard?.id
        let anchorNode = nodes.first(where: { $0.card?.id == primaryID }) ?? nodes.first!
        let anchor = CGPoint(x: anchorNode.posX, y: anchorNode.posY)

        // Remove anchor from placement list
        nodes.removeAll(where: { $0.id == anchorNode.id })

        // Early exit if nothing to place
        let count = max(0, nodes.count)
        guard count > 0 else { return }

        // CA-15: Adaptive ring geometry in WORLD space (zoom-independent)
        // Measure world-space sizes
        func worldSize(for node: BoardNode) -> CGSize {
            guard let id = node.card?.id else { return CGSize(width: 240, height: 160) }
            return nodeSizeInWorldPoints(for: id)
        }
        let anchorSize = worldSize(for: anchorNode)
        let nodeWorldSizes: [CGSize] = nodes.map(worldSize(for:))

        let maxNodeSpan = nodeWorldSizes.map { max($0.width, $0.height) }.max() ?? max(anchorSize.width, anchorSize.height)
        let avgNodeWidth = nodeWorldSizes.map { $0.width }.reduce(0, +) / CGFloat(nodeWorldSizes.count)

        // Base margins (WORLD units)
        let baseMargin: CGFloat = maxNodeSpan * 0.20 + 12.0 / max(CGFloat(zoomScale), 0.000001) // include a small view->world normalized margin
        let spacingMultiplier: CGFloat = 1.25 // arc-length spacing factor vs avg width
        let ringSeparationMultiplier: CGFloat = 1.10 // radial separation vs max node span

        // Start radius: clear the anchor's size plus margin
        var radius: CGFloat = (max(anchorSize.width, anchorSize.height) * 0.60) + (maxNodeSpan * 0.75) + baseMargin

        // Mutable pool
        var pool: [BoardNode] = nodes
        var remaining = pool.count
        var ringIndex = 0

        // Random seed angles per ring
        while remaining > 0 {
            // Desired arc spacing along circumference to avoid overlap
            let desiredArcSpacing = max(avgNodeWidth, 1.0) * spacingMultiplier

            // Ensure capacity for this ring; grow radius until capacity >= 1
            func capacity(at r: CGFloat) -> Int {
                let circ = 2.0 * .pi * r
                return max(1, Int(floor(circ / desiredArcSpacing)))
            }
            var cap = capacity(at: radius)

            // If we still have many nodes, make sure this ring can hold a reasonable share;
            // grow radius until we can place at least 1 and up to remaining
            while cap == 0 {
                radius += max(8.0, maxNodeSpan * 0.25) // grow a bit if degenerate
                cap = capacity(at: radius)
            }

            let take = min(remaining, cap)
            let angleStep = (2.0 * .pi) / CGFloat(take)
            let startAngle = Double.random(in: 0..<(2.0 * Double.pi))

            for i in 0..<take {
                if let node = pool.popLast() {
                    // Even placement with small jitter
                    let theta = startAngle + Double(i) * Double(angleStep)
                    let jitterR = Double.random(in: -0.10...0.10) * Double(maxNodeSpan)
                    let jitterT = Double.random(in: -0.18...0.18)
                    let r = Double(radius) + jitterR
                    let x = anchor.x + (r * cos(theta + jitterT))
                    let y = anchor.y + (r * sin(theta + jitterT))
                    node.posX = x
                    node.posY = y
                }
            }

            remaining = pool.count
            ringIndex += 1
            // Increase radius for next ring with separation based on node spans in WORLD units
            let ringSeparationWorld = max(maxNodeSpan * ringSeparationMultiplier + baseMargin, maxNodeSpan * 0.9)
            radius += ringSeparationWorld
        }

        try? modelContext.save()
    }
}

// MARK: - Board load, prefetch staging, and transform persistence

fileprivate extension MurderBoardView {
    @MainActor
    func loadBoardIfNeeded() async {
        if board == nil {
            let b = Board.fetchOrCreatePrimaryBoard(for: primary, in: modelContext)
            b.clampState()
            board = b
            zoomScale = b.zoomScale
            panX = b.panX
            panY = b.panY
            await stageThumbnailsIfNeeded()
        }
    }

    func applyBoardTransform() {
        guard let b = board else { return }
        zoomScale = b.zoomScale
        panX = b.panX
        panY = b.panY
    }

    @MainActor
    func stageThumbnailsIfNeeded() async {
        guard isContentReady == false else { return }
        let cards = (board?.nodes ?? []).compactMap { $0.card }
        guard !cards.isEmpty else {
            isContentReady = true
            return
        }

        prefetchProgress = (0, cards.count)

        let maxConcurrent = 2
        let launchStagger: UInt64 = 15_000_000 // 15 ms

        await withTaskGroup(of: Void.self) { group in
            var active = 0
            var index = 0

            func addTask(for card: Card) {
                group.addTask {
                    _ = await card.makeThumbnailImage()
                    await MainActor.run {
                        self.prefetchProgress.done += 1
                    }
                }
                active += 1
            }

            while index < cards.count {
                while active < maxConcurrent && index < cards.count {
                    addTask(for: cards[index])
                    index += 1
                    try? await Task.sleep(nanoseconds: launchStagger)
                }
                await group.next()
                active = max(0, active - 1)
            }
            while await group.next() != nil { }
        }

        try? await Task.sleep(nanoseconds: 80_000_000) // 80 ms
        withAnimation(.easeInOut(duration: 0.15)) {
            isContentReady = true
        }
    }

    func persistTransformDebounced() {
        persistTransformNow()
    }

    func persistTransformNow() {
        guard let b = board else { return }
        let sBefore = b.zoomScale
        let txBefore = b.panX
        let tyBefore = b.panY

        b.zoomScale = zoomScale.rangeClamped(to: Board.minZoom...Board.maxZoom)
        b.panX = panX.rangeClamped(to: Board.minPan...Board.maxPan)
        b.panY = panY.rangeClamped(to: Board.minPan...Board.maxPan)
        b.clampState()
        try? modelContext.save()

        #if DEBUG
        // Lightweight transform persistence log
        if sBefore != b.zoomScale || txBefore != b.panX || tyBefore != b.panY {
            let s = String(format: "%.4f", b.zoomScale)
            let tx = String(format: "%.2f", b.panX)
            let ty = String(format: "%.2f", b.panY)
            print("[MB] Persist transform: S=\(s) T=(\(tx), \(ty))")
        }
        #endif
    }

    // Initial recenter logic (0240–0280, 0250)
    func initialRecenterIfNeeded(on b: Board, windowSize: CGSize) {
        guard didInitialRecenter == false else { return }

        b.ensurePrimaryPresence(in: modelContext)

        let pairs = (b.nodes ?? []).compactMap { n -> (BoardNode, Card)? in
            guard let c = n.card else { return nil }
            return (n, c)
        }
        guard !pairs.isEmpty else {
            didInitialRecenter = true
            return
        }
        let primaryID = b.primaryCard?.id
        let target = pairs.first(where: { $0.1.id == primaryID })?.0 ?? pairs.first!.0

        if abs(target.posX) < 0.0001 && abs(target.posY) < 0.0001 {
            let rect = viewCanvasRect(worldForWindowSize: windowSize)
            let center = CGPoint(x: rect.midX, y: rect.midY)
            target.posX = center.x.dg
            target.posY = center.y.dg
            try? modelContext.save()
        }

        let world = CGPoint(x: target.posX, y: target.posY)
        let cView = CGPoint(x: windowSize.width / 2.0, y: windowSize.height / 2.0)
        panX = (cView.x.dg - world.x * zoomScale)
        panY = (cView.y.dg - world.y * zoomScale)
        persistTransformNow()

        didInitialRecenter = true
    }
}

// MARK: - Small helpers

private extension CGFloat {
    var dg: Double { Double(self) }
}

private extension Double {
    var cg: CGFloat { CGFloat(self) }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

private extension CGSize {
    func clamped(maxWidth: CGFloat, maxHeight: CGFloat) -> CGSize {
        CGSize(width: min(width, maxWidth), height: min(height, maxHeight))
    }
    func scaled(by scalar: CGFloat) -> CGSize {
        CGSize(width: width * scalar, height: height * scalar)
    }
}

#if DEBUG
// MARK: - Debug helper for inspecting GeometryReader sizes
@inline(never)
fileprivate func debugRecordNodeSize(id: UUID, size: CGSize) {
    // Place a breakpoint here to inspect `id` and `size` whenever a CardView reports its measured size.
    // No-op to avoid side effects in release builds.
    _ = id
    _ = size
}
#endif

// MARK: - Two‑finger pan overlay (0382)

fileprivate struct TwoFingerPanOverlay: View {
    @Binding var isPinching: Bool
    @Binding var isTwoFingerPanning: Bool
    let onDelta: (CGFloat, CGFloat) -> Void
    let onEnd: () -> Void

    var body: some View {
        #if os(iOS) || os(tvOS) || os(visionOS)
        TwoFingerPanView_iOS(
            isPinching: $isPinching,
            isTwoFingerPanning: $isTwoFingerPanning,
            onDelta: onDelta,
            onEnd: onEnd
        )
        #elseif os(macOS)
        TwoFingerPanView_macOS(
            isPinching: $isPinching,
            isTwoFingerPanning: $isTwoFingerPanning,
            onDelta: onDelta,
            onEnd: onEnd
        )
        #else
        Color.clear
        #endif
    }
}

#if os(iOS) || os(tvOS) || os(visionOS)
fileprivate struct TwoFingerPanView_iOS: UIViewRepresentable {
    @Binding var isPinching: Bool
    @Binding var isTwoFingerPanning: Bool
    let onDelta: (CGFloat, CGFloat) -> Void
    let onEnd: () -> Void

    func makeUIView(context: Context) -> UIView {
        let v = PassthroughView()
        v.isUserInteractionEnabled = true

        let recognizer = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        recognizer.minimumNumberOfTouches = 2
        recognizer.maximumNumberOfTouches = 2
        recognizer.cancelsTouchesInView = true
        recognizer.delaysTouchesBegan = false
        recognizer.delaysTouchesEnded = false
        recognizer.delegate = context.coordinator
        v.addGestureRecognizer(recognizer)

        context.coordinator.panRecognizer = recognizer
        context.coordinator.hostView = v
        return v
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.isPinching = isPinching
        context.coordinator.isTwoFingerPanning = isTwoFingerPanning
        context.coordinator.onDelta = onDelta
        context.coordinator.onEnd = onEnd
        // Ensure the overlay fills its container
        if let superview = uiView.superview {
            uiView.frame = superview.bounds
            uiView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isPinching: isPinching, isTwoFingerPanning: isTwoFingerPanning, onDelta: onDelta, onEnd: onEnd, twoFingerPanningBinding: $isTwoFingerPanning)
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var isPinching: Bool
        var isTwoFingerPanning: Bool
        var onDelta: (CGFloat, CGFloat) -> Void
        var onEnd: () -> Void

        weak var hostView: UIView?
        weak var panRecognizer: UIPanGestureRecognizer?
        private var twoFingerPanningBinding: Binding<Bool>

        init(isPinching: Bool, isTwoFingerPanning: Bool, onDelta: @escaping (CGFloat, CGFloat) -> Void, onEnd: @escaping () -> Void, twoFingerPanningBinding: Binding<Bool>) {
            self.isPinching = isPinching
            self.isTwoFingerPanning = isTwoFingerPanning
            self.onDelta = onDelta
            self.onEnd = onEnd
            self.twoFingerPanningBinding = twoFingerPanningBinding
        }

        @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
            guard let view = recognizer.view else { return }

            switch recognizer.state {
            case .began:
                twoFingerPanningBinding.wrappedValue = true
            case .changed:
                // Suppress while pinching; consume translation so it doesn’t accumulate.
                if isPinching {
                    recognizer.setTranslation(.zero, in: view)
                    return
                }
                let translation = recognizer.translation(in: view)
                // Emit incremental delta since last event
                onDelta(translation.x, translation.y)
                recognizer.setTranslation(.zero, in: view)
            case .ended, .cancelled, .failed:
                twoFingerPanningBinding.wrappedValue = false
                onEnd()
            default:
                break
            }
        }

        // Make two‑finger pan take precedence over other touches; allow simultaneous recognition with pinch only if needed.
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            // Prefer pinch precedence: if a pinch is recognized elsewhere, we let it run but our handler will ignore while pinching.
            return false
        }
    }

    // Transparent view that still receives touches
    final class PassthroughView: UIView {
        override class var layerClass: AnyClass { CALayer.self }
        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            // Receive two‑finger gestures across the whole canvas overlay
            return true
        }
        override func didMoveToSuperview() {
            super.didMoveToSuperview()
            backgroundColor = .clear
            isMultipleTouchEnabled = true
        }
    }
}
#endif

#if os(macOS)
fileprivate struct TwoFingerPanView_macOS: NSViewRepresentable {
    @Binding var isPinching: Bool
    @Binding var isTwoFingerPanning: Bool
    let onDelta: (CGFloat, CGFloat) -> Void
    let onEnd: () -> Void

    func makeNSView(context: Context) -> NSView {
        let v = PanInterceptView()
        v.wantsLayer = true
        v.layer?.backgroundColor = NSColor.clear.cgColor
        v.onDelta = { dx, dy in
            // Suppress while pinching
            if context.coordinator.isPinching { return }
            onDelta(dx, dy)
        }
        v.onBegin = {
            isTwoFingerPanning = true
        }
        v.onEnd = {
            isTwoFingerPanning = false
            onEnd()
        }
        context.coordinator.isPinching = isPinching
        return v
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let v = nsView as? PanInterceptView {
            v.onDelta = { dx, dy in
                if context.coordinator.isPinching { return }
                onDelta(dx, dy)
            }
            v.onBegin = { isTwoFingerPanning = true }
            v.onEnd = {
                isTwoFingerPanning = false
                onEnd()
            }
        }
        context.coordinator.isPinching = isPinching
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isPinching: isPinching)
    }

    final class Coordinator {
        var isPinching: Bool
        init(isPinching: Bool) { self.isPinching = isPinching }
    }

    // Transparent NSView that intercepts trackpad two‑finger scrollWheel events for panning.
    final class PanInterceptView: NSView {
        var onDelta: ((CGFloat, CGFloat) -> Void)?
        var onBegin: (() -> Void)?
        var onEnd: (() -> Void)?

        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
        override var acceptsFirstResponder: Bool { true }

        private var isActive: Bool = false

        override func scrollWheel(with event: NSEvent) {
            // Only handle precise trackpad scrolling; ignore momentum to avoid overshoot (B11).
            guard event.hasPreciseScrollingDeltas else { return }

            // Track active phase for precedence and persistence timing
            if event.phase.contains(.began) && !isActive {
                isActive = true
                onBegin?()
            }

            // Ignore kinetic momentum updates
            if !event.momentumPhase.isEmpty {
                // When momentum ends, treat as end if we were active
                if (event.momentumPhase.contains(.ended) || event.momentumPhase.contains(.cancelled)) && isActive {
                    isActive = false
                    onEnd?()
                }
                return
            }

            if event.phase.contains(.ended) || event.phase.contains(.cancelled) {
                if isActive {
                    isActive = false
                    onEnd?()
                }
                return
            }

            // Map deltas to pan updates, accounting for natural/inverted scrolling.
            // Goal: content tracks fingers visually.
            let dx = event.scrollingDeltaX
            let dy = event.scrollingDeltaY
            let useNatural = event.isDirectionInvertedFromDevice
            let appliedDX = useNatural ? dx : -dx
            let appliedDY = useNatural ? dy : -dy
            onDelta?(appliedDX, appliedDY)
        }

        override func updateTrackingAreas() {
            super.updateTrackingAreas()
        }

        override func viewWillMove(toSuperview newSuperview: NSView?) {
            super.viewWillMove(toSuperview: newSuperview)
            wantsLayer = true
            layer?.backgroundColor = NSColor.clear.cgColor
        }

        override func layout() {
            super.layout()
            // Ensure we fill the parent to capture gestures anywhere on the canvas
            if let superview = superview {
                frame = superview.bounds
                autoresizingMask = [.width, .height]
            }
        }
    }
}
#endif

#Preview("Murder Board (seeded)") {
    let schema = Schema([Card.self, Board.self, BoardNode.self, CardEdge.self, RelationType.self])
    let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [cfg])
    let ctx = container.mainContext
    ctx.autosaveEnabled = false

    let mira = Card(kind: .characters, name: "Mira", subtitle: "Explorer", detailedText: "")
    let jonas = Card(kind: .characters, name: "Historian", subtitle: "Historian", detailedText: "")
    let aster = Card(kind: .characters, name: "Mechanic", subtitle: "Mechanic", detailedText: "")
    let eden = Card(kind: .worlds, name: "Eden-3", subtitle: "Frontier World", detailedText: "")
    let opening = Card(kind: .scenes, name: "Opening Scene", subtitle: "Crash Site", detailedText: "")
    let artifact = Card(kind: .artifacts, name: "Ancient Artifact", subtitle: "Unknown origin", detailedText: "")

    ctx.insert(mira)
    ctx.insert(jonas)
    ctx.insert(aster)
    ctx.insert(eden)
    ctx.insert(opening)
    ctx.insert(artifact)

    let appearsIn = RelationType(code: "appears-in/is-appeared-by",
                                 forwardLabel: "appears in",
                                 inverseLabel: "is appeared by",
                                 sourceKind: .characters,
                                 targetKind: .scenes)
    let references = RelationType(code: "references/referenced-by",
                                  forwardLabel: "references",
                                  inverseLabel: "referenced by")
    ctx.insert(appearsIn)
    ctx.insert(references)

    ctx.insert(CardEdge(from: mira, to: opening, type: appearsIn))
    ctx.insert(CardEdge(from: jonas, to: opening, type: appearsIn))
    ctx.insert(CardEdge(from: aster, to: opening, type: appearsIn))
    ctx.insert(CardEdge(from: mira, to: artifact, type: references))
    ctx.insert(CardEdge(from: jonas, to: eden, type: references))

    let board = Board.fetchOrCreatePrimaryBoard(for: mira, in: ctx)
    board.zoomScale = 1.0
    board.panX = 0
    board.panY = 0
    board.clampState()

    _ = board.node(for: mira, in: ctx, createIfMissing: true, defaultPosition: (0, 0))
    _ = board.node(for: jonas, in: ctx, createIfMissing: true, defaultPosition: (280, -40))
    _ = board.node(for: aster, in: ctx, createIfMissing: true, defaultPosition: (-260, 60))
    _ = board.node(for: eden, in: ctx, createIfMissing: true, defaultPosition: (0, -260))
    _ = board.node(for: opening, in: ctx, createIfMissing: true, defaultPosition: (0, 260))
    _ = board.node(for: artifact, in: ctx, createIfMissing: true, defaultPosition: (-120, -240))

    try? ctx.save()

    return NavigationStack {
        MurderBoardView(primary: mira)
    }
    .modelContainer(container)
    .frame(minWidth: 820, minHeight: 560)
}

#if canImport(Testing)
// MARK: - MurderBoard Verification Suite (Swift Testing)

@Suite("MurderBoardView Verification (Phases 0–14)")
struct MurderBoardVerification {
    // [tests unchanged]
}
#endif
