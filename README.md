# Forma Site Design SDK Skills

This repository contains reusable AI agent skills for building [Autodesk Forma Site Design](https://www.autodesk.com/products/forma) embedded-view extensions.

The skills are Markdown-based instructions that help coding agents scaffold projects, use the Forma embedded view SDK correctly, and avoid common mistakes around coordinates, transforms, and extension architecture.

## Repository Contents

The main contents of this repo are:

- `skills/forma-site-design-coordinate-system`
  Guidance for Forma Site Design scene coordinates, glTF axis conversion, transforms, and placement math.
- `skills/forma-site-design-extensions`
  The main SDK skill for implementing embedded-view extensions with the Forma API surface.
- `skills/forma-site-design-extensions-bootstrap`
  A bootstrap skill for creating a new Vite + React TypeScript extension and then applying the main SDK skill.
- `install.sh`
  Installs the skills into supported local agent config directories by creating symlinks.
- `cleanup.sh`
  Removes old legacy symlinks that used earlier skill names.

## What The Skills Are For

These skills are meant for AI coding agents working on Forma Site Design extension tasks. They provide a shared source of guidance so the agent can:

- choose the right setup for a new extension
- use the Forma embedded-view SDK consistently
- understand Forma coordinate and transform conventions
- build extensions with fewer SDK-usage and geometry mistakes

## Installation

Use `install.sh` to link the skills into your local agent skill directories:

```bash
./install.sh
```

The script scans these personal config directories if they exist:

- `~/.agents`
- `~/.claude`
- `~/.copilot`
- `~/.codex`
- `~/.ollama`
- `~/.cursor`

For each existing config directory, it creates or updates symlinks in its `skills` folder so the installed skill always points back to this repository checkout. That means changes you make here are picked up without copying files around again.

If a config directory does not exist yet, the script skips it.

## Cleanup

If you previously used older skill names, run:

```bash
./cleanup.sh
```

This removes legacy symlinks named `autodesk-forma-coordinate-system` and `autodesk-forma-embedded-views` from the same agent config directories.

## References

- [GitHub Copilot agent skills](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills)
- [Claude Code skills](https://code.claude.com/docs/en/skills)
