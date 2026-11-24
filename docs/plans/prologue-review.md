# Review: prologue and save-point crow

Reviewed against [prologue-and-save-crow.md](prologue-and-save-crow.md). Owner decisions applied: candle puzzle, end card then title, locked-door custom kept, carving left ambiguous, other defaults as planned.

## Verdict

**Ready for the owner to play.** Every planned piece is built. All 9 test files pass, and the headless smoke run is clean. There are no blocking bugs. Two story-polish issues are worth fixing before anyone else sees it (S1, S2 below). Nobody has seen it on screen yet, so the checklist at the end matters more than the tests.

## Test run (2026-11-24)

| Test file | Result |
|---|---|
| test_chaser_pathing | pass |
| test_dialogue_choices | pass |
| test_game_state | pass |
| test_maren_room (R1 to R38: the whole prologue from New Game to the end card and back to title, including save and load) | pass (harmless "resources still in use at exit" note) |
| test_player_grid | pass |
| test_prologue_gate_hall | pass |
| test_save_crow | pass |
| test_save_menu | pass |
| test_save_system | pass |
| Headless smoke run | clean, exit 0 |

All tests use their own throwaway save folders, so they never touch the player's real saves. One extra check I ran by hand also passed: saving twice into the same file on Windows overwrites it correctly.

## Plan items

| Item | Status |
|---|---|
| W1 Story memory | Done |
| W2 Dialogue choices | Done |
| W3 Save files | Done (static, 20 slots, crash-safe write, damaged files shown as unreadable) |
| W4 Dialogue lines | Done (all ids present) |
| W5 Save menu | Done |
| W6 Persistent "already talked" | Done |
| W7 Game flow in Main | Done |
| W8 Save crow | Done. Its files ended up in `scenes/world/` and `scripts/world/`, not `save/`. That's fine. |
| W9 Title screen | Done |
| W10 Gate and hall | Done |
| W11 Maren's room and the candle puzzle | Done |
| W12 Flow test and docs | Done. The flow test is `test_maren_room.gd` rather than `test_prologue_flow.gd`. GLOSSARY has "Save crow", and the save format is in `docs/save-system.md`. |

**Owner requirement: the crow appears the moment Maren is alone.** Met. Edrin finishes walking out, disappears, and in the same instant the crow starts fading in on the sill (`scripts/areas/prologue/maren_room.gd:72-76`). It can be talked to within a second, which test R13 checks.

**Story rules.** Met.
- Caldris is never named anywhere in game text, and the word "demon" does not appear.
- Nothing warns about saving. The crow offers "Shall I keep this one?" and the menu title reads "Keep this moment".
- There is no quest log and no objective text.
- The only instructions on screen are the save menu's key hints ("Up/Down: move, Interact: choose, Esc: back").

## Defects, ranked

### Story or feel (fix soon)

- **S1. "The key turns" plays while Edrin is still in the room.** The goodnight conversation ends with "The key turns. He waits a moment on the other side before he goes." Only after that line does Edrin walk two tiles to the door and vanish (`data/dialogue.json:59`, `scripts/areas/prologue/maren_room.gd:65-72`). Fix: move that last narration line so it plays after he has left, just before the crow appears.
- **S2. The crow's first line describes an arrival the player already watched.** "Something taps at the glass. Then it is on the sill..." (`data/dialogue.json:62`) only plays when the player talks to the crow. By then it has been visibly sitting there. This flaw comes from my plan, not the builders. Fix: either play that line automatically as the crow fades in, or reword it (for example "It has been watching you since the key turned.").
- **S3. Edrin pops out of existence at the door instead of fading.** `maren_room.gd:39-41` hides him instantly. Fix: a half-second fade, as the old test room does.

### Robustness (low; needs an odd situation)

