# x402 Facilitators & Verification Networks

Facilitators verify and settle x402 payment payloads so every seller does not need to implement Solana transaction verification by hand.

## 1. Flow

```text
Client -> Server: request protected resource
Server -> Client: 402 payment requirements
Client -> Facilitator/Solana path: create signed payment payload
Client -> Server: retry original request with x402 payment header
Server -> Facilitator: verify/settle payment
Server -> Client: resource + PAYMENT-RESPONSE receipt
```

For Solana, use the `exact` scheme via `@x402/svm`. The facilitator/server implementation should verify the same requirement the server issued: network, asset, payee, amount, route, method, and expiry.

## 2. Hosted facilitator

Use the hosted facilitator URL configured by the current x402 docs or your deployment. This repo has historically used both:

- `https://x402.org/facilitator`
- `https://api.x402.org`

Before generating production code, verify the intended facilitator URL from the installed SDK or official deployment docs and keep it in one environment variable:

```env
X402_FACILITATOR_URL=https://x402.org/facilitator
X402_FACILITATOR_API_KEY=
```

Server middleware should read from `process.env.X402_FACILITATOR_URL` instead of hardcoding a URL.

## 3. Self-hosted facilitator

For production volume or stricter control, self-host the facilitator components supported by the currently installed `@x402/svm` package. Prefer package exports such as `@x402/svm/exact/facilitator` over undocumented package names.

Self-hosting checklist:

- private Solana RPC
- isolated facilitator signer / fee payer
- short settlement cache TTL
- duplicate settlement protection
- structured logs for payment payloads and settlement receipts
- rate limits per seller route
- alerting on failed settlement or unexpected asset/payee

Do not claim sub-50ms settlement or verification unless you have measured it in the target deployment.
