# Saving, story flags, areas and crows

## Game flow

The game opens on the title screen (New Game / Continue / Quit). New Game resets the story memory and starts at the gate (`gate`). Continue opens the list of 20 save files. `scripts/main.gd` owns this flow: `start_new_game()`, `load_game(data)`, `return_to_title()`, `build_save_data()`, and `enter_directly(area_id, spawn)` (a shortcut for tests that skips the title).

## Story memory (GameState)

`GameState` (an autoload, `scripts/core/game_state.gd`) remembers what has happened:

- **flags**: yes/no facts about the story, set with `GameState.set_flag(id)` and read with `get_flag(id)`. Names are dotted and grouped by part. The prologue uses `prologue.arrived`, `prologue.in_hall`, `prologue.edrin_left`, `prologue.candles_solved`, `prologue.done`.
- **talked**: which things Maren has already looked at or talked to (so repeat lines play).
- **devotion**: the hidden tally.
- **crow_pool_index**: how far through its repeat lines each crow is.
- **playtime**: only counts while a game is running (not on the title).

`flag_changed` is emitted whenever a flag changes. `to_dict()` and `from_dict()` turn all of this into save data and back.

## Save files

`SaveSystem` (`scripts/core/save_system.gd`) reads and writes 20 slots as plain JSON, `slot_01.json` to `slot_20.json`, in the game's `user://saves/` folder. A slot is written to a temporary file and then renamed, so a crash cannot ruin it. A missing slot reads as empty. A damaged slot or one with an unknown version reads as "unreadable" and never crashes the game.

Each file holds: `version`, `saved_at`, `playtime_sec`, `area_id`, `area_label`, `cell`, `facing`, `save_point` (which crow), and `state` (the `GameState.to_dict()` output).

The save menu (`scripts/ui/save_menu.gd`) is the shared 20-slot list, used for saving (at a crow) and loading (from the title). Saving over a used slot does not ask for confirmation.

## Adding a new area

1. Make the scene under `scenes/areas/` and add it to `AREAS` in `scripts/main.gd` with an id.
2. On the area's root node set the metadata `area_size` and `area_label`. The label is the name shown in the save list.
3. Add a `Spawns/<name>` marker for each place the player can arrive (set `facing` metadata if needed). Exits take the target area id and spawn name.
4. If the area changes with the story (props that appear, doors that open), give the root an `apply_state()` method. `Main` calls it every time the area is entered, including after a load, so the area must rebuild itself from `GameState` flags only.
5. Things that should show or hide by flag can use the `visible_flag` / `hidden_flag` settings on an interactable instead of code.

Anything in the group `stateful` inside the area that has `apply_state()` is also refreshed on entry.

## Adding a save crow

Place `scenes/world/save_crow.tscn` in the area and set:

- `crow_id`: a unique name for this crow (it is stored in saves as `save_point`).
- `first_conversation_id` and `repeat_pool`: dialogue ids in `data/dialogue.json` for the first visit and later visits (the pool cycles).
- `visible_flag`: the crow appears (fades in) when this flag is set. Empty means always there.
- `hidden_flag`: the crow vanishes (fades out) when this flag is set. Empty means never.

The crow then offers `crow_save_prompt` (Keep it / Not now), opens the save menu, and writes the slot. The wording of all its lines lives in `data/dialogue.json`. The crow never explains saving or warns the player.

A dialogue line can carry `choices` (`[{"text": ..., "value": ...}]`); the picked value is available as `Dialogue.last_choice`.
