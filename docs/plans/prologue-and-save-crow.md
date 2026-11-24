# Plan: Prologue and the save-point crow

Status: proposed, waiting on the owner's answers to the open questions (defaults below are used if no answer).

## (a) What the player experiences

**Title.** A plain title screen: New Game, Continue, Quit. Continue opens the list of 20 save files (greyed out when there are none).

**1. The gate (about 3 min).** Dusk. Maren walks up a short path to Hollowmere Manor. A few things can be looked at: a withered Order lily by the gate, the cathedral's dark shape beyond the wall, a bell rope that has been cut. Nobody tells her where to go. Edrin waits at the door with a lamp. He is warm, a little nervous, and too formal. He takes her inside.

**2. The entrance hall (about 2 min).** Edrin walks ahead and she follows. A couple of details: a row of coat hooks where one small, very clean child's coat still hangs (on a second playthrough: hers), a hymn board with the numbers taken down. Edrin shows her to her room.

**3. Maren's room, alone (about 1 to 2 min).** Edrin says goodnight, then quietly explains that by custom the door is locked on the first night, and that he is sorry. Maren says she remembers the custom. He leaves, and the key turns. **The moment she is alone, a crow is on the sill, inside a closed window.** It talks to her as if it has always known her. It offers to "keep this moment" for her: that is the save. No menu tutorial, no "remember to save" text.

**4. The tutorial puzzle (about 3 to 4 min).** The door stays locked. Three wall candles sit under three carved words. The Order prayer pinned above the writing table names them in one order. Lighting them that way makes the flames lean toward the door and die (gentle failure, candles reset). Small letters cut into the windowsill at a child's eye height give the old reading, in reverse. Lighting them that way loosens the nails on the covered mirror: behind it is a low servants' passage. This teaches: look at everything, inscriptions have two readings, failing costs nothing. It is also Maren's first small act of defiance (leaving a room she was locked into), which the Good Ending's epilogue can point back to later.

**5. The crow vanishes.** When the passage opens, the crow is gone. A feather is left on the sill. Walking into the passage ends the prologue (default: an "End of the prologue" card, then back to the title; see open question 1).

Rules kept: the crow and Maren never name Caldris; no quest log, no objective text, no saving warnings; the crow's lines read as sweet on a first run and as Caldris's fear and longing on a second.

## Draft lines (placeholders for the owner to rewrite)

| id | lines |
|---|---|
| `gate_lily` | (narr) An Order lily in a stone cup by the gate. Its petals have gone the colour of tallow. |
| `gate_cathedral` | (narr) Beyond the wall, the cathedral. No windows are lit. It looks closer than it should. |
| `gate_bellrope` | (narr) A bell rope, cut cleanly at shoulder height. |
| `edrin_arrival` | Edrin: Sister Maren? Light keep you. I'm Edrin. I've been sent to look after you. / Edrin: You'll want to be out of the cold. The damp gets into everything here. Even the hymnals. / Maren: It's colder than I remember. / Edrin: You've been here before? Of course. You'd have been very small. Forgive me. / Edrin: This way. |
| `hall_hooks` | (narr) A row of coat hooks. One still holds a child's coat, far too small and far too clean. |
| `hall_hymnboard` | (narr) A hymn board. The numbers have been taken down and stacked face-down beneath it. |
| `edrin_goodnight` | Edrin: This is yours. I aired it out myself. / Edrin: There's... a custom, the first night. The door is locked until the morning bell. I'll let you out myself. / Edrin: I'm sorry. I know how it sounds. / Maren: It's all right. I remember the custom. / Edrin: Light keep you, Sister. / (narr) The key turns. He waits a moment on the other side before he goes. |
| `crow_room_first` | (narr) Something taps at the glass. Then it is on the sill, inside, and the glass is still whole. / Crow: There you are. / Maren: ... / Crow: You still tuck your thumbs in when you're frightened. / Crow: He locked it gently. They always do it gently. / Crow: I can keep this moment for you, if you like. I keep all of them. |
| `crow_room_repeat` (pool, one per visit, cycling) | Crow: Still here. I'm always a little bit here. / Crow: You used to hum when you counted stairs. You're doing it now. / Crow: Every door in this house remembers your hands. |
| `crow_save_prompt` | Crow: Shall I keep this one? [choices: Keep it / Not now] |
| `crow_saved` | Crow: Kept. I've had a lot of practice holding on to things. |
| `crow_declined` | Crow: Then I'll only watch. |
| `room_prayer` | (narr) The Order's evening prayer, pinned above the table: "We obey, we endure, we give, and so the Light is kept." Someone has scratched out every third word. |
| `room_sill_carving` | (narr) Small letters cut into the sill, at a child's eye height: "Give first. Then hold on. Then do as you're told, last of all, and someone will come to sit with you." |
| `candle_plaque_obey` / `_endure` / `_give` | (narr) A candle in an iron cup. Carved beneath it: OBEY. (ENDURE, GIVE) |
| `candles_wrong` | (narr) The flames lean toward the door, all three at once, and go out. |
| `candles_right` | (narr) The flames stand very straight. Behind the cloth, a nail drops to the floor. Then another. |
| `room_mirror_open` | (narr) The cloth falls. There is no glass behind it, only a low passage, and cold air. |
| `room_feather` | (narr) A black feather on the sill. It leaves no dust on your fingers, though it should. |
| `door_locked_room` | (narr) Locked. From the outside. |

