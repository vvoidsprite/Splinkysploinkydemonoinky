# Castle art pass: the gate and the entrance hall

Plan only. No game code was written for this.

## In plain words

**The gate.** Right now the manor is a flat strip of repeated wall with a door stuck on it. After this pass Maren arrives facing a real castle front, built the way the owner's reference picture shows it:
- A tall grey keep sits in the middle, with arrow slits, a red trim band and two red-framed gothic windows.
- A dark arched doorway sits at its foot, with stone steps and a flickering torch on each side.
- Lower wings with battlements and gothic window niches spread to both sides.
- Slim red-roofed towers with torches stand at the outer edges.
- A cobbled forecourt and path lead up to the door. The dead trees, the lily cup, the bell post and the cathedral spire are all still there.

The building needs about three times the height the old wall had. To make room, everything you can walk on or talk to moves down the map by the same amount. The walk from where Maren arrives up to Edrin stays about the same length. As she walks up, the camera slowly reveals the keep above her, which gives a small "arrival" moment for free.

**The hall.** Today the hall is an empty dark box, which is why Edrin's walk feels long. After this pass it is a grand but cold hall:
- A grey inlaid stone floor, with a dark crimson runner up the middle.
- Two rows of tall fluted stone pillars line the walk, each hung with a red drape.
- Tall gothic windows along the far wall let in pale dusk light that falls across the floor in slanted shafts.
- At the far end, a stair rises out of sight, flanked by two wall torches. This is "upstairs to the rooms", where Maren will be taken.
- Two fire bowls by the entrance and two candelabras near the coat hooks and the hymn board give small warm pools of light in a cold, blue-violet room.

The walk now passes something every few steps (pillar, drape, light shaft), so it reads as a procession, not dead time.

**What does not change:**
- Every conversation, story flag, exit and spawn works exactly as before.
- Edrin walks the same path in the hall and on the same cells.
- All existing tests keep passing. The gate tests only get their cell numbers moved down to match.

## Facts the builders must respect

- **The walking grid is 16 px.** Characters stand on tile centres. A tile is blocked when a solid body reaches more than 2 px into it. Props block exactly one tile with a 16x16 collider at (0,-8) from their "feet" point.
- **`tile_painter.gd` works in 32 px atlas tiles.** Each legend entry is `Rect2i(col,row,w,h)` in 32-px units, and w/h above 1 repeats a seamless block. It paints only when the layer has no saved cells, so never save painted cells into the scene.
- **`frame_loop.gd` loops frames 0..frame_count-1** (defaults: 6 frames at 8 fps) with a random start, so neighbouring torches don't flicker in sync.
  - `Anim/torch.png`, `Anim/light1a.png` and `Anim/light2a.png` are all 4 columns x 2 rows with 6 frames used. Set `hframes = 4` and `vframes = 2`, and leave `frame_count` at 6.
  - torch and light1 frames are 32x32; light2 frames are 32x64.
  - Use the "a" (warm flame) variants only. The b/c variants are recoloured flames and don't suit dusk.
- **Large pieces are `Sprite2D` region cuts, not tiles.** These are the keep, wings, towers, doorway, windows, pillars, stairs and drapes. Set `centered = false` and `region_enabled = true`, and use an offset so the sprite's bottom edge sits on the node's position (its "feet"). That way y-sorting puts Maren in front of or behind it correctly.
  - Freestanding pieces (pillars, fire bowls, trees) are `StaticBody2D` with a `Sprite` child and a one-tile `Shape`. Copy the DeadTree and Pillar pattern already in `gate.tscn` and `manor_room.tscn`.
  - Pieces that are part of a wall get no collider of their own. The big wall collider covers them.
- **Asset licence** (`assets/RPG_Buildings_CASTLE_v1.0/public-license.txt`): free for commercial use, edits allowed, no reselling, credit appreciated. We will credit it (W3).
- **Use `castle_outside.png`, not `castle_outside_shadows.png`.** The shadow sheet's pieces are wider, and the regions below are measured on the plain sheet. One soft dark strip at the foot of the building stands in for the shadow (see G6).

## Part G: the gate exterior

