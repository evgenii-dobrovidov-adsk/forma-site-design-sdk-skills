#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source_skills_dir="$repo_root/skills"

if [[ ! -d "$source_skills_dir" ]]; then
  echo "Skills source directory not found: $source_skills_dir" >&2
  exit 1
fi

config_dirs=(
  "$HOME/.agents"
  "$HOME/.claude"
  "$HOME/.copilot"
  "$HOME/.codex"
  "$HOME/.ollama"
  "$HOME/.cursor"
)

for config_dir in "${config_dirs[@]}"; do
  if [[ ! -d "$config_dir" ]]; then
    echo "Skipping missing config directory: $config_dir"
    continue
  fi

  target_skills_dir="$config_dir/skills"
  mkdir -p "$target_skills_dir"

  echo "Linking skills into: $target_skills_dir"

  for skill_dir in "$source_skills_dir"/*; do
    if [[ ! -d "$skill_dir" || ! -f "$skill_dir/SKILL.md" ]]; then
      continue
    fi

    skill_name="$(basename "$skill_dir")"
    target_link="$target_skills_dir/$skill_name"

    if [[ -e "$target_link" && ! -L "$target_link" ]]; then
      echo "  Skipping existing non-symlink: $target_link"
      continue
    fi

    rm -f "$target_link"
    ln -s "$skill_dir" "$target_link"
    echo "  Linked $skill_name"
  done
done
