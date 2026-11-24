# Review: compact areas, revision 2 (gate, hall, Maren's room)

Reviewer pass over the finished build against `docs/plans/compact-areas.md`. No game code was changed.

## Verdict

**Good to keep, with one real problem to fix.** All 11 test files pass. The story runs unchanged from the gate to the end card. The hall and the bedroom now look like real, intentional places in the RPG Maker style: a black void around them, pillars set into the wall, light that comes from windows. The forest ring is mixed and clumped, and nothing hides Maren.

The real problem is at the gate. The player never sees the top of the castle: the keep, the parapets, the back wings and the cathedral. Maren can't walk close enough for the camera to show it. The "look at the cathedral" line also describes a building that isn't on screen.

## Tests (all run headless, 180 s timeout each)

| Test | Result |
|---|---|
| test_area_framing | pass |
| test_area_layouts | pass |
| test_chaser_pathing | pass |
| test_dialogue_choices | pass |
| test_game_state | pass |
| test_maren_room (whole prologue, end to end) | pass |
| test_player_grid | pass |
| test_prologue_gate_hall | pass |
| test_save_crow | pass |
| test_save_menu | pass |
| test_save_system | pass |

The warnings in the output are expected, because the tests trigger them on purpose (for example "saved cell blocked, moved"). The "leaked at exit" lines are harmless.

## Defects, most important first

1. **Medium. The top of the castle and the cathedral are never on screen in play.**
   - Where: `scenes/areas/prologue/gate.tscn:94-147` (the cathedral, back wings and keep are drawn at y 0-150); camera in `scripts/main.gd:216-233`.
   - Why: the highest Maren can stand is row 22, and the camera follows her. So the top of the screen never goes above about y 170.
   - Result: in every in-game capture (`gate_door.png`, `gate_bell.png`, `gate_spawn.png`) the castle starts at the tower roofs. Only `gate_whole.png`, a zoomed-out tool view, shows the keep and the spires.
   - The cathedral examine line ("Beyond the wall, the cathedral ... It looks closer than it should", `data/dialogue.json:42`) points at nothing the player can see.
   - Fix options:
     - make the map shorter at the top, so the castle sits lower (move every castle piece down by about 160 px and remove that strip);
     - or let the camera look higher at the gate;
     - or move the cathedral silhouette down beside a corner tower, where it shows.
2. **Medium-low. The hymn board's art contradicts its text.**
   - Where: `entrance_hall.tscn:468-514`.
   - The board shows six pale number plates still hanging on it. The text (`data/dialogue.json:52`) says the numbers "have been taken down and stacked face-down beneath it".
   - Fix: an empty board with a small stack of plates on the ledge or the floor. That art would also tell the story.
3. **Low. The corner wall tiles draw "+" crosses in the room and the hall.**
   - Where: `maren_room.tscn:67-68`, `entrance_hall.tscn:61-62`.
   - The grey edge lines run past each other at the corners and out into the black, around the room and around the hall's nook. The rooms read a little like a drawn grid instead of a clean wall top.
   - Fix: pick the correct outer-corner pieces from the legend, checking by screenshot.
4. **Low. The covered mirror reads as a grey door or panel.**
   - Where: `maren_room.tscn:950-956` and `320-334`.
   - The cloth is 32 px wide and covers the new carved frame's sides (the frame runs x 216-248, the same as the cloth), so only the top and bottom of the frame show.
   - Fix: narrow the cloth to the opening (24 px), and give it a draped top edge or a sag so it reads as cloth over something.
5. **Low. Placeholder props made of plain rectangles.**
   - The hall's hooks and coats (`entrance_hall.tscn:369-431`) are two flat coloured bars on a rail. They read as "hanging things", but they're the flattest objects in the hall.
   - The gate's lily cup (`gate.tscn:434-493`) reads as a white square on a grey box, not a lily.
   - The bell post (`gate.tscn:509-552`) is a stick with a tiny box.
   - None of this breaks anything; it's the next art pass.
6. **Low. The washstand bowl floats a few pixels above the stand.**
   - Where: `maren_room.tscn:906-911`, bowl at y -34. The sprite has empty rows at its bottom.
   - Fix: lower it by about 3 px.