### G0. Shift the whole gate map down 14 rows (224 px)

The old wall base was at y=112 (row 7). The new building base is at **y=336** (row 21). Everything gameplay-related gets **+224 px in y, or +14 rows**. x never changes.

| Thing | Old | New |
|---|---|---|
| `area_size` | 640x416 | **640x640** |
| North wall collider | 640x112 centred (320,56) | **640x336 centred (320,168)**, blocks rows 0-20 |
| West / East colliders | 16x416 at y 208 | **16x640 at y 320** |
| South collider | at y 424 | **at y 648** |
| Spawn `start` | (328,360), cell (20,22) | **(328,584), cell (20,36)** |
| Edrin | (328,136), cell (20,8) | **(328,360), cell (20,22)** |
| Edrin's walk target in `gate.gd` | `Vector2i(20, 7)` | **`Vector2i(20, 21)`** |
| Exit | (320,116) | **(320,340)** |
| LilyCup | (248,296) | **(248,520)** |
| BellPost | (232,128) | **(232,352)** |
| CathedralLook | (530,96) | **(530,320)** |
| DeadTreeW / DeadTreeE | (88,232) / (552,296) | **(88,456) / (552,520)** |

The camera already follows `area_size` (Main sets its limits), so nothing else changes. Saves can't be made at the gate (the crow lives in Maren's room), so no old save points into the new wall.

### G1. Ground (tiles)

- **`Grass` layer:** keep it, and extend it to 20 rows of `g`.
- **New `Cobble` layer** (tile_painter on `RPGFW_Set1_v1.0/_PNG/g_terrain1.png`, `z_index -1`, above Grass):
  - a forecourt 11 tiles wide (x 144-496, 32-px cols 5-15) from row 10 to row 12 (y 320-416);
  - the path 2 tiles wide (cols 9-10, x 288-352) from row 13 to the bottom.
  - The castle pack has no ground cobble, so it comes from the farm set's cobble block at the right side of `g_terrain1.png`. My estimate is **`Rect2i(35, 0, 4, 3)`**. The builder must view the sheet and confirm it is a seamless block, and fix the numbers if not.
  - Fallback: the grey cobble in `g_terrain3.png`.
- **Delete** the old `ManorWall` tile layer and the `Path` ColorRect.

### G2. The keep (centre)

Region cuts from `castle_outside.png`, under `Props`, with no colliders.

| Piece | Region | Placement (feet = bottom-left via offset) |
|---|---|---|
| Keep tower | `Rect2(823, 196, 178, 328)` | position (320,336), offset (-89,-328): spans x 231-409, y 8-336 |
| Two large red-framed gothic windows | `Rect2(1344, 16, 32, 48)` and `Rect2(1392, 16, 32, 48)` | on the keep's middle tier, about y 160-208, at x≈ 268 and 340 (left edges). Must not cover the red trim band or the arrow slits. Nudge by eye, keep it symmetric about x=320 |
| Doorway with steps | `Rect2(1080, 544, 80, 83)` (already used as `Arch`) | position (320,336), offset (-40,-83). Reuse the existing `Arch` node: just move it |

Window sprites and the doorway need a `z_index` or tree order that puts them above the keep. Simplest: put the keep at `z_index -1` and leave the overlays at 0 but **without** y-sort (child of a plain `Node2D "Facade"` at z -1, ordered keep → windows → door).

**Important:** Maren must never sort *behind* the facade. Put every flat wall piece in `Facade` (z -1, no y-sort). Only freestanding things go in `Props` (y-sorted).

### G3. Wings (left and right of the keep)

Each wing is two stacked region cuts. The east wing is the same cut with `flip_h = true`, so the front is symmetric like the reference.

| Piece | Region | West placement | East placement |
|---|---|---|---|
| Ground storey (brick, gothic niches) | `Rect2(0, 480, 232, 110)` | top-left (0,226) | top-left (408,226), flip_h |
| Upper storey (rampart walk, battlements, dormers, pilasters) | `Rect2(0, 291, 232, 172)` | top-left (0,54) | top-left (408,54), flip_h |

Overlap the two storeys by a few pixels if a seam shows. The wings end 2 px under the keep's sides; the keep is drawn after them, so it covers the join.

