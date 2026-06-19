#!/usr/bin/env bash

# Solana Agent Commerce Skill - Standard Installer

set -e

# Base formatting
NC='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
UNDERLINE='\033[4m'

# Basic colors for standard text
RED='\033[38;5;196m'
GREEN='\033[38;5;46m'
YELLOW='\033[38;5;226m'
BLUE='\033[38;5;33m'
CYAN='\033[38;5;51m'
WHITE='\033[38;5;231m'
GRAY='\033[38;5;244m'

# Solana True Color Gradients (Purple to Teal)
C1='\033[38;2;153;69;255m'
C2='\033[38;2;147;77;250m'
C3='\033[38;2;141;85;245m'
C4='\033[38;2;135;92;241m'
C5='\033[38;2;129;100;236m'
C6='\033[38;2;123;108;231m'
C7='\033[38;2;117;116;226m'
C8='\033[38;2;111;124;221m'
C9='\033[38;2;105;131;217m'
C10='\033[38;2;99;139;212m'
C11='\033[38;2;93;147;207m'
C12='\033[38;2;87;155;202m'
C13='\033[38;2;81;163;197m'
C14='\033[38;2;75;171;193m'
C15='\033[38;2;69;178;188m'
C16='\033[38;2;62;186;183m'
C17='\033[38;2;56;194;178m'
C18='\033[38;2;50;202;173m'
C19='\033[38;2;44;210;169m'
C20='\033[38;2;38;218;164m'
C21='\033[38;2;32;225;159m'
C22='\033[38;2;26;233;154m'
C23='\033[38;2;20;241;149m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Target paths
SKILL_DIR_NAME="solana-agent-commerce"
TARGET_SKILL_DIR="${HOME}/.claude/skills/${SKILL_DIR_NAME}"
TARGET_AGENTS_DIR="${HOME}/.agents"
TARGET_RULES_DIR="${HOME}/.claude/rules"

INSTALL_AGENTS=false
INSTALL_RULES=false

print_banner() {
    echo ""
    echo -e "${C1}╔══════════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${C2}║                                                                                                  ║${NC}"
    echo -e "${C3}║   ███████╗ ██████╗ ██╗      █████╗ ███╗   ██╗█████╗   █████╗  ██████╗ ███████╗███╗   ██╗████████╗║${NC}"
    echo -e "${C4}║   ██╔════╝██╔═══██╗██║     ██╔══██╗████╗  ██║██╔══██╗ ██╔══██╗██╔════╝ ██╔════╝████╗  ██║╚══██╔══╝║${NC}"
    echo -e "${C5}║   ███████╗██║   ██║██║     ███████║██╔██╗ ██║███████║ ███████║██║  ███╗█████╗  ██╔██╗ ██║   ██║   ║${NC}"
    echo -e "${C6}║   ╚════██║██║   ██║██║     ██╔══██║██║╚██╗██║██╔══██║ ██╔══██║██║   ██║██╔══╝  ██║╚██╗██║   ██║   ║${NC}"
    echo -e "${C7}║   ███████║╚██████╔╝███████╗██║  ██║██║ ╚████║██║  ██║ ██║  ██║╚██████╔╝███████╗██║ ╚████║   ██║   ║${NC}"
    echo -e "${C8}║   ╚══════╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═══╝   ╚═╝   ║${NC}"
    echo -e "${C9}║                                                                                                  ║${NC}"
    echo -e "${C10}║                            ███████╗██╗  ██╗██╗██╗     ██╗     ███████╗                            ║${NC}"
    echo -e "${C11}║                            ██╔════╝██║ ██╔╝██║██║     ██║     ██╔════╝                            ║${NC}"
    echo -e "${C12}║                            ███████╗█████╔╝ ██║██║     ██║     ███████╗                            ║${NC}"
    echo -e "${C13}║                            ╚════██║██╔═██╗ ██║██║     ██║     ╚════██║                            ║${NC}"
    echo -e "${C14}║                            ███████║██║  ██╗██║███████╗███████╗███████║                            ║${NC}"
    echo -e "${C15}║                            ╚══════╝╚═╝  ╚═╝╚═╝╚══════╝╚══════╝╚══════╝                            ║${NC}"
    echo -e "${C16}║                                                                                                  ║${NC}"
    echo -e "${C17}║                             ${WHITE}${BOLD}Solana Agent Commerce Skill for AI Agents${NC}${C17}                            ║${NC}"
    echo -e "${C18}║                                                                                                  ║${NC}"
    echo -e "${C19}║   ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄   ║${NC}"
    echo -e "${C20}║                                     ${WHITE}${BOLD}Powered by x402 Protocol${NC}${C20}                                     ║${NC}"
    echo -e "${C21}║   ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀   ║${NC}"
    echo -e "${C22}║                                                                                                  ║${NC}"
    echo -e "${C23}╚══════════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_help() {
    echo -e "${C14}${BOLD}Solana Agent Commerce Skill - Interactive Installer${NC}"
    echo ""
    echo -e "${GRAY}Usage:${NC} ./install.sh [OPTIONS]"
    echo ""
    echo -e "${GRAY}Installs with recommended defaults:${NC}"
    echo -e "  ${C13}•${NC} Location: ~/.claude/skills/"
    echo -e "  ${C13}•${NC} Installs the solana-agent-commerce skill"
    echo ""
    echo -e "${GRAY}Options:${NC}"
    echo -e "  ${YELLOW}--agents${NC}       Install specialized agents (x402-architect, etc.)"
    echo -e "  ${YELLOW}--rules${NC}        Install x402 security rules"
    echo -e "  ${YELLOW}-y, --yes${NC}      Skip confirmation prompt"
    echo -e "  ${YELLOW}-h, --help${NC}     Show this help"
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
    -y|--yes)
      SKIP_CONFIRM=true
      shift
      ;;
    -h|--help)
      print_help
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      echo -e "Use ${YELLOW}--help${NC} for usage information"
      exit 1
      ;;
  esac
