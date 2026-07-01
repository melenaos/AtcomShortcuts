# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

MyShortcuts is a collection of PowerShell launcher scripts that provide quick access to development projects. `MyShortcuts.ps1` is the management hub; all other `.ps1` files are per-project shortcut scripts that open directories, launch IDEs, start services, and compile solutions.

## Setup

Scripts must be unblocked before first use:
```powershell
Get-ChildItem -Path .\ -Recurse -Filter *.ps1 | Unblock-File
```

## Architecture

### MyShortcuts.ps1 — The Manager

Manages the shortcut collection itself. Key capabilities:
- `-init` adds the MyShortcuts directory to the user's `PATH` environment variable so scripts can be called by name from anywhere.
- `-new` launches an interactive wizard to create a new shortcut script from feature snippets in `templates/snippets/`.
- `-edit` opens an action menu for an existing shortcut: **Add predefined feature**, **Add custom command**, or **Open in editor**.
- `-list` lists all available `.ps1`/`.bat` shortcuts.
- `-directory` / `-d` opens the MyShortcuts folder (in Explorer or terminal with `-t`).

### Configuration

`settings.json` stores user-level config:
- `devDirectory` — base development folder used to resolve relative project paths
- `editorPath` — editor to open scripts with (defaults to `notepad.exe`)
- `tunnelName` — default Cloudflared tunnel name (optional)

`config/features.json` defines the predefined feature registry: each feature has an `id`, display `label`, `snippet` filename, `scope` (`"project"` or `"global"`), `params` array (switch name, alias, type), and optional `prompts` array for config variable requirements.

- **project-scoped** features (`directory`, `explorer`, `project`, `code`, `claude`, `compile`, and the ATCOM features `atcomrun`/`docker`/`site`) are generated against the script's single project directory. Snippets use `{{placeholders}}` that get expanded for that directory.
- **global** features (`tunnel`, `azurite`) have no directory association.

#### ATCOM project features

ATCOM projects have a fixed internal layout under the project root: a `Docker/` folder (with `up.ps1` and a `.env` containing `COMPOSE_PROJECT_NAME=<Name>`) and a `Site/` folder (the runnable `.csproj`). These features reference those subfolders of `{{dir}}`:
- `docker` (`-docker`) — `cd {{dir}}\Docker` and run `.\up.ps1 -Run`. `up.ps1` runs `docker-compose up -d` (detached), so the command returns; runs inline.
- `site` (`-site` / `-s`) — `cd {{dir}}\Site` and run `dotnet run` in a new Windows Terminal window (long-running, so it gets its own tab).
- `atcomrun` (`-run` / `-r`) — the full project: docker up (inline) followed by the Site `dotnet run` (new window).

Both `docker` and `atcomrun` first check `{{dir}}\Docker\.env`: if `COMPOSE_PROJECT_NAME` contains uppercase letters (which docker-compose rejects), the user is warned and prompted `(Y/n)` to lowercase it in place before the containers start.

Prompts with `"perProject": true` (e.g., `sln` for project/compile) are prompted once and stored as `$<dirName>_<var>`, where `<dirName>` is derived from the project name (e.g., `$TestProject_sln`).

### lib/InteractiveMenu.ps1

Two reusable console UI functions used by the wizard and edit flows:
- `Show-SelectionMenu -Title -Options` — single-select arrow-key menu, returns selected index.
- `Show-ChecklistMenu -Title -Items` — multi-select checklist (space to toggle, enter to confirm), returns array of selected indices. Items are `@{ label = "..."; checked = $true/$false }`.

### Per-Project Shortcut Scripts

Each project script created from MyShortcuts follows a consistent pattern:

**Configuration block** (top of every script):
- `$projects` — ordered hashtable with a single entry mapping the project's directory name to its path (e.g., `"TestProject" = "$($settings.devDirectory)\TestProject"`). The directory name is derived from the project name (non-alphanumeric characters stripped).
- `$<dirName>_sln` — solution name for the project (e.g., `$TestProject_sln`)
- `$tunnelName` — Cloudflared tunnel name (global)

