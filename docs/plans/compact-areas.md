# Compact areas, revision 2: the room, the gate and the hall, built to feel real

This is a plan only. No game code has been written for it.

It replaces the first compact-areas plan. The engine work from that plan (item E) is already done: small maps sit in the middle of the screen, loading always lands Maren on a free tile, the screen edge is black, and outdoor maps can be ringed by a forest. Maren's room was rebuilt once from the first plan; this revision redoes it properly.

The owner's guidance on the reference pictures was: "Don't copy them, but take reference in how they are used. They feel real and intentional." Every choice below follows that rule. A wall has a reason to be there, furniture stands where a person would put it, and light comes from somewhere.

## In plain words

**Maren's room** becomes a real small manor bedroom instead of a box with coloured blocks.
- The back wall has a proper window with red drapes, and the crow lands on its stone sill.
- Under the wall stands a narrow candle table holding the three candles, each with its little plaque on the table's front.
- The covered mirror hangs in the wall to the right.
- Along the right side of the back wall there's a tall wardrobe, a nightstand holding the prayer paper, and the bed with its headboard against the wall. A chest sits at the foot of the bed.
- A washstand with a bowl stands by the left wall. A rug covers the middle of the floor, and the door is in the front wall.
- Moonlight falls from the window across the floor.
- The room is a little wider than now, so the furniture fits without crowding the puzzle.
- Nothing about the story changes: Edrin's goodnight, the key turning, the crow, the candles, the mirror and the end card all work exactly as now.

**The gate** becomes a small yard in front of a castle that looks built, not pasted.
- The castle front is layered:
  - the tall keep at the back;
  - battlemented wings with a walkway along their tops;
  - a round red tower at each corner;
  - two slim towers with red banners flanking a gothic doorway with steps;
  - torches on either side of the door;
  - a soft shadow where the walls meet the ground.
- The cathedral's spires show over the right wing.
- A cobbled forecourt runs along the castle, with a cobbled path leading down from it.
- The yard is ringed by forest. Two dead trees, the bell post and the lily cup stand in it.
- At the bottom of the path, the yard's iron gate stands open against a low wall, the way Maren came in.
- Edrin waits at the door and walks in the same way as now.

**The entrance hall** becomes one long, narrow, deliberate hallway floating in black.
- Maren comes in through the front door into a small nook at the left end. Edrin leads her up into the hall and down its whole length to a stone stair at the far right end, which goes up to her room.
- On the left (north) wall, from left to right:
  - the coat hooks;
  - a carved pillar set into the wall;
  - a closed side door in its own arched frame;
  - a pillar;
  - a tall window with a red valance, letting a beam of dusk light fall across the floor;
  - a pillar;
  - the hymn board;
  - a pillar;
  - a second dusk window;
  - the stair.
- Torches burn on the pillars. A red runner with gold edging runs the full length of the floor.
- The pillars are part of the wall, not poles standing in the middle of the floor.

**The forest ring** gets an upgrade, so it stops looking like one tree stamped over and over.
- It will mix pines, oaks, birches and the odd dead tree, in clumps rather than an even grid.
- A fringe of ferns, grass tufts and stumps will run along the inner edge, where the forest meets the yard.
- Trees below the yard will no longer hang over the bottom of the map and hide Maren.

## Facts the builders rely on

- Godot 4.6, GDScript, 2D. The screen is 640x360. Maren moves on a 16 px grid (a "cell"). A cell counts as blocked when a body reaches more than 2 px into it.
- The tile painter (`scripts/world/tile_painter.gd`) paints 32 px atlas tiles from a legend of `Rect2i(col,row,w,h)` in 32 px units. It only paints a layer that has no saved cells.
- **How props are built:**
  - A prop is a `StaticBody2D` with a `Sprite2D` child (`centered=false`, `region_enabled`, offset so the sprite's bottom edge sits at the body's origin, its "feet") and a 16x16 shape at (0,-8). Bigger footprints use bigger shapes, as given below.
  - Flat wall pieces (windows, drapes, pillars set into the wall, the hymn board, wall doors) go in a `Node2D` at z -1 with no y-sort, so Maren never sorts behind them.
  - Freestanding furniture goes in the area's y-sorted node.
