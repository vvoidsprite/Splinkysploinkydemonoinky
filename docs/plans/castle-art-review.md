# Castle art pass: review

This review compares the build with `docs/plans/castle-art-pass.md`. No game code was changed.

## Verdict

**The gate is ready to play. The hall needs one small fix-up before it looks right.**

All 10 test files pass, and every story beat, exit and talk spot still works. The gate reads like the owner's reference picture: a symmetric keep, red trim, two red-framed gothic windows, an arched door with steps, door torches, battlemented wings and red-roofed corner towers on a cobbled forecourt.

The hall has its floor pattern, stair, windows, drapes and lights. But its pillars are placed so close together that each row looks like one endless pole rather than a colonnade. That undercuts the "grand hall" goal.

### Test run

Each file was run headless with `--fixed-fps 60` and a 240 s timeout. There were 0 failures.

| Test file | Checks passed |
|---|---|
| test_castle_art (new) | 31 |
| test_prologue_gate_hall | 28 |
| test_maren_room | 39 |
| test_save_crow | 25 |
| test_save_system | 27 |
| test_player_grid | 21 |
| test_chaser_pathing | 18 |
| test_save_menu | 16 |
| test_game_state | 9 |
| test_dialogue_choices | 7 |

`test_maren_room` prints a harmless "2 resources still in use at exit" warning. This was already there before this pass.

## Defects, most important first

1. **Hall pillars merge into poles and poke through the ceiling.** Medium. `scenes/areas/prologue/entrance_hall.tscn:212-348`.
   - Each pillar is 155 px tall, but the pillars in a row are only 80 px apart, so each pillar overlaps the next. Down each side of the runner you see one continuous column from the ceiling to row 20.
   - The front pair's tops (feet y=176) reach y=21, past the wall top (y=32) and into the dark ceiling border.
   - The pillars at x 222-242 and 414-434 also stand partly over the windows at x 200 and x 424.
   - **Fix (default):**
     - Use the short fluted pillar `Rect2(166, 628, 20, 91)`, offset (-10,-91), with the drape offset at (-9,-75).
     - Move the pillars to **columns 15 and 25** (x 248 / 408) and **rows 11, 17 and 23** (feet y 192 / 288 / 384). This leaves no overlap, keeps everything below the wall top, and clears the windows and torches.
     - Update test B2 to cells (15,11), (25,11), (15,17), (25,17), (15,23) and (25,23).
   - **Alternative:** keep the tall pillars, but only two pairs, at rows 13 and 23 in columns 15/25.
2. **Stray stone posts floating above the keep.** Low-medium. `scenes/areas/prologue/gate.tscn:127-133`.
   - The keep's cut starts at sheet x 823 and ends at 1001. That catches slivers of two loose battlement posts that sit beside the keep on the art sheet.
   - They show as two detached posts in the sky at about x 231-240 and x 400-409, y 8-34.
   - **Fix:** split the keep into two pieces:
     - `KeepTop`: `Rect2(833, 196, 160, 28)` at top-left (241,8);
     - `KeepBody`: `Rect2(823, 224, 178, 300)` at top-left (231,36).
   - The image is otherwise identical.
3. **The last light shaft is a thin sliver.** Low. `entrance_hall.tscn:105-108`.
   - The shafts all lean right. The one under the east window at x=568 runs into the wall, so it is clipped to an 8 px strip.
   - **Fix:** mirror the two east shafts so they lean left, for a symmetric hall:
     - `Shaft424` = (424,88), (456,88), (416,220), (368,220);
     - `Shaft568` = (568,88), (600,88), (560,220), (512,220).
4. **Missing `tests/test_castle_art.gd.uid`.** Low. All other scripts have one, and the project rule (docs/godot.md:8) is that `.uid` files are committed. Open the project in the editor, or run any import, to generate it, then commit it.
5. **The new test can't notice Edrin blocking the path.** Low. `tests/test_castle_art.gd:82,110`.
   - Both walk-path checks ignore Edrin's collider on *every* cell, not just his own. If his collider ever grew into the cell in front of him, the test would still pass.
   - I checked the layout directly: his block covers only his own cell. At the gate that is (20,22); in the hall it is (20,24), so hall cell **(20,23) is free**.
   - **Fix:** ignore his collider only for his own cell.
6. **The red cloth over the stair pokes 2 px into the ceiling border.** Trivial. `entrance_hall.tscn:120`. Set its y to 32.

## Checked and fine

- **Gate:**
  - every gameplay position moved down by 14 rows, exactly as planned;
  - `gate.gd:38` now walks Edrin to (20,21), and the Exit is in row 21;
  - the wall blocks rows 0-20, and nothing is walkable inside the building;
  - the cobble path and forecourt are in place;
  - the cathedral spires sit behind the east wing.
- **Draw order:**
  - the gate facade, torches and foot shadow all sit in one layer that never draws over Maren;
  - the hall's windows, stair and light shafts sit under the characters;
  - the pillars, fire bowls and candelabras sort correctly in front of or behind Maren;
  - the front-door leaf can't cover her at the spawn spot.
- **FillW/FillE** (the 8 px wall strips beside the keep): in my mock-up they close the gap between the wings and the keep's narrower upper storeys without a visible seam. Worth one look in the running game.
- **Performance:** 10 small additive glows and 4 shafts are negligible at this scale and won't affect frame rate.
- **Glows layer** (hall, drawn above characters): the warm light brightens Maren slightly when she passes a fire bowl. That reads as lighting. Check it isn't too strong.
- **README credit** is present (README.md:9).
- **No leftover scratch files** were found in the repo.

## For the owner to check by eye

1. **Gate, at the start:** is the castle front close to the reference? Note the grass above the battlements: there is no sky, because the scene is seen from above. Are the door torches large enough to notice?
2. **Gate, walking up:** does the keep reveal nicely? Are there two floating posts at the keep's top corners (defect 2)?
3. **Hall, during Edrin's walk:** do the pillars read as poles (defect 1)? Do the light shafts and warm pools give the cold-grand-hall feel? Is the hall too dark?
4. **Hall, east window:** is the clipped light shaft visible (defect 3)?
