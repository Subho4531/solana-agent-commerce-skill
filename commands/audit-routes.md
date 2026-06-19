---
name: audit-routes
description: Reads the user's existing x402 route configuration files and audits them against the strict rules defined in skill/security.md. Outputs a pass/fail report for quote expiry, route binding, idempotency, and spend caps.
---

# /audit-routes

This command acts as an automated security reviewer for x402 implementations.

## Execution Steps

1.  **Analyze the Codebase:**
    *   Search the user's workspace for files importing `@x402/express`, `@x402/hono`, `@x402/next`, or `@x402/fetch`.
    *   Read the contents of those configuration files.

2.  **Audit Seller Routes (API Endpoints):**
    *   **Pass/Fail**: Does the `paymentMiddleware` config include `maxAgeSeconds`?
    *   **Pass/Fail**: Is the `resource` string highly specific (includes payee wallet)?
    *   **Pass/Fail**: Is there an idempotency check (`x-payment-id`) before performing expensive work?
    *   **Pass/Fail**: Are private keys loaded from env vars?

3.  **Audit Buyer Agents (Fetch clients):**
    *   **Pass/Fail**: Is there a spend policy defined in the `onPaymentRequired` hook?
    *   **Pass/Fail**: Does it check `maxAmountRequired` against a per-request cap?
    *   **Pass/Fail**: Are private keys strictly loaded from env vars or KMS?

4.  **Report Generation:**
    *   Output a markdown checklist of the findings.
    *   For any failures, provide the specific code snippet required to fix it, referencing `skill/security.md`.
