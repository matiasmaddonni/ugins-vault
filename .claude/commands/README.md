# Project slash commands

Each `.md` file in this folder is a project-scoped slash command. Invoke as `/<filename>` (without `.md`).

## Layout
Each file has YAML frontmatter (`description`) followed by the instructions Claude should follow when the command is invoked.

```
.claude/commands/
  <command>.md
```

## Examples in this repo
- `/build` — runs the simulator build, reports status.
- `/regen` — regenerates the Xcode project via XcodeGen, then builds.