The existing `mirror` line ("nailed down at the corners") is reused as the mirror's text before the puzzle is solved.

## (b) Work items

File ownership is exclusive inside a wave. Max 2 Sonnet builders at once. Each item ends with the headless smoke run passing (`<godot> --path . --headless --quit-after 1`) and its own tests passing.

### Wave 1 (parallel)

**W1. Story memory (GameState).** Remembers what has happened: flags, who has been talked to, play time, hidden devotion tally.
- Files: new `scripts/core/game_state.gd`; `project.godot` (add autoload `GameState`).
- API: `reset()`, `set_flag(id, value := true)`, `get_flag(id, default := false)`, `mark_talked(key)`, `has_talked(key)`, `playtime_sec: float` (counts only while `counting` is true), `devotion: int`, `to_dict() -> Dictionary`, `from_dict(d)`. Signal `flag_changed(id, value)`.
- Accept: round-trip `from_dict(to_dict())` is lossless; `reset()` clears everything.

**W2. Dialogue choices.** The dialogue box can end a line with two or more choices.
- Files: `scripts/ui/dialogue_box.gd`, `scenes/ui/dialogue_box.tscn`.
- A line may carry `"choices": [{"text": "...", "value": "..."}]`. Up/down (ui_up/ui_down plus move_up/move_down) moves the cursor, interact confirms. New signal `chose(value: String)`, emitted just before `finished`. Add `var last_choice := ""`.
- Accept: existing conversations behave exactly as before; a choice line cannot be skipped by mashing interact during typing (first press finishes typing, next selects).

### Wave 2 (parallel)

**W3. Save files (SaveSystem).** Reads and writes the 20 slots. Needs W1.
- Files: new `scripts/core/save_system.gd` (`class_name SaveSystem`, static functions, no autoload); new `tests/test_save_system.gd`.
- API: `SLOT_COUNT := 20`, `static var save_dir := "user://saves/"`, `save_slot(n, data) -> bool`, `load_slot(n) -> Dictionary` (empty if missing or damaged), `slot_summary(n) -> Dictionary` (`{exists, damaged, area_label, playtime_sec, saved_at}`), `any_saves() -> bool`. Writes to a temp file then renames, so a crash cannot ruin a slot.
- Accept: test file passes (see section d).

**W4. Dialogue content.** All lines from the table above go into the data file.
- Files: `data/dialogue.json` only.
- Accept: valid JSON, every id in the table exists, existing ids untouched. `crow_save_prompt` uses the W2 `choices` shape with values `save` / `no`.

### Wave 3 (parallel)

**W5. Save menu.** The 20-slot list, used both for saving (crow) and loading (title).
- Files: new `scenes/ui/save_menu.tscn`, `scripts/ui/save_menu.gd`.
- CanvasLayer above the dialogue box, in group `save_menu`. `open(mode: "save"|"load")`, signal `closed(slot: int)` (-1 when cancelled). Shows about 6 rows at a time, scrolls. Row: `File 01   Maren's Room   0:12:34   2026-11-24 21:03`, empty rows `File 03   -`, damaged rows `File 04   (unreadable)`. Interact confirms, `ui_cancel` (Esc) backs out. In load mode, empty and damaged rows can't be picked. Saving over an occupied slot happens without a confirm (RPG Maker style).
- Accept: works with keyboard only; placeholder look matches the dialogue box (same colours).

**W6. Persistent interactables.** "Already talked" survives saving and loading.
- Files: `scripts/interaction/interactable.gd`.
- Key = `owner.name + "/" + str(owner.get_path_to(self))`; use `GameState.has_talked/mark_talked` instead of the local bool. Add optional `@export var visible_flag := ""` / `hidden_flag := ""`; add `apply_state()` which shows/hides (and sets monitorable) from those flags.
- Accept: existing manor_room behaviour unchanged.

### Wave 4 (parallel)

