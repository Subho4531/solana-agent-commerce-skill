# Monetizing MCP Servers with HTTP 402

Use this reference when placing an x402-paid HTTP gateway in front of MCP tools.

## 1. Gateway pattern

Gate the HTTP transport layer, not the local stdio server directly.

```text
Agent MCP Client -> x402 HTTP Gateway -> MCP Server
                  <- 402 challenge
Agent pays with @x402/fetch
Agent retries call -> gateway forwards JSON-RPC/tool call
```

Prefer streamable HTTP transports when available. SSE examples are acceptable only when the target MCP server/client stack still uses SSE.

## 2. Gating tool calls

```typescript
import { Hono } from "hono";
import { paymentMiddleware } from "@x402/hono";
import { ExactSvmScheme } from "@x402/svm";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { SSEClientTransport } from "@modelcontextprotocol/sdk/client/sse.js";

const app = new Hono();

const priceByTool: Record<string, string> = {
  "summarize": "10000", // 0.01 USDC if middleware expects atomic units
  "research": "50000",
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

If pricing varies by tool, generate separate paid routes or choose the exact payment requirement after validating `body.name`. Never let the caller choose the price.

## 3. Consuming gated MCP gateways

The MCP HTTP/SSE transport must use the paid fetch implementation. If the transport constructor does not support a custom fetch function in your installed MCP SDK version, wrap the gateway behind a small client function that uses `paidFetch` directly.

```typescript
import { wrapFetchWithPayment } from "@x402/fetch";
import { createSvmClient } from "@x402/svm/client";
import { toClientSvmSigner } from "@x402/svm";

const client = createSvmClient({
  signer: toClientSvmSigner(mySolanaKitSigner),
  rpcUrl: process.env.SOLANA_RPC_URL,
});

const paidFetch = wrapFetchWithPayment(fetch, client);

const response = await paidFetch("https://mcp-gateway.provider.com/mcp/v1/tools/call", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    "Idempotency-Key": crypto.randomUUID(),
  },
  body: JSON.stringify({
    name: "summarize",
    arguments: { text: "..." },
  }),
});

const paymentReceipt = response.headers.get("PAYMENT-RESPONSE");
const result = await response.json();
```