Acceptance by eye:
- no transparent gaps between the pieces;
- the battlements read as a continuous roofline;
- the keep stands about 46 px above the wings.

### G4. Corner towers and torches

- **Slim red-roof towers:** `Rect2(12, 624, 40, 188)`, feet at (20,336) and (620,336) (offset (-20,-188); the east one uses flip_h). They go in `Facade`, drawn last.
- **Wall torches** (`Anim/torch.png`, frame_loop, hframes 4, vframes 2):
  - two at the door, positions (264,300) and (376,300);
  - two on the corner towers, positions (20,250) and (620,250).
  - z 0, inside `Facade` after the towers.
- **Warm glow under each torch:** a `Polygon2D` octagon about 28 px across, `Color(1, 0.7, 0.35, 0.18)`, with a `CanvasItemMaterial` set to additive blend. Copy Edrin's `LampGlow` polygon, scaled ×3.

### G5. Cathedral spire

Keep the `Cathedral` Polygon2D silhouette, but move it up and behind the east wing so its spires show above the battlements:
- polygon y values: the roofline at y≈54 and the tip at y=0;
- x range 470-592, unchanged;
- `z_index -2` so it draws behind the wing.

`CathedralLook` moves as in G0. Maren still "looks at" it from cell (33,21), facing up.

### G6. Foot shadow and mood

- A `Polygon2D` strip, black at alpha 0.25, from x 0-640, y 330-346, in `Facade` (z -1, drawn last). It grounds the building on the cobbles.
- Keep `Dusk` CanvasModulate at `Color(0.72, 0.62, 0.8)`. It already tints the warm torches toward a melancholy dusk.

### G7. Props that stay

- **LilyCup, BellPost, Edrin:** only their positions change.
- **BellPost:** it now stands just in front of the west wing, at the wall line (y 352). That is good, because the rope hangs by the wall. Its interact cell is unchanged relative to the post.

### G acceptance

- [ ] New Game shows Maren on the cobble path. The lower facade (doorway, torches, wing niches) is visible at the top of the screen. Walking up reveals the keep's top.
- [ ] The front is symmetric about x=320 and matches the reference's layout: keep, red trim, 2 gothic windows, arched door with steps, 2 door torches, battlemented wings, corner towers.
- [ ] Torches flicker out of sync. No flat placeholder rectangles remain except the LilyCup and BellPost (out of scope).
- [ ] Every gate interaction, Edrin's walk into the door and the transition to the hall work.
- [ ] `test_prologue_gate_hall` and `test_maren_room` pass after the cell updates in W1.

## Part H: the entrance hall interior

**No gameplay position changes in this scene at all.** Hooks, HymnBoard, FrontDoor, Edrin, RoomExit, Spawns and the four wall colliders keep their exact positions and shapes. The hall tests stay untouched.

**Cells that must stay walkable** (the new test checks them):
- column 20, rows 6-27;
- (19,6), (9,6), (30,6) and (20,26).

### H1. Floor (tiles, `Tiles` layer legend)

- **Floor:** change `"."` from the wood floor `Rect2i(15,14,2,2)` to the grey inlaid flagstone **`Rect2i(14, 38, 2, 2)`** (castle_interriors x 448-512, y 1216-1280: one square inlay per tile).
- **Border band:** add `","` = **`Rect2i(14, 36, 2, 2)`** (grey interlocking stone, x 448-512, y 1152-1216). Use it for the first floor row under the wall (row 3) and the floor column next to each side wall (col 1 and col 18), so the room gets a framed edge.
- The builder views those two blocks at 2x and confirms they tile without seams. If one doesn't, it falls back to `Rect2i(17,38,2,2)` (the brown inlay twin).
- Wall, border and ceiling letters stay as they are.

**The runner:** keep the `Runner` ColorRect, recoloured to deep crimson `Color(0.3, 0.09, 0.11)`. Add two 2-px-wide child ColorRects, `Color(0.55, 0.42, 0.2)`, down its left and right edges as a faded gold trim. Same rectangle as now (x 296-360, y 112-448).

### H2. Colonnade (freestanding, y-sorted, in `Decor`)

