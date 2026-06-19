#!/bin/bash

# Solana Agent Commerce Skill - Custom Installer

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INSTALL_AGENTS=false
INSTALL_RULES=false
INSTALL_ALL=false

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --agents) INSTALL_AGENTS=true ;;
        --rules) INSTALL_RULES=true ;;
        --all) INSTALL_ALL=true ;;
        -h|--help)
            echo "Usage: ./install-custom.sh [OPTIONS]"
            echo "Options:"
            echo "  --agents    Install specialized x402 agents to .agents/"
            echo "  --rules     Install x402 security rules to .claude/rules/"
            echo "  --all       Install everything (agents and rules)"
            exit 0
            ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [ "$INSTALL_ALL" = true ]; then
    INSTALL_AGENTS=true
    INSTALL_RULES=true
fi

# Run base install
echo -e "${CYAN}Running base installation...${NC}"
"$SCRIPT_DIR/install.sh"

# Install Agents
if [ "$INSTALL_AGENTS" = true ]; then
    echo -e "${CYAN}Installing specialized agents...${NC}"
    mkdir -p "$SCRIPT_DIR/.agents"
    cp -r "$SCRIPT_DIR/agents/"* "$SCRIPT_DIR/.agents/"
    echo -e "${GREEN}✓ Agents installed to .agents/${NC}"
fi

# Install Rules
if [ "$INSTALL_RULES" = true ]; then
    echo -e "${CYAN}Installing security rules...${NC}"
    mkdir -p "$HOME/.claude/rules"
    # Create a basic rule file redirecting to the skill's security doc
    cat > "$HOME/.claude/rules/x402-security-rules.md" << EOL
# x402 Security Rules
Always adhere to the security rules defined in the solana-agent-commerce skill:
Refer to ~/.claude/skills/solana-agent-commerce/security.md for strict guidelines on:
- Spend caps
- Stale quotes
- Route binding
EOL
    echo -e "${GREEN}✓ Rules installed to ~/.claude/rules/${NC}"
fi

echo -e "\n${GREEN}✓ Custom installation complete!${NC}\n"
