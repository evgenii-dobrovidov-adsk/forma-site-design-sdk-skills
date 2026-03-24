#!/usr/bin/env bash

set -euo pipefail

legacy_skill_names=(
  "autodesk-forma-coordinate-system"
  "autodesk-forma-embedded-views"
)

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
  if [[ ! -d "$target_skills_dir" ]]; then
    echo "Skipping missing skills directory: $target_skills_dir"
    continue
  fi

  echo "Cleaning legacy skill links in: $target_skills_dir"

  for skill_name in "${legacy_skill_names[@]}"; do
    target_link="$target_skills_dir/$skill_name"

    if [[ -L "$target_link" ]]; then
      rm -f "$target_link"
      echo "  Removed symlink: $skill_name"
      continue
    fi

    if [[ -e "$target_link" ]]; then
      echo "  Skipping existing non-symlink: $target_link"
      continue
    fi

    echo "  Not present: $skill_name"
  done
done
