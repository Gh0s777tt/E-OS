# 🔐 Contributor Security Guide

This is the **practical** security guide for working *on* E-OS. To **report** a
vulnerability, see [`../SECURITY.md`](../SECURITY.md).

## Golden rules

1. **Never commit secrets.** No tokens, keys, passwords, `.pkgar` signing keys.
   CI runs **gitleaks** and GitHub **push protection** will block you.
2. **Sign your commits** (`git commit -S`). See below.
3. **Review dependencies.** Dependabot PRs are not auto-merged blindly.
4. **Least privilege** in code — request only the scheme handles you need.

## Signing commits

```bash
# one-time
git config --global user.signingkey <YOUR_KEY_ID>
git config --global commit.gpgsign true
# or SSH signing
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub
```

Signed commits get the **Verified** badge and are encouraged for all merges.

## If a secret leaks

1. **Revoke it immediately** at the provider (GitHub/GitLab/etc.).
2. Tell a maintainer (see `SECURITY.md`).
3. Do **not** try to rewrite history alone — coordinate; the secret is already
   compromised the moment it's pushed.

> 🧠 Note: GitHub/GitLab **secret scanning auto-revokes** many token types the
> instant they appear in a push or are pasted publicly. Treat any exposed token
> as dead and rotate it.

## Repository protections (maintainers)

| Control | Where | Status |
|---------|-------|--------|
| Secret scanning + push protection | GitHub repo settings | on |
| gitleaks CI | `.github/workflows/gitleaks.yml` | on |
| CodeQL code scanning | `.github/workflows/codeql.yml` | on |
| Dependabot | `.github/dependabot.yml` | on |
| Branch protection (no force-push, required review) | default branch | on |
| CODEOWNERS review | `.github/CODEOWNERS` | on |

## Threat model (summary)

E-OS's microkernel design shrinks the trusted computing base: a compromised
driver is a compromised **process**, not the kernel. The scheme model enables
capability-style confinement. Hardening the *distribution* (signed images, SBOM,
reproducible builds) is tracked under roadmap **v0.3.0 "Fortify"**.

## Why AGPL-3.0

Strong copyleft is an anti-appropriation control: anyone who ships or **serves** a
modified E-OS must release their source. It keeps the security benefits of the
code in the open. Inherited Redox code stays MIT; see [`../NOTICE`](../NOTICE).
