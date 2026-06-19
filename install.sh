#!/usr/bin/env bash

# Solana Agent Commerce Skill - Installation Script
set -e

# Target paths
SKILL_DIR_NAME="solana-agent-commerce-skill"
TARGET_SKILL_DIR="${HOME}/.claude/skills/${SKILL_DIR_NAME}"
TARGET_AGENTS_DIR="${HOME}/.agents"
TARGET_RULES_DIR="${HOME}/.claude/rules"

INSTALL_AGENTS=false
INSTALL_RULES=false

# Parse flags
for arg in "$@"; do
  case $arg in
    --agents)
      INSTALL_AGENTS=true
      shift
      ;;
    --rules)
      INSTALL_RULES=true
      shift
      ;;
    *)
      # Unknown options
      ;;
  esac
done

echo "Installing Solana Agent Commerce Skill..."

# Create target directories if they don't exist
mkdir -p "${TARGET_SKILL_DIR}"
mkdir -p "${TARGET_SKILL_DIR}/references"

# Copy Skill Hub and Reference manuals
cp -r SKILL.md "${TARGET_SKILL_DIR}/"
cp -r references/* "${TARGET_SKILL_DIR}/references/"
echo "✔ Installed skill hub and references to: ${TARGET_SKILL_DIR}"

# Install Agents if requested
if [ "$INSTALL_AGENTS" = true ]; then
  mkdir -p "${TARGET_AGENTS_DIR}"
  cp -r agents/* "${TARGET_AGENTS_DIR}/"
  echo "✔ Installed system agents to: ${TARGET_AGENTS_DIR}"
fi

# Install Rules if requested
if [ "$INSTALL_RULES" = true ]; then
  mkdir -p "${TARGET_RULES_DIR}"
  cp -r rules/* "${TARGET_RULES_DIR}/"
  echo "✔ Installed developer rules to: ${TARGET_RULES_DIR}"
fi

echo "Installation complete!"
