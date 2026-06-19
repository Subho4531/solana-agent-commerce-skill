#!/usr/bin/env bash

# Solana Agent Commerce Skill - Standard Installer

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Target paths
SKILL_DIR_NAME="solana-agent-commerce"
INSTALL_TARGET="codex"
CODEX_HOME_DIR="${CODEX_HOME:-${HOME}/.codex}"
TARGET_SKILL_DIR="${CODEX_HOME_DIR}/skills/${SKILL_DIR_NAME}"
TARGET_AGENTS_DIR="${HOME}/.agents"
TARGET_RULES_DIR="${CODEX_HOME_DIR}/rules"
TARGET_COMMANDS_DIR="${CODEX_HOME_DIR}/commands"

INSTALL_AGENTS=false
INSTALL_RULES=false
INSTALL_COMMANDS=false

print_banner() {
    echo ""
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║${NC}                                                                                                  ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}   ${CYAN}███████╗ ██████╗ ██╗      █████╗ ███╗   ██╗█████╗   ${GREEN}█████╗  ██████╗ ███████╗███╗   ██╗████████╗${NC}${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}   ${CYAN}██╔════╝██╔═══██╗██║     ██╔══██╗████╗  ██║██╔══██╗ ${GREEN}██╔══██╗██╔════╝ ██╔════╝████╗  ██║╚══██╔══╝${NC}${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}   ${CYAN}███████╗██║   ██║██║     ███████║██╔██╗ ██║███████║ ${GREEN}███████║██║  ███╗█████╗  ██╔██╗ ██║   ██║   ${NC}${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}   ${CYAN}╚════██║██║   ██║██║     ██╔══██║██║╚██╗██║██╔══██║ ${GREEN}██╔══██║██║   ██║██╔══╝  ██║╚██╗██║   ██║   ${NC}${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}   ${CYAN}███████║╚██████╔╝███████╗██║  ██║██║ ╚████║██║  ██║ ${GREEN}██║  ██║╚██████╔╝███████╗██║ ╚████║   ██║   ${NC}${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}   ${CYAN}╚══════╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ${GREEN}╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═══╝   ╚═╝   ${NC}${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}                                                                                                  ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}                            ${YELLOW}███████╗██╗  ██╗██╗██╗     ██╗     ███████╗${NC}                            ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}                            ${YELLOW}██╔════╝██║ ██╔╝██║██║     ██║     ██╔════╝${NC}                            ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}                            ${YELLOW}███████╗█████╔╝ ██║██║     ██║     ███████╗${NC}                            ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}                            ${YELLOW}╚════██║██╔═██╗ ██║██║     ██║     ╚════██║${NC}                            ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}                            ${YELLOW}███████║██║  ██╗██║███████╗███████╗███████║${NC}                            ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}                            ${YELLOW}╚══════╝╚═╝  ╚═╝╚═╝╚══════╝╚══════╝╚══════╝${NC}                            ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}                                                                                                  ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}                             ${WHITE}Solana Agent Commerce Skill for AI Agents${NC}                            ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}                                                                                                  ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}   ${GREEN}▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄${NC}   ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}                                     ${YELLOW}Powered by x402 Protocol${NC}                                     ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}   ${GREEN}▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀${NC}   ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}                                                                                                  ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_help() {
    echo "Solana Agent Commerce Skill - Standard Installer"
    echo ""
    echo "Usage: ./install.sh [OPTIONS]"
    echo ""
    echo "Installs with recommended defaults:"
    echo "  - Location: \${CODEX_HOME:-~/.codex}/skills/"
    echo "  - Installs the solana-agent-commerce skill"
    echo ""
    echo "Options:"
    echo "  --agents       Install specialized agents (x402-architect, etc.)"
    echo "  --rules        Install x402 security rules"
    echo "  --commands     Install command prompts"
    echo "  --target codex Install to Codex locations (default)"
    echo "  --target claude Install to Claude locations"
    echo "  -y, --yes      Skip confirmation prompt"
    echo "  -h, --help     Show this help"
    echo ""
}

# Parse flags
SKIP_CONFIRM=false
while [[ $# -gt 0 ]]; do
  case $1 in
    --agents)
      INSTALL_AGENTS=true
      shift
      ;;
    --rules)
      INSTALL_RULES=true
      shift
      ;;
    --commands)
      INSTALL_COMMANDS=true
      shift
      ;;
    --target)
      INSTALL_TARGET="$2"
      if [ "$INSTALL_TARGET" = "claude" ]; then
        TARGET_SKILL_DIR="${HOME}/.claude/skills/${SKILL_DIR_NAME}"
        TARGET_RULES_DIR="${HOME}/.claude/rules"
        TARGET_COMMANDS_DIR="${HOME}/.claude/commands"
      elif [ "$INSTALL_TARGET" = "codex" ]; then
        TARGET_SKILL_DIR="${CODEX_HOME_DIR}/skills/${SKILL_DIR_NAME}"
        TARGET_RULES_DIR="${CODEX_HOME_DIR}/rules"
        TARGET_COMMANDS_DIR="${CODEX_HOME_DIR}/commands"
      else
        echo "Unknown target: $INSTALL_TARGET"
        echo "Use --target codex or --target claude"
        exit 1
      fi
      shift 2
      ;;
    -y|--yes)
      SKIP_CONFIRM=true
      shift
      ;;
    -h|--help)
      print_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

