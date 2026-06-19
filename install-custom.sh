#!/bin/bash

# Solana Agent Commerce Skill - Convenience Installer

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INSTALL_ARGS=()

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --agents)
            INSTALL_ARGS+=("--agents")
            ;;
        --rules)
            INSTALL_ARGS+=("--rules")
            ;;
        --commands)
            INSTALL_ARGS+=("--commands")
            ;;
        --all)
            INSTALL_ARGS+=("--agents" "--rules" "--commands")
            ;;
        --target)
            INSTALL_ARGS+=("--target" "$2")
            shift
            ;;
        -y|--yes)
            INSTALL_ARGS+=("--yes")
            ;;
        -h|--help)
            echo "Usage: ./install-custom.sh [OPTIONS]"
            echo "Options:"
            echo "  --agents          Install specialized x402 agents"
            echo "  --rules           Install x402 security rules"
            echo "  --commands        Install command prompts"
            echo "  --all             Install agents, rules, and commands"
            echo "  --target codex    Install to Codex locations (default)"
            echo "  --target claude   Install to Claude locations"
            echo "  -y, --yes         Skip confirmation prompt"
            exit 0
            ;;
        *)
            echo "Unknown parameter passed: $1"
            exit 1
            ;;
    esac
    shift
done

echo -e "${CYAN}Running installation...${NC}"
"$SCRIPT_DIR/install.sh" "${INSTALL_ARGS[@]}"

echo -e "\n${GREEN}✓ Custom installation complete!${NC}\n"
