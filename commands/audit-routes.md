---
name: audit-routes
description: Instructs the system to invoke the x402-auditor agent to review the codebase for security flaws, missing idempotency keys, incorrect x402 configurations, and hardcoded secrets.
---

# /audit-routes

This command triggers a comprehensive security audit of your x402 integration.

## Execution Steps

1.  **Invoke Auditor**: The system MUST assume the persona of the `x402-auditor` agent (defined in `agents/x402-auditor.md`).
2.  **Scan Scope**: Identify all server-side routes using `paymentMiddleware`, `PAYMENT-REQUIRED`, `X-PAYMENT`, `PAYMENT-RESPONSE`, facilitator URLs, and client-side code using `@x402/fetch`, `@x402/svm`, `wrapFetchWithPayment`, or `wrapFetchWithPaymentFromConfig`.
3.  **Review against Rules**: Systematically check the code against every rule in `rules/x402-security-rules.md`.
4.  **Generate Report**: Output a structured audit report using the template below.

## Audit Report Template

```markdown
# x402 Security Audit Report

**Date:** YYYY-MM-DD
**Scope:** [List of files reviewed]

## 🚨 Critical Findings
*(Bugs that lead to loss of funds, double-spending, or total failure)*
- **[File Name]**: [Description of vulnerability]. 
  - **Recommendation**: [Code snippet showing the fix]

## ⚠️ Warnings
*(Poor practices that reduce reliability or security, e.g., missing idempotency, hardcoded devnet RPCs)*
- **[File Name]**: [Description of issue].
  - **Recommendation**: [Code snippet showing the fix]

## ✅ Passed Checks
- [x] Rule 1.1: No plaintext private keys found.
- [x] Rule 2.1: Client spend caps are configured.
- [ ] ... (List checked rules)
```

## Required Modernization Checks

- [ ] No v2 code uses `solana:mainnet`; use CAIP-2 IDs.
- [ ] No buyer examples use raw `@solana/web3.js` `Keypair` directly with `ExactSvmScheme`.
- [ ] No generated code uses fake `.pay()` or `verifySvmTransfer` helpers unless the installed package exports them.
- [ ] Mutating paid routes require `Idempotency-Key`.
- [ ] Successful paid responses log `PAYMENT-RESPONSE`.