- **Interacting:** Maren interacts with the nearest visible `interactable` Area2D overlapping the cell in front of her (`player.gd _front_target`). An Area can sit inside a blocked cell.
- **Animated lights:** `scripts/world/frame_loop.gd` animates the `torch.png`, `light1a.png` and `light2a.png` sheets in `assets/RPG_Buildings_CASTLE_v1.0/Anim/`. Each sheet is 4x2 frames with 6 used. Use only the "a" light variants.
- **Area metadata:**
  - `area_size` (Vector2i);
  - `border`: "black" (the default) or "trees";
  - `area_label`.
- **Camera:** a map smaller than the screen is centred and doesn't scroll. The gate is 464 wide, so it's centred left to right and scrolls up and down.
- **Godot executable:** `C:\Users\julie\Documents\GameDev\Godot\Godot_v4.6.1-stable_win64_console.exe`.
- **Running a test:** `<exe> --path . --headless --fixed-fps 60 --script tests/<name>.gd` (run from the project folder).

## Verified art regions

Every region below was cut out of the sheet and inspected by eye at 2-4x zoom, and its edges were measured with a connected-pixel scan. Each is written as `Rect2(x, y, w, h)` in sheet pixels.

**`castle_interriors.png`** (1056x1280)

| Use | Region | Notes |
|---|---|---|
| Wall tiles | `b` = atlas (2,6), `B` = (2,8) | Existing legend; the brick block sits at px 0-160 x 160-288 |
| Pillar set into the wall (bronze bands), 3 tiles tall | `Rect2(384,128,32,142)` | Ceiling cornice 0-32, pillar face 32-112, base 112-142. The base overhangs the floor by 14 px. Twin at x 352. |
| Taller variant | `Rect2(288,96,32,174)` | Spare; don't use (too tall for a 3-tile wall) |
| Wall run with three grey fluted pillars | `Rect2(22,608,116,110)` | Pillars at about x 24-40, 72-88 and 120-136. Spare. |
| Tall tracery window | `Rect2(96,993,32,48)`, twin `Rect2(144,993,32,48)` | Hall windows and the bedroom window |
| Medium window | `Rect2(2,948,28,44)` | Spare |
| Closed gothic door | `Rect2(448,975,32,49)`, `Rect2(496,975,32,49)`, `Rect2(544,975,31,49)`, `Rect2(593,975,31,49)` | Arched stone frame, studded door. The first two have the handle on the right. |
| Open doorway with steps | `Rect2(448,1039,32,49)`, `Rect2(496,1039,32,49)`, `Rect2(544,1039,32,49)`, `Rect2(592,1039,32,49)` | Door leaf swung in, dark interior. Spare. |
| Stair in a brick alcove | `Rect2(512,896,64,64)` | End of the hall. Alternative: `Rect2(576,896,64,64)`. |
| Stone stair between rails | `Rect2(384,896,64,64)` | Spare |
| Floor: grey inlay | atlas `Rect2i(14,38,2,2)` | Hall floor (existing `.` legend) |
| Floor: wood planks | atlas `Rect2i(14,13,4,4)` (px 448,416,128,128) | Bedroom floor option, see the open questions |
| Glass pane on a stand | `Rect2(7,1072,18,32)` | Spare |

**`castle_decoratives.png`** (512x512)

| Use | Region |
|---|---|
| Red short valance | `Rect2(32,288,64,25)`, twin `Rect2(160,288,64,25)` |
| Red narrow banner | `Rect2(7,269,18,36)`, twin `Rect2(231,269,18,36)` |
| Red centre valance with tails | `Rect2(98,224,59,36)` |
| Bowl (washstand) | `Rect2(7,72,16,16)` |
| Candlestick (nightstand) | `Rect2(43,81,8,15)` |
| Small candelabra | `Rect2(71,65,16,31)` (spare) |
| Hanging lantern | `Rect2(458,256,11,31)` (spare) |

**`castle_outside.png`** (1600x1056)

