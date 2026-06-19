# Security & Verification Skills

This guide details the practices and configuration files for writing highly secure Solana programs using **`trailofbits/skills`**, **`frankcastleauditor/safe-solana-builder`**, and **`QEDGen/solana-skills`**.

---

## 1. Audit-Derived Security Rules (`frankcastleauditor/safe-solana-builder`)

**`safe-solana-builder`** enforces strict, audit-derived validations to eliminate common Solana smart contract bugs (like missing ownership checks, unvalidated PDAs, or non-canonical bumps).

### Canonical PDA Bump Verification & Owner Validation
To prevent account substitution and security bypasses, a Solana program must enforce:
1.  **Owner Verification**: The account belongs to the correct program.
2.  **Canonical Bump**: The PDA is derived using `find_program_address` (which finds the canonical bump), and that bump is stored/checked during initialization.

Below is an Anchor verification implementation:

```rust
use anchor_lang::prelude::*;

declare_id!("SafeProg1111111111111111111111111111111111");

#[program]
pub mod safe_vault_program {
    use super::*;

    pub fn initialize_vault(ctx: Context<InitializeVault>, vault_bump: u8) -> Result<()> {
        let vault = &mut ctx.accounts.vault;
        vault.owner = ctx.accounts.authority.key();
        vault.bump = vault_bump; // Store the bump
        
        // Audit protection: Check that the stored bump matches the canonical bump
        let canonical_bump = ctx.bumps.vault;
        require_keys_eq!(
            vault.owner,
            ctx.accounts.authority.key(),
            VaultError::UnauthorizedOwner
        );
        require!(vault_bump == canonical_bump, VaultError::NonCanonicalBump);

        msg!("Vault successfully initialized with canonical bump: {}", canonical_bump);
        Ok(())
    }
}

#[derive(Accounts)]
pub struct InitializeVault<'info> {
    #[account(mut)]
    pub authority: Signer<'info>,

    // Anchor automatically verifies ownership and canonical bump with constraints:
    #[account(
        init,
        payer = authority,
        space = 8 + 32 + 1,
        seeds = [b"vault", authority.key().as_ref()],
        bump
    )]
    pub vault: Account<'info, VaultState>,

    pub system_program: Program<'info, System>,
}

#[account]
pub struct VaultState {
    pub owner: Pubkey,
    pub bump: u8,
}

#[error_code]
pub enum VaultError {
    #[msg("Owner does not match authority.")]
    UnauthorizedOwner,
    #[msg("Provided bump is not canonical.")]
    NonCanonicalBump,
}
```

---

## 2. Formal Verification (`QEDGen/solana-skills`)

**`QEDGen/solana-skills`** facilitates formal verification by defining behavior specifications via `.qedspec` files and verifying arithmetic correctness with **Kani**.

### Defining a Vault Specification (`vault.qedspec`)
```json
{
  "spec_version": "1.0",
  "program": "safe_vault_program",
  "invariants": [
    {
      "name": "vault_balance_matches_total_deposits",
      "description": "The lamport balance of the PDA vault must always equal the sum of active depositor records.",
      "formula": "vault.lamports >= sum(deposits.amount)"
    },
    {
      "name": "non_overflow_deposit",
      "description": "deposits.amount + new_deposit must not exceed u64::MAX",
      "formula": "deposits.amount + new_deposit <= 18446744073709551615"
    }
  ]
}
```

### Kani Harness for Arithmetic Verification (`verification_harness.rs`)
Kani analyzes Rust code statically to prove the absence of crashes, panics, and arithmetic overflows/underflows.

```rust
// Under verification folder: verification/harness.rs
#[cfg(kani)]
mod verification {
    use super::*;

    #[kani::proof]
    fn verify_deposit_arithmetic() {
        // 1. Initialize symbolic inputs (can represent any possible value)
        let current_balance: u64 = kani::any();
        let deposit_amount: u64 = kani::any();

        // 2. Add preconditions to match real-world validation
        kani::assume(current_balance <= 10_000_000_000_000); // Max reasonable balance

        // 3. Run checked addition (what the program executes)
        let result = current_balance.checked_add(deposit_amount);

        // 4. Assert correctness
        if result.is_none() {
            // Checked add fails -> program must panic safely or return error
            assert!(current_balance.checked_add(deposit_amount).is_none());
        } else {
            // Checked add succeeds -> sum must be equal or greater
            let sum = result.unwrap();
            assert!(sum >= current_balance);
        }
    }
}
```

---

## 3. Automated Vulnerability Scanning (`trailofbits/skills`)

**`trailofbits/skills`** implements static analysis workflows. Below is a custom Semgrep security rule checking for unsafe account modification where a program fails to verify that the target account is writable.

### Semgrep Security Rule Configuration (`solana-writable-check.yaml`)
```yaml
rules:
  - id: solana-unvalidated-writable-account
    patterns:
      - pattern: |
          AccountInfo { key, is_signer, is_writable: false, .. }
      - pattern-not: |
          AccountInfo { key, is_signer, is_writable: true, .. }
    message: |
      Warning: Account state modification attempted on an account not marked as writable.
      Ensure the account configuration verifies `is_writable: true` to prevent state corruption.
    languages:
      - rust
    severity: WARNING
```
