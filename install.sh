#!/usr/bin/env bash

# Solana Agent Commerce Skill - Standard Installer

set -e

# Base formatting
NC='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
UNDERLINE='\033[4m'
ITALIC='\033[3m'

# High-intensity Colors
RED='\033[91m'
GREEN='\033[92m'
YELLOW='\033[93m'
BLUE='\033[94m'
PURPLE='\033[95m'
CYAN='\033[96m'
WHITE='\033[97m'
GRAY='\033[90m'

# Solana True Color Gradients (Vibrant Purple to Teal/Green)
C1='\033[38;2;153;69;255m'    # Solana Purple
C2='\033[38;2;135;80;250m'
C3='\033[38;2;117;91;245m'
C4='\033[38;2;99;102;240m'
C5='\033[38;2;81;113;235m'
C6='\033[38;2;63;124;230m'
C7='\033[38;2;45;135;225m'
C8='\033[38;2;27;146;220m'
C9='\033[38;2;20;160;210m'
C10='\033[38;2;15;180;190m'
C11='\033[38;2;10;200;170m'
C12='\033[38;2;5;220;150m'
C13='\033[38;2;20;241;149m'   # Solana Green/Teal

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Target paths
SKILL_DIR_NAME="solana-agent-commerce"
TARGET_SKILL_DIR="${HOME}/.claude/skills/${SKILL_DIR_NAME}"
TARGET_AGENTS_DIR="${HOME}/.agents"
TARGET_RULES_DIR="${HOME}/.claude/rules"

INSTALL_AGENTS=false
INSTALL_RULES=false
SKIP_CONFIRM=false

print_banner() {
    echo ""
    echo -e "${C1} ┌───────────────────────────────────────────────────────────────────────────────────────────────────────┐ ${NC}"
    echo -e "${C2} │   ${C1}███████╗ ██████╗ ██╗      █████╗ ███╗   ██╗█████╗    █████╗  ██████╗  ███████╗███╗   ██╗████████╗${C2}   │ ${NC}"
    echo -e "${C3} │   ${C2}██╔════╝██╔═══██╗██║     ██╔══██╗████╗  ██║██╔══██╗  ██╔══██╗██╔════╝ ██╔════╝████╗  ██║╚══██╔══╝${C3}   │ ${NC}"
    echo -e "${C4} │   ${C3}███████╗██║   ██║██║     ███████║██╔██╗ ██║███████║  ███████║██║  ███╗█████╗  ██╔██╗ ██║   ██║   ${C4}   │ ${NC}"
    echo -e "${C5} │   ${C4}╚════██║██║   ██║██║     ██╔══██║██║╚██╗██║██╔══██║  ██╔══██║██║   ██║██╔══╝  ██║╚██╗██║   ██║   ${C5}   │ ${NC}"
    echo -e "${C6} │   ${C5}███████║╚██████╔╝███████╗██║  ██║██║ ╚████║██║  ██║  ██║  ██║╚██████╔╝███████╗██║ ╚████║   ██║   ${C6}   │ ${NC}"
    echo -e "${C7} │   ${C6}╚══════╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝  ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═══╝   ╚═╝   ${C7}   │ ${NC}"
    echo -e "${C8} │                                                                                                       │ ${NC}"
    echo -e "${C9} │                            ${C9}███████╗██╗  ██╗██╗██╗     ██╗     ███████╗                                │ ${NC}"
    echo -e "${C10} │                            ${C10}██╔════╝██║ ██╔╝██║██║     ██║     ██╔════╝                                │ ${NC}"
    echo -e "${C11} │                            ${C11}███████╗█████╔╝ ██║██║     ██║     ███████╗                                │ ${NC}"
    echo -e "${C12} │                            ${C12}╚════██║██╔═██╗ ██║██║     ██║     ╚════██║                                │ ${NC}"
    echo -e "${C13} │                            ${C13}███████║██║  ██╗██║███████╗███████╗███████║                                │ ${NC}"
    echo -e "${C1} │                            ${C1}╚══════╝╚═╝  ╚═╝╚═╝╚══════╝╚══════╝╚══════╝                                │ ${NC}"
    echo -e "${C2} │                                                                                                       │ ${NC}"
    echo -e "${C3} │                       ${BOLD}${WHITE}SOLANA x402 AGENT COMMERCE PLATFORM & SKILL${NC}${C3}                                     │ ${NC}"
    echo -e "${C4} │                           ${DIM}${ITALIC}Autonomous Machine-to-Machine Payments${NC}${C4}                                      │ ${NC}"
    echo -e "${C5} └───────────────────────────────────────────────────────────────────────────────────────────────────────┘ ${NC}"
    echo ""
}