**W7. Game flow in Main.** New game, load, title, area hooks.
- Files: `scripts/main.gd`, `scenes/main.tscn`, `tests/test_player_grid.gd` (one-line setup change only).
- `_ready` shows the title instead of entering an area. Add to `AREAS`: `gate`, `entrance_hall`, `maren_room` (paths `res://scenes/areas/prologue/<id>.tscn`). New: `start_new_game()` (GameState.reset, enter `gate`/`start`, counting on), `load_game(data)` (free cache, GameState.from_dict, enter area and place at saved cell/facing), `build_save_data() -> Dictionary`, `enter_directly(area_id, spawn)` for tests, `return_to_title()`. After every `_enter`, call `area.apply_state()` if it has one, then call it on every node in group `stateful` inside the area. Area label for saves comes from area root metadata `area_label`. Instance `SaveMenu` and `TitleScreen` (title from W9; until W9 lands, a placeholder node with the same API is fine, W9 replaces it) in main.tscn.
- test_player_grid: after loading main, call `M.enter_directly("manor_room", "start")`.
- Accept: test_player_grid and test_chaser_pathing still pass; existing manor_room and grounds_test reachable via `enter_directly`.

**W8. The save-point crow.** A reusable crow that talks, offers to save, appears and vanishes on flags.
- Files: new `scenes/save/save_crow.tscn`, `scripts/save/save_crow.gd`.
- Exports: `crow_id`, `first_conversation_id`, `repeat_pool: PackedStringArray`, `appear_flag := ""` (empty = always), `vanish_flag := ""` (empty = never; this is the Seal crow later), `leave_feather := true`. In groups `interactable` and `stateful`. On interact: first conversation (or next pool line), then `crow_save_prompt`; on `save` open SaveMenu in save mode, write `Main.build_save_data()` with `save_point = crow_id`, then `crow_saved`; on `no` play `crow_declined`. Player frozen while the menu is open. `apply_state()` sets visibility from the flags. When `appear_flag` turns on while the area is live, fade in over 0.5 s; when `vanish_flag` turns on, fade out and show a `Feather` interactable (`room_feather`). Placeholder art: the existing black polygon bird with its bob.
- Accept: saving from the crow produces a slot that loads back to the same room with the crow present.

### Wave 5 (parallel)

**W9. Title screen.**
- Files: new `scenes/ui/title_screen.tscn`, `scripts/ui/title_screen.gd`; `scenes/main.tscn` only to swap the W7 placeholder for this scene (W7 is done by then).
- New Game / Continue (disabled when `SaveSystem.any_saves()` is false, opens SaveMenu in load mode) / Quit. Working title text "Lychkin". Signals `new_game`, `load_requested(slot)`.
- Accept: keyboard only; Continue loads into the right area.

**W10. The gate and entrance hall.**
- Files: new `scenes/areas/prologue/gate.tscn`, `entrance_hall.tscn`, `scripts/areas/prologue/gate.gd`, `entrance_hall.gd`; new `scripts/characters/npc_walker.gd` (walks a character tile by tile along a list of cells, awaitable, uses `character_sprite.update_motion`).
- Gate: reuse the grounds tileset and props; examinables `gate_lily`, `gate_cathedral`, `gate_bellrope`; Edrin at the door with `edrin_arrival`; after it, fade to `entrance_hall`. Hall: Edrin walks ahead to the room door (player frozen during the walk), examinables `hall_hooks`, `hall_hymnboard`; the room door takes her to `maren_room`. Sets flags `prologue.arrived`, `prologue.in_hall`. Both roots get `area_label` ("Hollowmere, the gate", "Hollowmere, the hall").
- Accept: walkable start to finish on keyboard; the front door won't let her back out after entering (`door_locked`).

### Wave 6 (one builder)

**W11. Maren's room, the crow and the candle puzzle.**
- Files: new `scenes/areas/prologue/maren_room.tscn`, `scripts/areas/prologue/maren_room.gd`, `scripts/puzzles/candle_row.gd`.
- On first entry: Edrin is inside, `edrin_goodnight` plays automatically, he walks out, door sound/fade, flag `prologue.edrin_left`. The `SaveCrow` (appear `prologue.edrin_left`, vanish `prologue.candles_solved`) fades in **immediately** on that flag. Examinables: `room_prayer`, `room_sill_carving`, `mirror`, `door_locked_room`. Candle row: three candles; lighting order is remembered; any wrong full sequence plays `candles_wrong` and resets; GIVE, ENDURE, OBEY plays `candles_right`, sets `prologue.candles_solved`, crow vanishes, mirror becomes `room_mirror_open` and an exit into the passage. Passage exit plays an "End of the prologue" card and returns to title (flag `prologue.done`). `apply_state()` restores all of this from flags (Edrin gone, candles lit, mirror open) so a load mid-puzzle is correct. Area label "Hollowmere, Maren's room".
- Accept: crow is not visible or talkable before Edrin leaves and is talkable within 1 s after; loading a save made at the crow puts her in the room with Edrin gone and the crow present.