done

print_banner

echo -e "${WHITE}${BOLD}🚀 Starting Standard Installation${NC}"
echo ""
echo -e "${GRAY}This will install:${NC}"
echo -e "  ${CYAN}📦${NC} solana-agent-commerce  → ${UNDERLINE}$TARGET_SKILL_DIR${NC}"
if [ "$INSTALL_AGENTS" = true ]; then
echo -e "  ${CYAN}🤖${NC} Specialized Agents     → ${UNDERLINE}$TARGET_AGENTS_DIR${NC}"
fi
if [ "$INSTALL_RULES" = true ]; then
echo -e "  ${CYAN}🛡️ ${NC} x402 Security Rules    → ${UNDERLINE}$TARGET_RULES_DIR${NC}"
fi
echo ""

if [ "$SKIP_CONFIRM" = false ]; then
    echo -ne "${C11}▶${NC} Proceed with installation? [Y/n] "
    read -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo -e "\n${YELLOW}⛔ Installation cancelled. Have a great day!${NC}"
        exit 0
    fi
fi

echo ""

echo -e "${C11}[1/1]${NC} ${BOLD}Installing solana-agent-commerce...${NC}"

# Create target directories if they don't exist
mkdir -p "${TARGET_SKILL_DIR}"
mkdir -p "${TARGET_SKILL_DIR}/references"

# Copy Skill Hub and Reference manuals
cp -r "$SCRIPT_DIR/skill/SKILL.md" "${TARGET_SKILL_DIR}/"
cp -r "$SCRIPT_DIR/skill/references/"* "${TARGET_SKILL_DIR}/references/"
echo -e "  ${GREEN}✓${NC} Installed skill hub and references"

# Install Agents if requested
if [ "$INSTALL_AGENTS" = true ]; then
  echo -e "${C14}[+]${NC} ${BOLD}Installing specialized agents...${NC}"
  mkdir -p "${TARGET_AGENTS_DIR}"
  cp -r "$SCRIPT_DIR/agents/"* "${TARGET_AGENTS_DIR}/"
  echo -e "  ${GREEN}✓${NC} Installed system agents"
fi

# Install Rules if requested
if [ "$INSTALL_RULES" = true ]; then
  echo -e "${C17}[+]${NC} ${BOLD}Installing developer rules...${NC}"
  mkdir -p "${TARGET_RULES_DIR}"
  cp -r "$SCRIPT_DIR/rules/"* "${TARGET_RULES_DIR}/"
  echo -e "  ${GREEN}✓${NC} Installed developer rules"
fi

# Done
echo ""
echo -e "${C23}╔══════════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${C23}║${NC}  ${WHITE}${BOLD}🎉 Installation Complete!${NC}                                                                       ${C23}║${NC}"
echo -e "${C23}╚══════════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${WHITE}${BOLD}Ready to go! What's next?${NC}"
echo -e "  ${C13}•${NC} ${YELLOW}/scaffold-seller${NC} ${DIM}→ Create a paid API endpoint${NC}"
echo -e "  ${C13}•${NC} ${YELLOW}/scaffold-buyer${NC}  ${DIM}→ Create an autonomous client${NC}"
echo -e "  ${C13}•${NC} ${YELLOW}/audit-routes${NC}    ${DIM}→ Review my integration for security flaws${NC}"
echo ""
echo -e "${C1}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${C10}                     Powered by x402 Protocol & Solana Agent Kit${NC}"
echo -e "${C23}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