**Switch naming convention:**
- Each script targets one project directory, so switches use plain names: `-directory`, `-claude`, `-code`, etc.
- Switches keep their aliases (e.g., `-d` for `-directory`).

**Common switches** (present in most scripts):
| Switch | Alias | Action |
|--------|-------|--------|
| `-directory` | `-d` | Open the project directory |
| `-explorer` | `-exp` | Open the project directory in Windows Explorer |
| `-project` | `-p` | Open `.sln` in Visual Studio (generic `project` feature) |
| `-site` | `-s` | `dotnet run` the Site project (ATCOM `site` feature) |
| `-docker` | | Start docker containers via `Docker\up.ps1 -Run` (ATCOM) |
| `-run` | `-r` | Run the full ATCOM project: docker + Site (ATCOM) |
| `-all` | `-a` | Run all launch actions together |
| `-release` | | dotnet build in Release config |
| `-debug` | | dotnet build in Debug config |
| `-code` | | Open project in VS Code |
| `-tunnel` | | Start Cloudflared tunnel |
| `-claude` | | Open Claude Code in the project directory |

Not every script has every switch — check the `param()` block at the top of each file.

### Templates

`templates/snippets/` contains individual feature snippets. Project-scoped snippets use `{{placeholders}}`:
- `{{dir}}` — directory reference (e.g., `$($projects.TestProject)`)
- `{{switch}}` — switch variable name (e.g., `directory`)
- `{{label}}` — directory name for comments (e.g., `TestProject`)
- `{{sln}}` — solution variable (e.g., `$TestProject_sln`)
- `{{switchRelease}}` / `{{switchDebug}}` — for compile snippet

Global snippets (`tunnel.ps1`, `azurite.ps1`) remain as plain `if($switchName){ ... }` blocks.

### Helper Functions

- `Expand-Snippet` — reads a snippet template and replaces `{{placeholders}}` with provided values.
- `Get-SwitchName` — returns the switch name for a feature+directory combination. Retained for snippet expansion; with a single directory it always returns the plain name.
- `Get-ExistingProjects` — parses the `$projects = [ordered]@{...}` block from script lines to extract the directory name and path.

### Marker Comments & Feature Injection

Scripts created by the `-new` wizard contain four marker comments that enable programmatic editing via `-edit`:

- `# [/params]` — last line inside `param()`, before closing `)`. New switch declarations are injected here.
- `# [/projects]` — inside the `$projects` hashtable.
- `# [/help]` — inside the help block, before `Write-Host ""` + `exit`. New help lines are injected here.
- `# [/commands]` — very last line of the script. New command blocks are injected here.

The generated script layout also uses two config section delimiters that the injection code searches for:
- `# =============== Script =============== #` — top of config section (settings line goes after this)
- `# ===== C O N F I G U R A T I O N ====== #` — bottom of config section (new config vars go before this)

**Injection mechanics:** The edit functions read the file as an array of lines, find marker positions, then insert new content in reverse index order (commands → group trigger → help → config → params) to avoid index shifting. The last param line before the marker gets a trailing comma appended before new params are inserted.

**Add predefined feature** (`Exec-AddFeature`) adds the params/help/snippets for the selected features against the script's single project directory, and updates the group trigger.

**Add custom command** (`Exec-AddCustomCommand`) injects a new switch and command block that references `$($projects.<name>)` for the project directory.

## Conventions

- Follow the existing template structure: `param()` block, configuration variables section with `$projects` hashtable, then conditional blocks per switch.
- Generated scripts must preserve the four marker comments (`# [/params]`, `# [/projects]`, `# [/help]`, `# [/commands]`) for `-edit` injection to work.
- Use `-all` to group the common launch actions (directory, project, tunnel, etc.).
- Use `pushd`/`popd` when temporarily changing directories within a switch block.
- Use `wt --window 0` to spawn new Windows Terminal tabs for long-running processes (tunnels, claude).
- Keep `$projects` as the first configuration variable after the settings line.
- Per-project config variables use the naming convention `$<dirName>_<var>` (e.g., `$TestProject_sln`).
- New snippets in `templates/snippets/` should use `{{placeholders}}` for project-scoped features (`{{dir}}`, `{{switch}}`, `{{label}}`).