- **R1. A hand-edited or half-valid save file can freeze the game on Continue.** A file that has the right version but a broken position (`"cell": [1]`) is listed as a normal, loadable save (`scripts/core/save_system.gd:84-86`). Loading it then fails partway through: the title is already closed and Main stays marked "busy", leaving a black screen (`scripts/main.gd:88-93`). Normal play cannot produce such a file. Fix: check the shape of the data (area, cell with 2 numbers, a state dictionary) in `_read`, and mark the file unreadable otherwise.
- **R2. A failed save is silent.** If writing the file fails (disk full, permissions), the crow says nothing and the player may believe it saved (`scripts/world/save_crow.gd:104-105`). Fix: play `crow_declined` or a dedicated line.
- **R3. Loading has no fade.** It cuts straight from the title to the room (`scripts/main.gd:95`). This is cosmetic. Fix: fade like New Game does.
- **R4. Continue lights up even when every save is unreadable.** That is by design, so damaged files can be seen and overwritten. The menu then has nothing to pick, but Esc backs out, so it is not a softlock (`scripts/core/save_system.gd:63-68`).

### Housekeeping

- **H1. Eight script `.uid` files were missing.** They are now generated (by my import run) and must be committed alongside the scripts. The new ones are `scripts/areas/prologue/{gate,entrance_hall,maren_room}.gd.uid`, `scripts/characters/npc_walker.gd.uid`, `scripts/puzzles/{candle,candle_row}.gd.uid` and `tests/{test_maren_room,test_prologue_gate_hall}.gd.uid`.
- **H2. Leftovers to tidy.**
  - `crow_room_repeat` in `data/dialogue.json:69` is unused; it duplicates `crow_room_repeat_1`.
  - `save_crow.gd:80` sends an odd "talked" signal with the id `crow_declined`.
  - `scenes/areas/prologue/entrance_hall.tscn:197-198` is missing a blank line between two nodes. Godot reads it fine.
- **H3. The old test room still has its own Edrin and crow intro.** These are `scenes/areas/manor_room.tscn` and `edrin_first` / `crow_first`. They only matter for developer testing, but they repeat the prologue's beats and differ in wording.

### Checked and fine

- **Candles mid-puzzle.** They are deliberately not saved; loading puts them back to dark, which is fair and tested.
- **Crow line cycling.** It survives save and load. Numbers from the save file are converted back properly.
- **Position after loading.** Numbers that come back from the save file as decimals are converted properly.
- **Loading mid-cutscene.** This cannot happen. The only save point is the crow, which only exists after Edrin has left the room. A load also never replays the goodnight scene (R34).
- **Edrin's state.** It is driven by flags in all three areas and restored on load.
- **Hall front door.** It is locked ("The door is shut fast."), and there is no way back to the gate, as planned. Maren's room door is locked too. The prologue is one-way by design.
- **Frozen player.** Every cutscene (gate walk, hall walk, goodnight, crow talk, end card) unfreezes Maren at its end, and each one checks it is still running before continuing. No stuck states were found.

## What the owner should check by eye

1. **Title screen.** Does "Lychkin" plus three options look acceptable as a placeholder? Continue is greyed out on a fresh install.
2. **Gate.**
   - Does the dusk tint read as dusk, and is the cathedral shape legible?
   - Can you find the lily, bell rope and cathedral without help?
   - Does Edrin's lamp read as a lamp?
3. **Gate to hall.** After Edrin's last line he steps once toward the door and the screen fades. Does that feel like being led in, or abrupt?
4. **Hall walk.**
   - Edrin walks the full length of the hall while Maren can't move. Is the length bearable, or too long?
   - Does the child's coat stand out on the hooks?
5. **Goodnight scene.**
   - Watch for S1: the key turns before he leaves.
   - Edrin vanishes at the door (S3).
   - Does the crow fading in on the sill feel like "the moment she is alone"?
6. **The crow.**
   - Is the placeholder black shape readable as a bird at game size?
   - Does the gentle bob look alive or odd?
   - Read the first conversation for S2.
7. **The save menu.**
   - Is the text readable at 640x360?
   - Does "Keep this moment" as a header feel right?
   - Do the rows fit on one line ("File 01  Hollowmere, Maren's room  0:04:12  2026-11-24 21:03")? Long area names may crowd the row.
8. **Candles.**
   - Are the OBEY / ENDURE / GIVE labels readable?
   - Is it clear that reading a plaque also lights the candle?
   - Do the flames visibly lean toward the door on a wrong order?
9. **The mirror opening.** Is the dark opening visible, and does walking into it feel natural?
10. **End card.** "End of the prologue" holds for 3 seconds, then the title returns. Does Continue now offer your save?
11. **Timing.** Does a first, unhurried run take roughly 10 minutes? The planned budget was 3 + 2 + 2 + 3-4.
