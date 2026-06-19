# x402 Scaffolding Commands

You can quickly scaffold client, server, or testing configurations for x402 on Solana.

---

## 1. Scaffolding a Server Setup

Use this command layout to generate a default, ready-to-run Express server gated by x402:

```bash
# Clone template files
npx degit solanabr/solana-agent-commerce-skill/templates/express-gated my-gated-api
cd my-gated-api
npm install
```

### Environment Configuration:
Ensure you create a `.env` file containing:
```env
PORT=8080
SOLANA_RPC_URL=https://api.mainnet-beta.solana.com
USDC_RECEIVER_ADDRESS=YOUR_WALLET_PUBLIC_KEY
```

---

## 2. Scaffolding a Client Setup

To quickly generate an agent fetch loop with built-in daily spending caps and wallet connections:

```bash
# Clone client template
npx degit solanabr/solana-agent-commerce-skill/templates/client-agent my-agent-client
cd my-agent-client
npm install
```

### Environment Configuration:
Ensure you create a `.env` file containing:
```env
AGENT_PRIVATE_KEY=[12,34,56,...] # Array of bytes
DAILY_SPENDING_LIMIT_USDC=5.00
PER_REQUEST_LIMIT_USDC=0.10
```