print_help() {
    echo -e "${C10}${BOLD}Solana Agent Commerce Skill - CLI Options${NC}"
    echo ""
    echo -e "${GRAY}Usage:${NC} ./install.sh [OPTIONS]"
    echo ""
    echo -e "${GRAY}Options:${NC}"
    echo -e "  ${C11}--agents${NC}       Install specialized system agents (architect, builder, auditor)"
    echo -e "  ${C11}--rules${NC}        Install x402 security & routing rules"
    echo -e "  ${C11}-y, --yes${NC}      Skip the interactive confirmation prompt"
    echo -e "  ${C11}-h, --help${NC}     Show this help manual"
    echo ""
}

# Parse flags
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
    -y|--yes)
      SKIP_CONFIRM=true
      shift
      ;;
    -h|--help)
      print_help
      exit 0
      ;;
    *)
      echo -e "${RED}Error: Unknown option $1${NC}"
      echo -e "Run with ${YELLOW}--help${NC} to see available options."
      exit 1
      ;;
  esac
done

print_banner

# Summary of installation target paths
echo -e "${WHITE}${BOLD}⚡ Ready to Bootstrap Skillset${NC}"
echo -e "${GRAY}------------------------------------------------------------${NC}"
echo -e "  ${C3}➜${NC} ${BOLD}x402 Core Skill${NC}      → ${CYAN}${UNDERLINE}$TARGET_SKILL_DIR${NC}"
if [ "$INSTALL_AGENTS" = true ]; then
  echo -e "  ${C3}➜${NC} ${BOLD}Specialized Agents${NC}   → ${CYAN}${UNDERLINE}$TARGET_AGENTS_DIR${NC}"
fi
if [ "$INSTALL_RULES" = true ]; then
  echo -e "  ${C3}➜${NC} ${BOLD}Security Rules${NC}       → ${CYAN}${UNDERLINE}$TARGET_RULES_DIR${NC}"
fi
echo -e "${GRAY}------------------------------------------------------------${NC}"
echo ""

if [ "$SKIP_CONFIRM" = false ]; then
    echo -ne "${C11}▶${NC} Confirm installation? [Y/n] "
    read -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo -e "\n${RED}✗ Installation cancelled by user.${NC}"
        exit 0
    fi
fi

echo ""
echo -e "${C3}[1/3]${NC} Creating directory structures..."
mkdir -p "${TARGET_SKILL_DIR}"
mkdir -p "${TARGET_SKILL_DIR}/references"
echo -e "      ${GREEN}✓ Done.${NC}"

echo -e "${C6}[2/3]${NC} Copying core skill manuals & routes..."
cp -r "$SCRIPT_DIR/skill/SKILL.md" "${TARGET_SKILL_DIR}/"
cp -r "$SCRIPT_DIR/skill/references/"* "${TARGET_SKILL_DIR}/references/"
echo -e "      ${GREEN}✓ Done.${NC}"

echo -e "${C9}[3/3]${NC} Configuring add-on packs..."
if [ "$INSTALL_AGENTS" = true ]; then
  echo -e "      ${C10}•${NC} Installing system agents (architect, builder, auditor)..."
  mkdir -p "${TARGET_AGENTS_DIR}"
  cp -r "$SCRIPT_DIR/agents/"* "${TARGET_AGENTS_DIR}/"
fi
if [ "$INSTALL_RULES" = true ]; then
  echo -e "      ${C10}•${NC} Installing developer security rules..."
  mkdir -p "${TARGET_RULES_DIR}"
  cp -r "$SCRIPT_DIR/rules/"* "${TARGET_RULES_DIR}/"
fi
echo -e "      ${GREEN}✓ Done.${NC}"

# Premium Success Summary Block
echo ""
echo -e "${C13}┌────────────────────────────────────────────────────────────────────────────────────────┐${NC}"
echo -e "${C13}│${NC}  ${GREEN}${BOLD}🎉 SUCCESS: Solana Agent Commerce Skill has been successfully initialized!${NC}          ${C13}│${NC}"
echo -e "${C13}└────────────────────────────────────────────────────────────────────────────────────────┘${NC}"
echo ""
echo -e "${WHITE}${BOLD}Interactive Commands Configured:${NC}"
echo -e "  ${C12}•${NC} ${YELLOW}/scaffold-seller${NC}  ${DIM}→ Scaffold paid Express/Hono/Next.js API route${NC}"
echo -e "  ${C12}•${NC} ${YELLOW}/scaffold-buyer${NC}   ${DIM}→ Scaffold autonomous paying client${NC}"
echo -e "  ${C12}•${NC} ${YELLOW}/audit-routes${NC}     ${DIM}→ Audit routes against compliance & security rules${NC}"
echo ""
echo -e "${GRAY}Powered by the x402 Protocol & Solana Developer Network${NC}"
echo ""