| Use | Region | Notes |
|---|---|---|
| Keep | `Rect2(823,196,178,328)` | Crenellated top to about y 340, slit wall, wider lower tier from about 420 |
| Wing, upper (parapet and rampart walk, pilastered face) | `Rect2(0,291,176,172)` | Left half of the full `(0,291,352,172)` |
| Wing, lower (brick with gothic niches) | `Rect2(0,480,144,110)` | Left part of `(0,480,352,110)` |
| Round red tower | `Rect2(2,832,60,202)` | Twin at `(66,832,60,202)` |
| Slim red-roof tower | `Rect2(12,624,40,188)` | |
| Gothic portal with steps (blue gem) | `Rect2(1449,427,46,105)` | Twin at `(1529,427,46,105)` |
| Gabled portal | `Rect2(1440,544,64,118)` | Alternative, see the open questions |
| Iron gate leaves | `Rect2(960,841,31,55)`, `Rect2(993,841,31,55)` | |
| Fence posts | `Rect2(960,768,5,64)` | |
| Low wall post | `Rect2(768,932,32,68)` | |

**`veg_decoratives.png`** (1024x800). The dark-green set is rows y 0-256; y 256-512 repeats it in a lighter, yellower green. Bounding boxes include the soft shadow at the base.

| Use | Region |
|---|---|
| Pine, large | `Rect2(587,20,65,168)` |
| Pine, medium | `Rect2(682,32,79,156)` (fixes the old rough `(682,30,80,158)`) |
| Pine, small | `Rect2(778,97,44,91)` |
| Oak, medium | `Rect2(177,80,92,172)` |
| Oak, small round | `Rect2(313,167,48,85)` |
| Birch, tall | `Rect2(387,26,85,194)` |
| Birch, medium | `Rect2(481,77,60,143)` |
| Dead tree | `Rect2(837,32,56,155)`, `Rect2(901,56,51,131)` |
| Fern (green) | `Rect2(295,715,48,38)`, `Rect2(366,706,39,28)` |
| Fern, small | `Rect2(357,736,27,32)`, `Rect2(389,740,24,27)` |
| Grass tuft | `Rect2(6,643,20,22)` |
| Tall grass | `Rect2(742,704,17,32)`, `Rect2(678,706,17,30)`, `Rect2(710,710,16,26)` |
| Stump | `Rect2(600,409,37,34)`, `Rect2(707,417,29,23)`, `Rect2(788,422,26,21)` |
| Golden grass bush | `Rect2(2,673,27,29)` |

`rocks_with_shadows.png` is warm sandstone and clashes with the grey castle stone. It isn't used, see the open questions.

---

## R. Maren's room: a small manor bedroom

Files:
- `scenes/areas/prologue/maren_room.tscn` (rebuild);
- `tests/test_maren_room.gd`.

`scripts/areas/prologue/maren_room.gd` should need no change; `EDRIN_EXIT` stays `[(11,13), (10,13)]`.

### Size and shell
- `area_size` changes to **Vector2i(384,256)** (24x16 cells). `border` stays "black". `area_label` doesn't change.
- **Tiles:** 12x8 tiles, using the existing wall legend and walls.

  ```
  "1^^^^^^^^^^2"
  "LbbbbbbbbbbR"
  "LBBBBBBBBBBR"
  "L..........R" x4
  "3__________4"
  ```

  The floor stays `.` (inlay) unless the owner picks wood (see the open questions).
- **Walls** (all `StaticBody2D` rectangles):
  - North wall: y 0-96. Left shape x 0-224, right shape x 240-384. The gap at x 224-240 is the mirror.
  - `MirrorBlock` 16x96 at (232,48), as now.
  - West wall: x 0-32. East wall: x 352-384.
  - South wall: y 224-256.
- Walkable floor: cols 2-21, rows 6-13.

### Back wall (flat, z -1), left to right
1. **The window.**
   - Tracery window sprite `(96,993,32,48)` with its top-left at (56,36).
   - Red short valance `(32,288,64,25)` at (40,28). Red narrow banners `(7,269,18,36)` at (38,40) and `(231,269,18,36)` at (88,40), as drapes pulled to the sides.
   - Stone sill: a ColorRect band at x 50-94, y 82-88 (light grey with a darker 1 px underside). The crow sits on it at (72,84), and the carving point is (56,84). Both are unchanged.