7. **Low. The candle plaques merge into one black bar.**
   - Where: the three `Plaque` nodes, `maren_room.tscn:1027-1154`.
   - Each plaque is 30 px wide on a 32 px spacing, and together they hide the table's front. In the close crop, OBEY / ENDURE / GIVE read as one sign, with "ENDURE" touching its neighbours.
   - Fix: make the plaques narrower (about 24 px) so the wood shows between them.
8. **Low. Three script `.uid` files are missing:** `scripts/world/tree_border.gd`, `tests/test_area_framing.gd`, `tests/test_area_layouts.gd`. The project rule is that they're committed. Opening the project in the editor once creates them.
9. **Low. The README credit makes an unverified claim.**
   - It says RPGFW Set 1 is by "the same artist as the castle pack, Szadi art".
   - The pack's `license.txt` names no artist, so the credit should come from the store page.
   - The character sprite pack (Memao) also has no credit line yet.
10. **Low. The new layout test is thinner than the plan asked.**
    - Where: `tests/test_area_layouts.gd:158` and `174`.
    - At the gate it only checks column 14, and in the hall only row 9 and the nook, for walkable cells.
    - In practice it's covered elsewhere: the room has a full reachability check (R5d), and nothing is walled in.
11. **Low. The stair sprite is a different picture from the one planned.**
    - Where: `entrance_hall.tscn:235-240`.
    - The hall uses the plain "stone stair between rails", not the planned "stair in a brick alcove". It looks fine, just darker. Owner's call.

## Checked and fine

- **Story beats** are unaffected (proven end to end by test_maren_room):
  - Edrin's gate talk, his walk up the steps and the walk-in to the hall;
  - his walk down the whole hall (29 steps) with Maren held still;
  - the hooks, the hymn board and the front door;
  - the goodnight, then the key, then the crow on the sill the moment Maren is alone;
  - the candles, the mirror opening, the passage and the end card.
- **Saves and loads into the smaller rooms:**
  - Saving only happens at the crow in Maren's room, and the crow hasn't moved, so old saves land on a real floor cell.
  - A cell from an old bigger map that is now off the map or inside a wall moves to the nearest free cell within 3 steps; failing that, Maren starts at the room's entrance. The tests cover this, including a cell at (99,99).
  - The fix happens under the black fade, so the player never sees the jump.
- **Camera:**
  - Maps smaller than the screen sit centred and don't scroll.
  - The gate is centred left to right, and the forest covers the 88 px of margin on each side.
  - Fades cover every area change, and leaving the forest-ringed gate for the black hall is clean.
- **Dialogue box on small maps:** it covers the bottom 96 px of the screen.
  - Room: Maren and Edrin stand just above it during the goodnight scene.
  - Hall: at the front door the box covers Maren's feet (cosmetic).
- **Walking off the map:** every edge is walled.
  - At the gate: castle, sides, bottom, and gate posts.
  - Hall and room: all four walls, the stair block and the nook bottom.
  - Maren can't step into the void.
- **Things drawn over Maren:**
  - Trees and undergrowth always draw behind her, and canopies below the map reach at most 24 px in.
  - The gate leaves don't touch the spawn.
  - The only things drawn above her are the faint moonlight in the room and the torch glows on the hall wall. The glows never reach her row, and the moonlight is a soft tint, which is intended.
  - Eye-check: standing just left of the bed or chest, her right shoulder may be clipped by a few pixels.
- **Torches:**
  - Hall: on the pillars at x 96 and 288, and they flicker.
  - Gate: beside the doorway. They overlap the inner edge of the slim towers slightly, which reads as mounted on the towers.
- **Leftover files:** no stray capture scripts or images in the project. The `asset refereces/` folder (about 7 MB of reference pictures, name misspelled) is untracked; decide whether it belongs in the repo.

## What the owner should look at by eye

1. **Play the gate and walk to the door.** You'll see only the lower half of the castle, and no cathedral. Then pick a fix from defect 1.
2. **Hall:** look at the hymn board, which still shows its numbers, and at the coat hooks. Watch the corners of the hall and its nook for the "+" crosses.
3. **Maren's room:**
   - Does the covered mirror read as a mirror?
   - Do the plaques read as three plaques on a table?
   - Does the washstand bowl sit on the stand?
   - Walk Maren beside the bed and the chest.
4. **Gate yard:** decide whether the lily cup and the bell post need real art now or later.
