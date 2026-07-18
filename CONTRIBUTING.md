# 🤝 Contributing to E-OS

Thanks for your interest in **E-OS**! Contributions of all kinds are welcome —
code, docs, design, testing, and ideas.

> 📌 **First, the essentials:** read the **[Code of Conduct](CODE_OF_CONDUCT.md)**
> and, for vulnerabilities, the **[Security Policy](SECURITY.md)** (never file
> security bugs in public). New here? Start with
> **[docs/getting-started.md](docs/getting-started.md)**.
>
> 🧭 **Standards & Definition of Done:** **[CLAUDE.md](CLAUDE.md)** is the working
> agreement for everyone (humans and AI assistants) — the three verification gates,
> what "done" means, and the rule that every change updates the docs it affects.

## Ways to contribute

- 🐛 **Report bugs** / 💡 **request features** via the issue templates.
- 📝 **Improve docs** under `docs/` (or this file).
- 🎨 **Design** — wallpapers, icons, themes in the E-OS red/black identity.
- 🔧 **Code** — fixes, the curated `eos.toml`, branding, tooling, hardening.
- 🧪 **Test** — build & boot on different hardware/QEMU and report results.

## Development setup

See **[docs/getting-started.md](docs/getting-started.md)** and
**[docs/building.md](docs/building.md)**. The one rule to remember:

```bash
make CI=1 all   # CI=1 is required for non-interactive builds
make qemu       # boot it
```

## Workflow

1. **Fork** and create a topic branch off `main`
   (`git switch -c feat/my-change`).
2. Make focused changes. Keep PRs **small** — they're reviewed faster.
3. **Sign your commits** (`git commit -S`) where possible — see
   [docs/security.md](docs/security.md).
4. Update **[CHANGELOG.md](CHANGELOG.md)** (numbered entry) for user-facing
   changes, and **[ROADMAP.md](ROADMAP.md)** if relevant.
5. Run `rustfmt` on Rust changes; keep CI green.
6. Open a **Pull Request** using the template and link any issue/roadmap item.

### Commit style

Short, imperative subject; explain *why* in the body. Conventional prefixes are
appreciated (`feat:`, `fix:`, `docs:`, `ci:`, `security:`).

## Contribution terms (DCO + license)

By contributing you agree that:

- You wrote the change or have the right to submit it, under the
  [Developer Certificate of Origin](https://developercertificate.org/).
- Your contribution is licensed under **AGPL-3.0-or-later** (the project
  license). Inherited Redox files keep their original MIT notices — see
  [NOTICE](NOTICE).

### AI-assisted contributions

AI-assisted work **is allowed** in E-OS. If you use AI tooling, **you** remain
responsible for the result: understand the change, test it, ensure it's correct,
and confirm it's compatible with AGPL-3.0. Don't paste secrets into prompts.

> ⚠️ Note: this differs from **upstream Redox**, which does **not** accept
> LLM-generated contributions. If you're contributing *to Redox itself*, follow
> [their policy](docs/REDOX-CONTRIBUTING.md), not this one.

## Deep OS / upstream work

E-OS re-bases on upstream Redox rather than forking the kernel. For substantial
kernel/driver/relibc work, the right home is often **upstream Redox** — their
contributor guide (preserved here as
[docs/REDOX-CONTRIBUTING.md](docs/REDOX-CONTRIBUTING.md)) and the
[Redox Book](https://doc.redox-os.org/book/) are excellent references. Upstreaming
benefits both projects — and E-OS inherits it on the next re-base. 🙏

## Questions?

Open a [discussion or issue](https://github.com/Gh0s777tt/E-OS/issues), or read
the **[FAQ](docs/faq.md)**.