### Wave 7 (one builder, then Opus review)

**W12. Prologue flow test + docs.** `tests/test_prologue_flow.gd`; add "Save crow" to GLOSSARY.md (under Fragment) and record the save format in `docs/godot.md`.

## (c) Data shapes

**Save file**: `user://saves/slot_01.json` ... `slot_20.json` (plain JSON so it is easy to inspect).

```json
{
  "version": 1,
  "saved_at": "2026-11-24T21:03:11",
  "playtime_sec": 754.2,
  "area_id": "maren_room",
  "area_label": "Hollowmere, Maren's room",
  "cell": [24, 20],
  "facing": "down",
  "save_point": "crow_maren_room",
  "state": {
    "flags": {"prologue.arrived": true, "prologue.edrin_left": true},
    "talked": {"MarenRoom/SaveCrow": true},
    "devotion": 0,
    "crow_pool_index": {"crow_maren_room": 1}
  }
}
```
`state` is exactly `GameState.to_dict()`. Unknown `version` or bad JSON = slot shown as unreadable, never a crash.

**Dialogue line with choices** (additive; old lines unchanged):
```json
{"speaker": "Crow", "text": "Shall I keep this one?",
 "choices": [{"text": "Keep it", "value": "save"}, {"text": "Not now", "value": "no"}]}
```

**Flags used by the prologue**: `prologue.arrived`, `prologue.in_hall`, `prologue.edrin_left`, `prologue.candles_solved`, `prologue.done`. Dotted names, grouped by part.

**Area root metadata**: `area_size` (exists), new `area_label` (string shown in save slots).

## (d) Tests (same style as tests/test_player_grid.gd: `extends SceneTree`, PASS/FAIL lines, `DONE fails=N`, exit code 1 on failure)

`tests/test_save_system.gd` (W3). Sets `SaveSystem.save_dir = "user://test_saves/"` and deletes it at the end.
- S1 save slot 3 then load: equal dictionaries.
- S2 slot numbers outside 1..20 are refused.
- S3 missing slot: `load_slot` empty, summary `exists=false`.
- S4 garbage text in a slot file: `damaged=true`, no crash.
- S5 `any_saves()` false on empty dir, true after one save.
- S6 GameState `from_dict(to_dict())` round-trip with flags, talked, devotion.

`tests/test_prologue_flow.gd` (W12). Loads main.tscn.
- F1 `start_new_game()` lands in `gate`, title hidden.
- F2 in `maren_room` before `prologue.edrin_left`: crow invisible and not monitorable.
- F3 after the goodnight conversation finishes: crow visible and monitorable within 60 frames.
- F4 talking to the crow plays `crow_room_first` then the save prompt; choosing `save` and slot 1 writes a slot whose `area_id` is `maren_room` (uses test save dir).
- F5 wrong candle order: `prologue.candles_solved` stays false, candles reset.
- F6 right order: flag set, crow hidden, mirror exit enabled, feather present.
- F7 `load_game(slot 1)`: back before the puzzle, Edrin absent, crow present, candles unlit.
- F8 second talk to the crow uses the repeat pool, not the first conversation.

Run lines go in each file's header like the existing tests:
`<godot> --path . --headless --fixed-fps 60 --script tests/test_save_system.gd`

## (e) Open questions for the owner

1. **Where the prologue ends.** Default: "End of the prologue" card, then back to the title. Alternative: the passage leads straight into the existing test room and chase. Which?
2. **The tutorial puzzle.** Default A. Pick one:
   - A. **Three candles, two readings** (described above). No inventory needed, teaches the two-faith reading right away.
   - B. **The nailed mirror.** Find a hairpin in the drawer, pry the nails. Teaches item use, but needs an inventory first (bigger job).
   - C. **The hymn numbers.** The hall's hymn board numbers open a lock in the room. Teaches carrying a clue between rooms; less about the two faiths.
3. **The locked-door custom.** Edrin locks her in on the first night. It is strong dread and sets up her first defiance. Keep it, or soften it?
4. **The childhood carving on the sill.** Is it Maren's own (a second-playthrough reveal), or someone else's? The default draft leaves it ambiguous.
5. **The candle words.** OBEY / ENDURE / GIVE are placeholders. Do you want to write the Order prayer and the old reading yourself?
6. **Art placeholders.** Crow: the current black shape with a bob. Edrin: the existing bought sprite. Gate and hall: bought tilesets. Do you want to draw the crow (idle, appear, vanish) and the feather now, or later?
7. **What the save choice says.** "Keep it / Not now" is the default. Want different words?
8. **Title screen.** Plain text "Lychkin" with New Game / Continue / Quit for now. The "Good Ending?" list comes much later. OK?
9. **Saving over a file.** RPG Maker overwrites without asking. Keep that, or ask "Overwrite?"