2. **The candle table**, drawn against the wall foot.
   - Painted wood: top at x 108-196, y 74-80 (highlight row on top); apron at y 80-96 (darker); two leg stubs at the ends.
   - The candles stay at (120,80), (152,80) and (184,80), and their plaques sit on the apron, as now.
   - It adds no collision: the wall already blocks row 5.
3. **The mirror** at (232,80), with its cloth, as now. Add a thin carved frame (ColorRects) around the opening at x 220-244, y 40-96.
4. **The wardrobe.**
   - `StaticBody2D` "Wardrobe" at (272,112), shape 32x16 at (0,-8), which blocks cells (16,6) and (17,6).
   - Painted body 32 wide, from y 50 to 112: dark wood, two door panels, a cornice strip on top, and a small brass knob pair.
   - It goes in the y-sorted node. Maren never stands north of it.
5. **The nightstand.**
   - `StaticBody2D` "Nightstand" at (296,112), shape 16x16 at (0,-8), which blocks (18,6).
   - Painted body 16 wide, y 88-112. The candlestick `(43,81,8,15)` and the prayer paper ColorRect sit on top.
6. **The bed**, with its headboard against the wall.
   - `StaticBody2D` "Bed" at (320,144), shape 32x48 at (0,-24), which blocks (19-20, 6-8).
   - Painted: headboard y 84-100, pillow, blanket (deep red with a lighter fold line), a footboard edge at y 140-144.
7. **The chest** at the foot of the bed.
   - `StaticBody2D` "Chest" at (320,160), shape 32x16 at (0,-8), which blocks (19-20, 9).
   - Painted lid and iron bands.

### Floor and other furniture
- **Washstand** against the west wall:
  - `StaticBody2D` at (40,160), shape 16x16, which blocks (2,9).
  - Painted stand, with the bowl `(7,72,16,16)` on top.
- **Rug:** ColorRects at x 112-272, y 144-192 (border, field and inner border), as now but centred under the candle table.
- **Threshold:** a stone strip ColorRect at x 152-184, y 208-224, inside the door.
- **Door:** Area (168,216), id `door_locked_room`, and `DoorLeaf` as now.
- **Moonlight:** an additive `Polygon2D`, Color(0.55,0.6,0.9,0.07). It runs from the window bottom (56-88, 84) to a floor patch at about (60-120, 150-170).

### Interactables (only positions change)

| Node | Position | Stand cell, facing |
|---|---|---|
| Prayer (id `room_prayer`) | Area at (296,104), shape 12x12 | (18,7), up |
| SillCarving | (56,84), unchanged | (3,6), up |
| SaveCrow / Feather | (72,84), unchanged | (4,6), up |
| Candles Obey/Endure/Give | unchanged | (7,6), (9,6), (11,6), up |
| Mirror | (232,80), unchanged | (14,6), up. Passage cell (14,5). |
| Door | (168,216), unchanged | (10,12), down |

Edrin starts at (184,200), cell (11,12). Spawn `start` is at (168,200), cell (10,12), facing up. Both unchanged.

### Acceptance (R)
- Every story check in `test_maren_room.gd` passes, with these updates:
  - **R5b** expects (384,256);
  - the R15 **Prayer** target moves to (18,7) up.
- All floor cells not listed as furniture are reachable from the spawn.
- **Screenshots** (from the game window, not headless): the room at start; the room after the candles are solved (mirror open, feather on the sill); a close crop of the candle table. In them:
  - the furniture reads as a bed, wardrobe, nightstand, chest and washstand at a glance;
  - nothing overlaps the candle plaques;
  - Maren is never drawn behind a wall piece.

---

## G. The gate: a compact yard before a layered castle

