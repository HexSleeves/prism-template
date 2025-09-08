# Repository Guidelines

## Project Structure & Module Organization

- Source: root Lua files (`main.lua`, `conf.lua`, `controls.lua`, `debugger.lua`).
- Engine: `prism/` (Git submodule of PrismRL). Update via `git submodule update --init --recursive`.
- Game code: `modules/game/` (actions, actors, cells, components, systems). Keep files lowercase (e.g., `actors/player.lua`).
- States: `gamestates/` (e.g., `gamelevelstate.lua`) for screen/flow control.
- Display assets: `display/` (sprite sheets like `wanderlust_16x16.png`).
- Type hints: `definitions/` for LuaLS annotations of Prism/game APIs.

## Build, Test, and Development Commands

- Init submodule: `git submodule update --init --recursive`
- Run locally (requires LÖVE 11.4): `love .`
- Format code (Stylua): `stylua .`
- Package builds (makelove): `makelove` → artifacts in `makelove-build/` (targets set in `makelove.toml`).
- Debugger (optional): set `LOCAL_LUA_DEBUGGER_VSCODE=1` to enable `lldebugger`.

## Coding Style & Naming Conventions

- Indent: 3 spaces; no tabs. Config in `stylua.toml`.
- Prefer concise modules and clear domain folders under `modules/game/`.
- Prism types/classes use PascalCase when registered (e.g., `prism.components.Mover`).
- Filenames: lowercase with words joined (e.g., `fallsystem.lua`, `gamelevelstate.lua`).
- Keep new globals declared in `.luarc.json` `diagnostics.globals` if needed.

## Testing Guidelines

- No formal test suite yet. Validate changes by running `love .` and exercising controls in `controls.lua`.
- If introducing tests, prefer `busted`; name specs `spec/<area>/<module>_spec.lua` and keep fast.

## Commit & Pull Request Guidelines

- Commits: small, imperative, and scoped (e.g., "Add fall system", "Update controls mapping"). Reference issues with `#123` when relevant.
- PRs: include a clear summary, run steps (`love .`), screenshots/gifs for visual changes, and mention asset or control updates.
- Keep diffs focused; update docs (README/definitions) when APIs or controls change.
- Do not update `prism/` casually; sync intentionally and in a separate PR if needed.
