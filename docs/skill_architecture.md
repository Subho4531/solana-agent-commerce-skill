# Skill Architecture & Content Plan

This document describes the structure of the `solana-x402-skill` repository and our progressive loading architecture matching the `solana-game-skill` reference.

---

## 1. Directory Structure

```
solana-x402-skill/
├── README.md                          # Project overview, requirements, and installation
├── LICENSE                            # MIT License
├── install.sh                         # Shell installation script
├── skill/
│   ├── SKILL.md                       # Main hub & routing entrypoint
│   └── references/
│       ├── x402-server-patterns.md    # Express, Hono, and Next.js middleware setups
│       ├── x402-client-patterns.md    # Fetch/Axios wrappers, wallet setups, spending caps
│       ├── x402-solana-integration.md # USDC SPL Token, ExactSvmScheme, private keys
│       ├── x402-facilitator.md        # Hosted/Self-hosted verification networks
│       ├── x402-agent-kit.md          # Solana Agent Kit, LangChain, budget controls
│       ├── x402-mcp-monetization.md   # Wrapping and monetizing MCP servers
│       ├── x402-security.md           # Spending limits, key vaulting, compliance
│       └── x402-testing.md            # Mocks, local testing, devnet configuration
├── agents/
│   ├── x402-architect.md              # System design and integration patterns agent
│   └── x402-builder.md                # Node.js/TypeScript developer agent
├── commands/
│   └── x402-scaffold.md               # Scaffolding helper script
└── rules/
    └── x402-security-rules.md         # Custom developer rules for safe x402 operations
```

---

## 2. Progressive Loading Strategy

To ensure token efficiency, the skill loads context in a 3-layer cascade:

* **Layer 1: Metadata Scan** (~50 tokens):
  The agent scans the YAML frontmatter of `SKILL.md` to see if the user's intent matches `x402`, `HTTP 402`, `micropayments`, or `agent monetization`.
* **Layer 2: Hub Read** (~300 tokens):
  Once activated, the agent reads `SKILL.md`. This file contains the stack decisions and a routing table pointing to the `references/` directory.
* **Layer 3: Reference Load** (~300-500 tokens):
  The agent only loads the specific file under `references/` matching the user's immediate question, avoiding unnecessary token bloat.

---

## 3. Sub-Skill Routing Matrix

| Intent / Task | Target Reference | Agent |
| :--- | :--- | :--- |
| Gate API routes, set up Hono/Express. | `references/x402-server-patterns.md` | `x402-builder` |
| Make client calls, wrap fetch/axios. | `references/x402-client-patterns.md` | `x402-builder` |
| Wire up Solana wallets & USDC SPL mints. | `references/x402-solana-integration.md` | `x402-builder` |
| Configure payment verification facilitators. | `references/x402-facilitator.md` | `x402-architect` |
| Hook into Solana Agent Kit or LangChain. | `references/x402-agent-kit.md` | `x402-architect` |
| Monetize custom MCP servers via 402. | `references/x402-mcp-monetization.md` | `x402-builder` |
| Implement KMS key storage & spending caps. | `references/x402-security.md` | `x402-architect` |
| Mock facilitator responses, test devnet. | `references/x402-testing.md` | `x402-builder` |

---

## 4. Install Script Mechanics

The `install.sh` script copies the skill files directly to the target environment's `.claude/skills/solana-x402-skill` folder.

```bash
# Direct install flow
git clone https://github.com/solanabr/solana-x402-skill
cd solana-x402-skill
./install.sh
```

Flags supported:
* `--agents`: Also installs `x402-architect` and `x402-builder` to `.agents/`.
* `--rules`: Copies `x402-security-rules.md` to the target `.claude/rules/` directory.