Files:
- `scenes/areas/prologue/gate.tscn` (rebuild);
- `scripts/areas/prologue/gate.gd` (Edrin's route constant only).

### Size and shell
- `area_size` is **Vector2i(464,624)**: 29 cells wide (cols 0-28) and 39 cells tall (rows 0-38). Set `border` to "trees" and add a `TreeBorder` child (item T).
- Keep the dusk `CanvasModulate` Color(0.72,0.62,0.8).
- **Ground:**
  - grass `g` everywhere south of y 352;
  - cobble `c` forecourt across cols 5-23, rows 22-25;
  - cobble path cols 12-16 from row 26 to the bottom edge.
- **Collision:**
  - The whole castle front blocks rows 0-20 (one rectangle, x 0-464, y 0-336).
  - Row 21 is blocked except col 14, using two rectangles: x 0-224 and x 240-464, both y 336-352.

### The castle front (back to front)
All pieces come from `castle_outside.png`. Positions are sprite top-left corners in map pixels. Builders may nudge any piece by up to 8 px after looking at screenshots, but must not change the collision above.

1. **Cathedral silhouette:** the existing `Polygon2D` at z -2, moved so its spires show above the right wing (x about 300-460, y 0-110).
2. **Keep** `(823,196,178,328)` at (143,0), z -2. It's the tallest mass in the centre; its lower half is hidden by the front tiers.
3. **Wings, upper** `(0,291,176,172)`: left at (40,110); right flipped at (248,110). This gives parapets and a rampart walk at the top of each wing.
4. **Wings, lower** `(0,480,144,110)`: left at (64,242); right flipped at (256,242). This is the brick front wall with niches.
5. **Round red towers** `(2,832,60,202)`: at (0,150), and flipped at (404,150). They stand at the corners, with their feet on y 352.
6. **Slim towers** `(12,624,40,188)`: at (168,164) and (256,164), flanking the door, feet on y 352.
7. **Portal with steps** `(1449,427,46,105)` at (209,255). The doorway centre is x 232, and the steps spill 8 px onto the forecourt.
8. **Banners:** red narrow banner `(7,269,18,36)` from `castle_decoratives.png`, on each slim tower at (179,200) and (267,200).
9. **Torches:** `torch.png` with frame_loop at (200,300) and (264,300), each with an additive `light1a` glow.
10. **Shadows:**
    - a foot shadow ColorRect x 0-464, y 352-364, Color(0,0,0,0.22);
    - a darker 6 px band under each tower's base;
    - a 4 px shadow under each parapet line.

### Yard
- **Edrin** (Area id `edrin_arrival`): at (232,376), cell (14,23). In `gate.gd`, his route changes to `[Vector2i(14,22), Vector2i(14,21)]`.
- **Exit:** at (232,344), cell (14,21). Disabled until Edrin arrives; target `entrance_hall/start`. Behaviour unchanged.
- **Spawn** `start`: (232,600), cell (14,37), facing up.

| Interactable | Position | Stand cell, facing |
|---|---|---|
| Edrin | (232,376) | (14,24), up |
| BellPost (`gate_bellrope`) | body at (136,368), cell (8,23) | (8,24), up |
| LilyCup (`gate_lily`) | (152,536), cell (9,33) | (9,34), up |
| CathedralLook (`gate_cathedral`) | (376,344), inside the blocked row 21 | (23,22), up |

### Other yard pieces
- **Dead trees:** DeadTreeW `(837,32,56,155)` with its feet at (56,472); DeadTreeE `(901,56,51,131)` with its feet at (408,536). Each gets a 16x16 body and a few tufts and ferns at its foot.
- **Bottom edge:**
  - low wall stubs (post `(768,932,32,68)`) at x 168 and x 264, feet at 624;
  - the iron gate leaves swung open: `(960,841,31,55)` with its feet at (184,624) and `(993,841,31,55)` at (249,624), each with a body that blocks cells (11,38) and (17,38);
  - the path between them stays open.

### Acceptance (G)
- The story runs unchanged. Edrin's talk, the arrival flag and the walk-in to the hall all work, and every gate check in `test_prologue_gate_hall.gd` and `test_maren_room.gd` passes with the cells above.
- Column 14 is walkable from row 37 up to row 22.
- **Screenshots** (from the game window): the castle front with Maren at (14,24); the bottom of the yard with Maren on the spawn. In them:
  - no tree, gate leaf or wall stub covers Maren on the spawn;
  - the castle reads as several depths (keep behind, wings, towers in front), not a flat picture;
  - there are no visible seams between the wing halves.

---

## H. The entrance hall: one long, deliberate hallway

Files:
- `scenes/areas/prologue/entrance_hall.tscn` (rebuild);
- `scripts/areas/prologue/entrance_hall.gd` (route constants).

### Size and shell
- `area_size` is **Vector2i(576,256)**: 36x16 cells, 18x8 tiles. `border` is "black". Keep the chill `CanvasModulate` Color(0.62,0.6,0.78).
- **Layout:**
  - North wall, 3 tiles of face: ceiling edge y 0-32, wall face y 32-128.
  - Corridor floor: y 128-192, rows 8-11 (4 cells wide).
  - Entry nook below the left end: x 32-96, y 192-224, rows 12-13, cols 2-5. The front door is on its bottom edge at row 14.
  - Everything else is black void.
- **Tiles:**

  ```
  "1^^^^^^^^^^^^^^^^2"
  "LbbbbbbbbbbbbbbbbR"
  "LbbbbbbbbbbbbbbbbR"
  "LBBBBBBBBBBBBBBBBR"
  "L................R" x2
  "L..<south edge from col 3 on>"
  "<nook bottom edge, cols 1-2>"
  ```

  The builder picks the corner and edge letters from the existing legend by screenshot. The aim is a clean wall top along the south side of the corridor and around the nook.
- **Collision:**
  - North wall: x 0-496 and x 528-576, both y 0-128.
  - Stair block: x 496-528, y 0-112.
  - West wall: x 0-32. East wall: x 544-576.
  - South wall: x 96-576, y 192-256.
  - Nook bottom: x 32-96, y 224-256.
- Walkable:
  - corridor cols 2-33, rows 8-11;
  - nook cols 2-5, rows 12-13;
  - the stair cells (31,7) and (32,7).

### North wall rhythm (flat pieces, z -1)
- **Wall pillars:** the pillar set into the wall, `(384,128,32,142)`, with its top at y 0, at x 96, 192, 288 and 384. That makes a steady rhythm: a 32 px pillar, then a 64 px bay. Each pillar's base overhangs the floor by 14 px. That overhang is drawn on the floor, with no collision.
- **Bays**, from left to right:
  1. **Bay 1** (x 32-96): coat hooks. Rail, two hooks and a hanging coat as ColorRects, at about x 44-84, y 70-104.
  2. **Bay 2** (x 128-192): closed side door `(496,975,32,49)` at (144,79), in its arched frame. Decorative and locked, with no new dialogue.
  3. **Bay 3** (x 224-288): tracery window `(96,993,32,48)` at (240,40), with the red short valance `(32,288,64,25)` at (224,34). An additive dusk shaft, Color(0.85,0.55,0.6,0.1), slants down onto the floor.
  4. **Bay 4** (x 320-384): the hymn board, a dark board with pale "number" strips (ColorRects), at x 328-360, y 58-104.
  5. **Bay 5** (x 416-480): a second tracery window `(144,993,32,48)` at (432,40), with valance `(160,288,64,25)` at (416,34), and a shaft.
  6. **End** (x 480-544): the stair in its brick alcove, `(512,896,64,64)`, at (480,64).
- **Torches:** `torch.png` on the face of the pillars at x 96 and 288 (at about y 52), each with an additive `light1a` glow in the existing Glows node (z 1). The pillars at x 192 and 384 get no torch, so the light alternates.
- **Runner:**
  - crimson Color(0.3,0.09,0.11) along the corridor, x 40-536, y 144-176 (rows 9-10), with gold trims Color(0.55,0.42,0.2);
  - a short leg down into the nook at x 48-80, y 176-224.

### People, doors and interactables

| Thing | Position | Cell / use |
|---|---|---|
| Spawn `start` | (72,216) | cell (4,13), facing up |
| FrontDoor (`door_locked`) | Area (72,232) | used from (4,13) facing down |
| Hooks (`hall_hooks`) | Area (72,120) | used from (4,8) facing up |
| HymnBoard (`hall_hymnboard`) | Area (344,120) | used from (21,8) facing up |
| RoomExit (exit.gd, target `maren_room/start`) | (512,120), shape 32x8 | cells (31,7) and (32,7) |
| Edrin start | (72,184) | cell (4,11) |
| Edrin end | | cell (30,8), facing left toward Maren |

**Edrin's route** (`entrance_hall.gd`) runs (4,11) → (4,9) → (30,9) → (30,8), which is 29 steps.
- Replace `WALK_FROM_ROW`, `DOOR_ROW` and `COL` with clearly named constants for this route.
- `_place_edrin_at_door` places him at (30,8).
- Maren stays frozen during the walk, and the room exit is enabled after it, as now.

### Acceptance (H)
- Edrin walks the whole hall, and the hooks, hymn board, front door and room exit all work.
- Every hall check in the tests passes with the cells above.
- No pillar body stands on the floor. The only bodies are the wall rectangles above.
- **Screenshots** (from the game window): the hall at arrival, with Edrin at the nook; mid-walk; Maren at (31,8) below the stair. In them:
  - the pillars sit in the wall;
  - both window beams land on the runner;
  - the torches flicker (take two captures 10 frames apart);
  - the hall reads as one long corridor with black around it.

---

## T. The forest ring: variety and undergrowth

**Recommendation: yes, upgrade it.** A single pine shape repeated on a grid is the main thing that makes the outdoor border look generated rather than intended.

File: `scripts/world/tree_border.gd` (plus the test changes below).

### Tree mix
- Use the dark-row regions, in this order:
  1. pine large;
  2. pine medium (the corrected rect);
  3. pine small;
  4. oak medium;
  5. birch tall;
  6. birch medium;
  7. oak small;
  8. dead tree (837,…).
- Weights: [24,22,14,10,8,7,8,7]. Pines (indexes 0-2) make up 60%, so test F6's "mostly pines" still holds.

### Clumping
- Keep the jittered grid, but bias each tree toward one of a few clump centres per side.
- Leave a small gap now and then, but never one wide enough to show the backing through the full depth.
- Same seed, same result.
- Only flip trees, never scale them, so pixel art stays crisp.

### Undergrowth
- Add a new exported `undergrowth` list (regions) with weights: ferns, small ferns, grass tuft, tall grass, golden bush and stumps, from the table above.
- Place them along the inner fringe band, from 2 to 30 px outside the map edge, on every side, at about one per 18 px of edge.
- They go in a child `Node2D` named "Undergrowth" (y-sorted), so the existing count of tree sprites stays exact.
- Add `undergrowth_layout()`, which works like `layout()`.

### South edge rule
- A tree below the map may reach at most 24 px into the map, so canopies never hide Maren on the bottom rows.
- Trees on the south side are pushed down until their top is at or below `size.y - 24`.

### Keep
- `backing`, which still has 4 rects;
- the existing exports;
- `@tool`, so the forest shows in the editor.

### Acceptance (T)
- F6 passes unchanged, apart from the comment.
- New check F7 passes.
- A screenshot of the gate (Maren on the spawn and at the bell post) shows mixed trees in clumps, a fern and tuft fringe, and nothing hiding Maren.

---

## Tests to add or adjust

- **`tests/test_maren_room.gd`**
  - Gate talk stays at (14,24).
  - Hall: `P.place_at` changes from (28,7) to **(31,8)**, walking up.
  - R5b expects (384,256).
  - Prayer target moves to (18,7) up.
  - Everything else is unchanged.
- **`tests/test_prologue_gate_hall.gd`**: update the cells.
  - F2: spawn (14,37).
  - Edrin talk from (14,24); Edrin's gate route ends (14,21).
  - F15: Edrin's hall end is (30,8).
  - Front door from (4,13), facing down.
  - Hooks from (4,8), up. Hymn board from (21,8), up.
  - F21: lily from (9,34), bell from (8,24), cathedral from (23,22), all facing up.
- **`tests/test_area_framing.gd`**
  - F6 stays as is.
  - Add **F7**:
    - `undergrowth_layout()` isn't empty and is the same for the same seed;
    - no undergrowth feet inside the map;
    - no tree sprite whose feet are below the map reaches more than 24 px into it (`feet.y - region.h >= size.y - 24`).
- **New `tests/test_area_layouts.gd`**, replacing `tests/test_castle_art.gd`. Delete the old file; its checks describe the 640x640 gate and the old hall. For each of the three areas:
  - `area_size` and `border` are as specified.
  - **Walkability:** every cell listed as walkable is free, and the listed blocked cells are blocked:
    - gate rows 0-20, and row 21 except col 14;
    - hall row 7 except cols 31-32;
    - the room furniture cells.
  - A flood fill from the spawn reaches every interact stand cell.
  - Every `Sprite2D` region in the scene fits inside its texture.
  - The hall has at least 2 animated torches, and the gate has 2.
  - In the hall, no `StaticBody2D` other than the wall bodies has its origin inside rows 8-13. This is the "no free-standing pillars" check.
  - The gate has a `TreeBorder` child; the room and the hall have none.
- Other tests (save_system, save_menu, save_crow, chaser) don't touch these cells. Run them anyway at the end.

## Screenshots: how every builder checks their work

Headless runs use a dummy renderer and capture nothing. Each builder writes a small capture script in their scratchpad and runs Godot **windowed**.

1. **The script** (`extends SceneTree`):
   - loads `res://scenes/main.tscn`;
   - waits 2 frames;
   - sets any flags it needs through `GameState`;
   - calls `main.enter_directly(area, "start")`;
   - optionally calls `player.place_at(NavGrid.center_of(cell))`;
   - waits about 30 frames;
   - runs `root.get_viewport().get_texture().get_image().save_png(<scratchpad>/<name>.png)`;
   - quits.
2. **Run it:** `<exe> --path . --script <absolute path to capture script>` (no `--headless`).
3. **Look at the PNG** with the Read tool, judge it against the acceptance list for that item, fix, and capture again.
4. **Report:** the final screenshot paths go in the builder's report. They aren't committed.

## Work order

At most two Sonnet builders run at a time, and no two builders ever touch the same file.

| Wave | Builder | Item | Files (exclusive) |
|---|---|---|---|
| 1 | A | T forest ring | `scripts/world/tree_border.gd`, `tests/test_area_framing.gd` |
| 1 | B | R bedroom | `scenes/areas/prologue/maren_room.tscn`, `tests/test_maren_room.gd` (all the edits listed above, including the hall cell (31,8)) |
| 2 | C | G gate | `scenes/areas/prologue/gate.tscn`, `scripts/areas/prologue/gate.gd` |
| 2 | D | H hall | `scenes/areas/prologue/entrance_hall.tscn`, `scripts/areas/prologue/entrance_hall.gd` |
| 3 | E | Tests and final pass | `tests/test_prologue_gate_hall.gd`, new `tests/test_area_layouts.gd`, delete `tests/test_castle_art.gd`; runs every test and takes the final screenshots of all three areas |

- **Why this order:** G needs the upgraded forest (wave 1). `test_maren_room` can only pass end to end once G and H are in (wave 2). In wave 1, builder B checks the room on its own by entering it directly and running the room-only part through a capture script.
- **Every builder** finishes with the tests that touch their files and the screenshots named in their acceptance list.

## Open questions (with the default we'll use if there's no answer)

1. **Furniture art:** the art packs have no bed, wardrobe or chest sprites. *Default:* paint them from simple shapes in a three-tone wood palette, styled to match the pack. They can be swapped for drawn art later.
2. **Bedroom floor:** stone inlay, as now, or the pack's wood planks? *Default:* wood planks, which are warmer and more bedroom-like. Builder B shows both in screenshots and keeps planks unless they clash.
3. **Room width:** 384 instead of 320, so the furniture fits. *Default:* yes.
4. **Hall length:** 576, which fits the screen without scrolling. A longer hall would need sideways scrolling. *Default:* 576.
5. **Side door in the hall:** decorative only, or examinable with a new line of text? *Default:* decorative, with no new dialogue.
6. **Rocks:** the rock sheet is warm sandstone and clashes with the grey castle. *Default:* no rocks; use stumps, ferns and grass instead.
7. **Tree colour:** the dark green set or the lighter, yellower set? *Default:* dark, which suits dusk.
8. **Castle door style:** the gothic doorway with steps or the taller gabled portal? *Default:* the doorway with steps. It's lower, so the keep behind it shows.
9. **Open iron gate at the bottom of the yard:** *Default:* include it, to show where Maren came in.
10. **Cliffs, water or a road beyond the yard:** *Default:* not now, deferred.