print_banner

echo -e "${WHITE}Standard Installation${NC}"
echo ""
echo -e "This will install:"
echo -e "  ${BLUE}•${NC} solana-agent-commerce  → ${CYAN}$TARGET_SKILL_DIR${NC}"
if [ "$INSTALL_AGENTS" = true ]; then
echo -e "  ${BLUE}•${NC} Specialized Agents           → ${CYAN}$TARGET_AGENTS_DIR${NC}"
fi
if [ "$INSTALL_RULES" = true ]; then
echo -e "  ${BLUE}•${NC} x402 Security Rules          → ${CYAN}$TARGET_RULES_DIR${NC}"
fi
if [ "$INSTALL_COMMANDS" = true ]; then
echo -e "  ${BLUE}•${NC} Commands                    → ${CYAN}$TARGET_COMMANDS_DIR${NC}"
fi
echo ""

if [ "$SKIP_CONFIRM" = false ]; then
    read -p "Proceed with installation? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo -e "${YELLOW}Installation cancelled${NC}"
        exit 0
    fi
fi

echo ""

echo -e "${CYAN}[1/1]${NC} Installing solana-agent-commerce..."

# Create target directories if they don't exist
mkdir -p "${TARGET_SKILL_DIR}"
mkdir -p "${TARGET_SKILL_DIR}/references"

# Copy Skill Hub and Reference manuals
cp -r "$SCRIPT_DIR/skill/SKILL.md" "${TARGET_SKILL_DIR}/"
cp -r "$SCRIPT_DIR/skill/references/"* "${TARGET_SKILL_DIR}/references/"
echo -e "  ${GREEN}✓${NC} Installed skill hub and references to: $TARGET_SKILL_DIR"

if [ -d "$SCRIPT_DIR/docs" ]; then
  mkdir -p "$(dirname "$TARGET_SKILL_DIR")/docs"
  cp -r "$SCRIPT_DIR/docs/"* "$(dirname "$TARGET_SKILL_DIR")/docs/"
  echo -e "  ${GREEN}✓${NC} Installed docs next to skills"
fi

# Install Agents if requested
if [ "$INSTALL_AGENTS" = true ]; then
  echo -e "${CYAN}[+]${NC} Installing specialized agents..."
  mkdir -p "${TARGET_AGENTS_DIR}"
  cp -r "$SCRIPT_DIR/agents/"* "${TARGET_AGENTS_DIR}/"
  echo -e "  ${GREEN}✓${NC} Installed system agents to: $TARGET_AGENTS_DIR"
fi

# Install Rules if requested
if [ "$INSTALL_RULES" = true ]; then
  echo -e "${CYAN}[+]${NC} Installing developer rules..."
  mkdir -p "${TARGET_RULES_DIR}"
  cp -r "$SCRIPT_DIR/rules/"* "${TARGET_RULES_DIR}/"
  echo -e "  ${GREEN}✓${NC} Installed developer rules to: $TARGET_RULES_DIR"
fi

if [ "$INSTALL_COMMANDS" = true ]; then
  echo -e "${CYAN}[+]${NC} Installing commands..."
  mkdir -p "${TARGET_COMMANDS_DIR}"
  cp -r "$SCRIPT_DIR/commands/"* "${TARGET_COMMANDS_DIR}/"
  echo -e "  ${GREEN}✓${NC} Installed commands to: $TARGET_COMMANDS_DIR"
fi

# Done
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}  ${WHITE}Installation Complete!${NC}                                                ${GREEN}║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${WHITE}Installed:${NC}"
echo -e "  ${GREEN}✓${NC} solana-agent-commerce  ${CYAN}$TARGET_SKILL_DIR${NC}"
if [ "$INSTALL_AGENTS" = true ]; then
echo -e "  ${GREEN}✓${NC} Specialized Agents           ${CYAN}$TARGET_AGENTS_DIR${NC}"
fi
if [ "$INSTALL_RULES" = true ]; then
echo -e "  ${GREEN}✓${NC} x402 Security Rules          ${CYAN}$TARGET_RULES_DIR${NC}"
fi
if [ "$INSTALL_COMMANDS" = true ]; then
echo -e "  ${GREEN}✓${NC} Commands                    ${CYAN}$TARGET_COMMANDS_DIR${NC}"
fi
echo ""
echo -e "${CYAN}Try asking your agent:${NC}"
echo -e "  ${BLUE}•${NC} \"/scaffold-seller to create a paid API endpoint\""
echo -e "  ${BLUE}•${NC} \"/scaffold-buyer to create an autonomous client\""
echo -e "  ${BLUE}•${NC} \"/audit-routes to review my integration for security flaws\""
echo ""
echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}                     Powered by x402 Protocol${NC}"
echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