Six pillars, each a `StaticBody2D` with:
- a `Sprite` child: `castle_interriors.png`, `Rect2(166, 435, 20, 155)` (tall grey fluted pillar), offset (-10,-155);
- a 16x16 `Shape` at (0,-8).

| Pillar | Feet position | Cell blocked |
|---|---|---|
| PillarW1 / PillarE1 | (232,176) / (424,176) | (14,10) / (26,10) |
| PillarW2 / PillarE2 | (232,256) / (424,256) | (14,15) / (26,15) |
| PillarW3 / PillarE3 | (232,336) / (424,336) | (14,20) / (26,20) |

**Drapes on the pillars:** each pillar gets a child `Sprite2D` "Drape" (no collider) from `castle_decoratives.png`, `Rect2(7, 269, 18, 36)` (red torn drape), offset (-9,-120), drawn after the pillar sprite.

### H3. North wall: windows, stair, torches (flat, `z_index -1`, no y-sort)

Put these in a new `Node2D "WallDecor"` at z -1, placed after `Tiles` and before `Runner` in tree order.

- **Four tall gothic windows:** `castle_interriors.png`, `Rect2(96, 993, 32, 48)`, top-left at y=40. Left edges at x **56, 200, 424, 568**. These clear the hooks rail (x 116-188) and the hymn board (x 474-502).
- **Stair up to the rooms:** replace the `RoomDoor` ColorRect with `Rect2(384, 896, 64, 64)` (a stone stair between side rails), top-left (296,32), so it fills the wall band behind the RoomExit. This reads as "the way up". The builder views `Rect2(448,896,64,64)` too and picks whichever reads better as a stair going up and away.
- **Red valance** over the stair head: `castle_decoratives.png`, `Rect2(98, 224, 59, 36)`, top-left (299,30).
- **Torches:** move TorchW and TorchE from x 240/416 to **x 280 and 376** (y 56 unchanged), so they flank the stair.

### H4. Dusk light through the windows

Under each window, add a slanted light shaft: a `Polygon2D` in `WallDecor`, with a `CanvasItemMaterial` set to **additive** blend and `Color(0.85, 0.55, 0.6, 0.09)` (a faint rose-violet dusk).
- The quad starts at the window sill (x..x+32, y 88) and falls down and to the right onto the floor, ending around (x+40..x+88, y 220).
- The shafts lie on the floor. Characters walk through them.

### H5. Warm lights (freestanding, in `Decor`, y-sorted)

- **Two fire bowls** (`Anim/light1a.png`, frame_loop, hframes 4, vframes 2, offset (-16,-28)) on `StaticBody2D` with a 16x16 collider at (0,-8):
  - feet at (264,400) and (392,400);
  - they block cells (16,24) and (24,24), clear of col 20 and of the spawn row 26.
- **Two candelabras** (`Anim/light2a.png`, frame_loop, hframes 4, vframes 2, offset (-16,-62)), as in `manor_room.tscn`:
  - feet at (72,128) and (584,128);
  - they block cells (4,7) and (36,7).
- **Glows:** each torch, fire bowl and candelabra gets the same additive warm glow polygon as G4.

### H6. Mood

- Add a `CanvasModulate "Chill"`, `Color(0.62, 0.6, 0.78)`. This is the cold blue-violet hall that the warm lights cut into.
- The front door (south) keeps its `FrontDoorLeaf`, recoloured to wood `Color(0.24, 0.16, 0.11)`, plus a 2-px iron band ColorRect across it. It is out of view at the bottom wall, so that is enough.
- Fix the missing blank lines before `[node name="HymnBoard"...]`, `[node name="FrontDoor"...]` and the gate's `BellPost`/`CathedralLook`/`Edrin` headers. This is cosmetic only, and each builder fixes it in their own file.

### H acceptance

- [ ] When Edrin starts walking, the screen shows pillars, drapes, the runner, light shafts and at least two flickering lights. Every few steps something passes by.
- [ ] Nothing hides Maren or Edrin badly. Pillars sort in front of or behind characters correctly, and nothing covers column 20.
- [ ] The hooks, hymn board, front door and the stair exit still respond from the same spots.
- [ ] The room reads cold overall, with warm pools of light, and stays readable at 640x360.
- [ ] `test_prologue_gate_hall` passes untouched for the hall parts.

