# Plugin Development Rules

## YAML Frontmatter

- Multi-line descriptions MUST use `|` (literal block scalar)
- Single-line descriptions work without `|`
- Folded style without `|` breaks parsing

```yaml
# GOOD
description: Single line description

# GOOD
description: |
  Multi-line description
  with pipe character

# BAD - breaks parsing
description:
  Multi-line without pipe
```

## plugin.json Schema

- `name`: kebab-case, required
- `commands`: string (directory) or array of paths
- `agents`: array of `.md` file paths (NOT directory)
- `hooks`: path to hooks.json or inline object
- `skills`: NOT in schema - auto-discovered from `skills/*/SKILL.md`

```json
{
  "commands": "./commands/",
  "agents": ["./agents/architect.md", "./agents/debugger.md"],
  "hooks": "./hooks/hooks.json"
}
```

## marketplace.json Schema

- `name`: kebab-case marketplace identifier
- `owner`: object with `name` and `email`
- `plugins`: array of plugin entries
- Each plugin needs `name` and `source` (required)
- `source`: use `"./"` for same-repo plugins

## Component Discovery

- Commands: auto-discovered from `commands/*.md`
- Skills: auto-discovered from `skills/*/SKILL.md`
- Agents: must be explicitly listed in plugin.json
- Hooks: must be explicitly configured

## Naming Conventions

- All names: lowercase, hyphens only (kebab-case)
- No spaces, underscores, or uppercase
- Max 64 characters for skill names

## Path Rules

- All paths start with `./`
- Use `${CLAUDE_PLUGIN_ROOT}` in hooks/scripts
- Agents field requires `.md` extension on each file

## File Permissions

- All `.md` files should be `644` (readable)
- `600` permissions break plugin discovery
