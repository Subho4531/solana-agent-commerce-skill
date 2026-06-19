# Monetizing MCP Servers with HTTP 402

Use this reference to implement an x402-paid HTTP gateway in front of Model Context Protocol (MCP) servers, supporting per-tool pricing, streaming/chunk billing, batch call discounting, and capability advertisements.

---

## 1. Architecture Overview

To monetize MCP tools, gate the HTTP transport layer (SSE or custom HTTP routes) rather than gating the local stdio server directly.

```text
Agent MCP Client -> x402 HTTP Gateway -> MCP Server
                  <- 402 challenge
Agent pays with @x402/fetch
Agent retries call -> gateway forwards JSON-RPC/tool call
```

---

## 2. Gating Tool Calls

```typescript
import { Hono } from "hono";
import { paymentMiddleware } from "@x402/hono";
import { ExactSvmScheme } from "@x402/svm";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { SSEClientTransport } from "@modelcontextprotocol/sdk/client/sse.js";

const app = new Hono();

const priceByTool: Record<string, string> = {
  "summarize": "10000", // 0.01 USDC
  "research": "50000",  // 0.05 USDC
};

app.use(
  "/mcp/v1/tools/call",
  paymentMiddleware({
    accepts: [
      {
        scheme: ExactSvmScheme.scheme,
        network: process.env.X402_NETWORK ?? "solana:EtWTRABZaYq6iMfeYKouRu166VU2xqa1",
        maxAmountRequired: "50000",
        payTo: process.env.PAYEE_WALLET!,
        asset: process.env.USDC_MINT,
        maxAgeSeconds: 60,
      },
    ],
    description: "Paid access to MCP tool execution.",
  })
);

app.post("/mcp/v1/tools/call", async (c) => {
  const idempotencyKey = c.req.header("Idempotency-Key");
  if (!idempotencyKey) {
    return c.json({ error: "Idempotency-Key required" }, 428);
  }

  const body = await c.req.json();
  if (!Object.hasOwn(priceByTool, body.name)) {
    return c.json({ error: "Unknown or unpriced tool" }, 400);
  }

  const client = new Client({ name: "x402-gateway", version: "1.0.0" }, {});
  const transport = new SSEClientTransport(new URL("http://localhost:8080/sse"));
  await client.connect(transport);

  const result = await client.callTool({
    name: body.name,
    arguments: body.arguments,
  });

  return c.json(result);
});
```

---

## 3. Streaming Tool Call & Chunk Billing

For tools that stream long-running responses (e.g. detailed research summaries, code generation), charging a static fee upfront might undercharge or overcharge the client. Implement a stream-metering system that charges per SSE chunk or per-token returned.

```typescript
app.post("/mcp/v1/tools/call/stream", async (c) => {
  const body = await c.req.json();
  const baseFee = 5000n; // 0.005 USDC base fee
  
  // Set headers for server-sent events (SSE)
  c.header("Content-Type", "text/event-stream");
  c.header("Cache-Control", "no-cache");
  c.header("Connection", "keep-alive");

  // Fetch the tool stream from downstream MCP server
  // ... (Connect to MCP Server and acquire stream)
  
  return c.stream(async (stream) => {
    let tokensSent = 0;
    
    // Simulate reading chunks from MCP stream
    for (let i = 0; i < 5; i++) {
      const chunk = `data: { "text": "Research update ${i}...\\n" }\n\n`;
      await stream.write(chunk);
      tokensSent += 10;
      await stream.sleep(100);
    }
    
    // Compute final cost: Base fee + micro-lamports per token
    const tokenFee = BigInt(tokensSent) * 50n; // 50 atomic units per token
    const totalCost = baseFee + tokenFee;
    
    // Send final transaction billing info in the stream metadata
    await stream.write(`data: { "billing": { "totalCostAtomicUsdc": "${totalCost.toString()}" } }\n\n`);
  });
});
```

---

## 4. Batch Tool Call Pricing & Discounts

When an agent executes multiple tools simultaneously, you can reduce settlement overhead by allowing the client to send a batch request and offering a discount.

```typescript
interface BatchCallRequest {
  tools: Array<{ name: string; arguments: any }>;
}

app.post("/mcp/v1/tools/batch", async (c) => {
  const body = (await c.req.json()) as BatchCallRequest;
  
  // Calculate total gross cost
  let totalCostAtomic = 0n;
  for (const t of body.tools) {
    const toolCost = BigInt(priceByTool[t.name] || "0");
    totalCostAtomic += toolCost;
  }

  // Apply batch discount: 15% off for 3 or more tools
  if (body.tools.length >= 3) {
    totalCostAtomic = (totalCostAtomic * 85n) / 100n;
    console.log(`[Batch Discount] Applied 15% discount. New total: ${totalCostAtomic}`);
  }

  // Enforce x402 payment validation for the calculated totalCostAtomic
  // ... (Execute payment verification)
  
  // Execute all tools concurrently
  const client = new Client({ name: "x402-batch-gateway", version: "1.0.0" }, {});
  // ... (Connect to MCP, call tools in parallel via Promise.all)
  
  return c.json({ results: ["Batch results mock..."] });
});
```

---

## 5. Paid Tool Capability Advertisement

To ensure that autonomous planner agents understand the cost of a tool *before* invoking it, extend the MCP standard `listTools` schema. Add a custom `metadata` or `annotations` block containing payment details.

```typescript
app.get("/mcp/v1/tools/list", (c) => {
  return c.json({
    tools: [
      {
        name: "summarize",
        description: "Summarizes text documents. Premium service.",
        inputSchema: {
          type: "object",
          properties: {
            text: { type: "string" }
          },
          required: ["text"]
        },
        // Custom x402 monetization annotations
        monetization: {
          scheme: "exact",
          priceAtomicUsdc: "10000", // 0.01 USDC
          payee: process.env.PAYEE_WALLET!,
          network: "solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp"
        }
      },
      {
        name: "research",
        description: "Performs real-time search on Solana block data.",
        inputSchema: {
          type: "object",
          properties: {
            query: { type: "string" }
          },
          required: ["query"]
        },
        monetization: {
          scheme: "exact",
          priceAtomicUsdc: "50000", // 0.05 USDC
          payee: process.env.PAYEE_WALLET!,
          network: "solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp"
        }
      }
    ]
  });
});
```

---

## 6. Local Devnet Integration Testing

To test the monetized MCP gateway locally using Solana Devnet:

1. Deploy the gateway server using Devnet constants:
   - Network: `solana:EtWTRABZaYq6iMfeYKouRu166VU2xqa1`
   - USDC Mint: `4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU`
2. Bootstrap a test buyer wallet using the faucet helper script to acquire Devnet SOL and USDC.
3. Configure the buyer agent's MCP client wrapper to intercept tool requests, check the `monetization` metadata, verify its local spend policy allows the price, and execute the payment using `@x402/fetch` before forwarding.
