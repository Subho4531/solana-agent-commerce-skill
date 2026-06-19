# Agent Commerce & Build Workflows

This document outlines the workflows and flowcharts illustrating how developer agents utilize the **Solana Agent Commerce Skill** to build paid integrations, and how autonomous runtime agents utilize the resulting protocol to transact safely on Solana.

---

## 1. Build-Time: AI Developer Agent Workflow

This flowchart illustrates how an AI agent (e.g., your coding assistant, `x402-builder`, or `x402-architect`) utilizes this skill's progressive loading architecture to build and audit new features.

```mermaid
graph TD
    A["User Request<br/>(e.g., 'Gate this API' or 'Add buy capability')"] --> B["1. Intent Discovery<br/>(Scan SKILL.md Frontmatter)"]
    B --> C["2. Route Selection<br/>(Check SKILL.md Routing Matrix)"]
    
    C --> D{"Select Task Type"}
    D -- "Gate API Route" --> E["Load references/x402-server-patterns.md"]
    D -- "Setup Buyer Agent" --> F["Load references/x402-client-patterns.md"]
    D -- "Monetize MCP Tools" --> G["Load references/x402-mcp-monetization.md"]
    D -- "Solana Wallet / Signers" --> H["Load references/x402-solana-integration.md"]
    
    E & F & G & H --> I["3. Code Generation<br/>(Use 2026 stack & opinionated defaults)"]
    I --> J["4. Security Auditing<br/>(Apply rules/x402-security-rules.md)"]
    J --> K["5. Verification<br/>(Run commands/test-devnet.md)"]
    K --> L["Production Ready Code"]
```

---

## 2. Runtime: Autonomous Agent-to-Agent Commerce Workflow

This flowchart illustrates the step-by-step runtime interaction of an autonomous **Orchestrator Agent (Buyer)** calling a **Worker Agent (Seller)** gated by the x402 protocol, incorporating local safety checks and liquidity swaps.

```mermaid
sequenceDiagram
    autonumber
    actor User as User / Scheduler
    participant Buyer as Orchestrator Agent (Buyer)
    participant Jup as Jupiter Swap API
    participant Seller as Worker Agent (Seller)
    participant Solana as Solana Ledger (Mainnet/Devnet)

    User->>Buyer: Trigger task requiring specialized data/tool
    Buyer->>Seller: GET /api/v1/resource (Initial call, no payment)
    Note over Seller: Gated by @x402 Hono/Express Middleware
    Seller-->>Buyer: HTTP 402 Payment Required (Challenge details: payTo, network, amount, asset)
    
    Note over Buyer: Intercepted by @x402/fetch wrapper
    
    rect rgb(240, 240, 240)
        Note over Buyer: Enforce Local Spend Policy (x402-security.md)
        Buyer->>Buyer: Check Domain Allowlist & Spend Caps
        alt Policy Violated
            Buyer-->>User: Abort task (Notify spend policy breach)
        end
    end

    rect rgb(240, 248, 255)
        Note over Buyer: Balance & Liquidity Verification
        Buyer->>Buyer: Check USDC Wallet Balance
        alt USDC Balance < Required Amount
            Buyer->>Jup: Get swap quote (SOL -> USDC)
            Jup-->>Buyer: Swap Route / Transaction
            Buyer->>Solana: Execute Swap (Atomic Swap to USDC)
            Solana-->>Buyer: Transaction confirmed (Balance funded)
        end
    end

    rect rgb(255, 240, 245)
        Note over Buyer: Payment Resolution
        Buyer->>Solana: Transfer USDC (ExactSvmScheme)
        Solana-->>Buyer: Return Transaction Signature (TxID)
        Buyer->>Buyer: Construct x402 header (Signature, Payee, Mint)
    end

    Buyer->>Seller: GET /api/v1/resource (Retry with x402 Payment Header + Idempotency-Key)
    
    rect rgb(240, 255, 240)
        Note over Seller: Verify & Settle Transaction
        Seller->>Solana: Verify payment (TxID matches payee, amount, asset & is confirmed)
        Solana-->>Seller: Verified
        Seller->>Seller: Log payment receipt
    end
    
    Seller-->>Buyer: HTTP 200 OK (With Resource Data & PAYMENT-RESPONSE Receipt Header)
    Buyer->>Buyer: Log Receipt (For reconciliation/audits)
    Buyer-->>User: Task completed successfully
```

---

## 3. Best Practices for Implementing Workflows

When implementing these workflows in your application:

1. **Keep Signers Safe**: Never expose private keys directly to LLMs. Use `@x402/fetch` which encapsulates private key signing inside a closed JS closure.
2. **Enforce Daily Budgets**: Implement hard limits in your agent code to prevent "runaway agent loops" from draining the wallet.
3. **Idempotency is Mandatory**: Always supply unique UUIDs in the `Idempotency-Key` headers on client calls and verify them on the server to prevent double-charging on network retries.
4. **Devnet First**: Always test with the public facilitator on Devnet using `solana:EtWTRABZaYq6iMfeYKouRu166VU2xqa1` and Devnet USDC before deploying to Mainnet.
