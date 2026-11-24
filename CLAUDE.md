# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

A Godot 4.6 (GDScript, 2D) project, built with Claude Code through the Godot MCP server, that aims to become a story-driven, lore-rich game.

## Working with the owner

The owner is not a developer. Talk like a product owner would: what a feature does for the player, what changed, what's open. Skip code and engine jargon unless asked, and keep updates granular, with the reasoning in plain language.

When running `grill-with-docs` (or its `grilling` skill), ask every question through the built-in question prompter (the AskUserQuestion tool), not as plain chat text.

## Read when needed

- Adding or changing a feature: use the `building-features` skill.
- Proposing ideas, story, art or tone: [docs/creative-direction.md](docs/creative-direction.md)
- Running Godot, MCP setup, file handling: [docs/godot.md](docs/godot.md)
