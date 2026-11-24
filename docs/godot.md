# Godot setup

- GDScript only (no C#/Mono). Forward Plus renderer.
- There is no build, lint, or test setup. Use the `godot` MCP tools (run project, read debug output, create scenes and nodes) or run Godot directly.
- The Godot executable path is set as `GODOT_PATH` in `.mcp.json` and is specific to the owner's Windows machine. It is not a shell environment variable, so read it from that file when running Godot by hand.
- Headless smoke run: `<godot exe> --path . --headless --quit-after 1`
- Tests live in `tests/` and each is a standalone script. Run one with `<godot exe> --path . --headless --fixed-fps 60 --script tests/<name>.gd`. They print PASS/FAIL lines and `DONE fails=N`, and exit with code 1 on any failure. The run line is also in each file's header. Current tests: `test_game_state`, `test_save_system`, `test_dialogue_choices`, `test_save_menu`, `test_save_crow`, `test_prologue_gate_hall`, `test_maren_room`, `test_player_grid`, `test_chaser_pathing`, `test_area_framing`, `test_area_layouts`. Save tests use a throwaway save folder, so they never touch real saves.
- Scenes (`.tscn`) and script `.uid` files are committed; `.godot/` and `*.import` are gitignored. When moving or renaming a script, move its `.uid` file with it.
- Save system, story flags, areas and crows: see [docs/save-system.md](save-system.md).
- Known issue: the `GODOT_PATH` value in `.mcp.json` uses single backslashes, which is invalid JSON. If the MCP server fails to load, change them to `\` or `/`.