## Work items and order

Two builders run at once at most, and never on the same file.

### Wave 1 (parallel)

**W1: Gate exterior (Builder A)**
- **Files:**
  - `scenes/areas/prologue/gate.tscn`
  - `scripts/areas/prologue/gate.gd` (only the walk cell `Vector2i(20, 7)` → `Vector2i(20, 21)`)
  - `tests/test_prologue_gate_hall.gd`, gate lines only:
    - F2 spawn (20,22) → **(20,36)**;
    - line 44 (20,9) → **(20,23)**;
    - F21 targets (15,19) → **(15,33)**, (14,9) → **(14,23)** and (33,7) → **(33,21)**.
  - `tests/test_maren_room.gd` lines 106 and 116: (20,9) → **(20,23)** and (20,8) → **(20,22)**.
- **Do:** G0-G7.
- **Done when:**
  - G acceptance is met;
  - both test files pass;
  - a screenshot of the gate at spawn and one with Maren next to Edrin are attached to the hand-back.

**W2: Hall interior (Builder B)**
- **Files:** `scenes/areas/prologue/entrance_hall.tscn` only.
- **Do:** H1-H6.
- **Done when:**
  - H acceptance is met;
  - `test_prologue_gate_hall` and `test_maren_room` still pass (W2 must not change any cell);
  - screenshots of the hall at spawn and mid-walk are attached to the hand-back.

### Wave 2 (after both are reviewed)

**W3: Art-layout test, full run, credit (one builder)**
- **Files:**
  - new `tests/test_castle_art.gd`
  - `README.md` (one credit line under a "Credits" heading: "Castle tiles and animations: RPG Buildings CASTLE by Szadi art")
- **Test checks**, headless, same style as the other tests:
  1. **Gate cells free:** column 20 rows 21-36; (20,23), (15,33), (14,23), (33,21); spawn (20,36).
  2. **Gate wall solid:** every cell in rows 0-20 is blocked.
  3. **Hall cells free:** column 20 rows 6-27; (19,6), (9,6), (30,6), (20,26).
  4. **Hall pillars block their cells:** (14,10), (26,10), (14,15), (26,15), (14,20), (26,20).
  5. **Lights animate:** every node using `frame_loop.gd` in both scenes has a texture and `hframes*vframes >= frame_count`. After 0.5 s at least one of them has changed frame.
  6. **Region cuts are sane:** every region-enabled Sprite2D in both scenes has its `region_rect` inside its texture's size (this catches typos in pixel regions).
  7. **Spawn checks:**
     - the gate's `area_size` is (640,640);
     - Edrin's gate cell is (20,22) and the Exit lies in row 21;
     - the hall's Edrin is still at cell (20,24).
- **Done when:** the new test and all 9 existing test files pass. Report the counts per file.

## Open questions for the owner

Defaults apply if there is no answer.

1. **The gate gets taller (14 rows).** Maren still starts about the same walk away from Edrin, and the castle top reveals as she walks up. OK? *Default: yes.*
2. **Cobble source:** the castle pack has no ground cobblestone, so the forecourt borrows the farm set's cobble, tinted by the dusk filter. OK, or would you rather have plain packed earth? *Default: cobble.*
3. **Cathedral:** it stays as a dark silhouette peeking over the east wing, not real art. *Default: silhouette. Real cathedral art would be its own pass.*
4. **The stair at the end of the hall** implies the rooms are upstairs. That fits "Edrin leads her up to her room". Do you want it to be a door instead? *Default: stair.*
5. **Drape colour:** the sheet has red, blue and green drapes. Red matches the keep's trim and the reference. *Default: red.* Blue would feel colder and sadder.
6. **Light level:** the hall is cold blue-violet with small warm pools. If it feels too dark when you play it, we raise the hall filter one step. *Default: as planned.*
7. **The lily cup and bell post** are still simple placeholder shapes. Should they get real art in this pass or a later one? *Default: later; they are not castle pieces.*
