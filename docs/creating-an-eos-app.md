# Creating an E-OS app

The pattern every first-party E-OS GUI app follows, so a new one starts in minutes
instead of re-discovering the Redox/Slint plumbing. Reference implementations:
[`eos-notes`](https://gitlab.com/e-os/eos-notes) (notes, SQLite/WAL) and
[`eos-guard`](https://gitlab.com/e-os/eos-guard) (file-integrity monitor, blake3).

> **Why a shared pattern?** Modern GUI toolkits don't run on Redox out of the box.
> The [`eos-ui`](https://gitlab.com/e-os/eos-ui) crate solves it once — Slint's
> software renderer over `orbclient`, plus font bootstrap — and every app reuses it.
> See [ARCHITECTURE.md](../ARCHITECTURE.md) and
> [design-desktop-environment.md](design-desktop-environment.md).

## 1. Crate layout

```
eos-<app>/
├── Cargo.toml
├── build.rs                # slint_build::compile("ui/<app>.slint")
├── ui/<app>.slint          # the Slint UI
├── .gitlab-ci.yml          # fmt + host build (--no-default-features) + --selftest
├── README.md
└── src/
    ├── main.rs             # arg parse; `--selftest` branch; else gui::run()
    ├── core.rs             # the NON-GUI logic (db.rs / scan.rs / …) — the real work
    ├── selftest.rs         # headless proof, prints EOS-<APP>-SELFTEST-OK
    └── gui.rs              # Slint UI wiring, behind the `gui` feature
```

**Split the logic from the UI.** All real behaviour lives in `core.rs` (+
`selftest.rs`); `gui.rs` only wires widgets to it. This is what makes the app
provable headlessly (§4) and keeps the host build (which can't compile the GUI)
working.

## 2. Cargo.toml

```toml
[features]
default = ["gui"]
gui = ["dep:slint", "dep:eos-ui"]   # GUI is a Redox-target concern

[dependencies]
slint  = { version = "1.17", default-features = false, features = ["compat-1-0", "std", "renderer-software", "unstable-fontique-010"], optional = true }
eos-ui = { git = "https://github.com/Gh0s777tt/eos-ui.git", rev = "<pin>", optional = true }
# add rusqlite = { version = "0.31", features = ["bundled"] } if you need storage

[build-dependencies]
slint-build = "1.17"

[profile.release]
overflow-checks = true              # E-OS hardening baseline
```

`gui` is default but **feature-gated** so CI/hosts can build the CLI half with
`--no-default-features` (Slint's winit host backend no longer compiles on modern
host rustc; the Redox target uses `eos-ui`'s custom backend, not winit).

## 3. main.rs + eos-ui

```rust
mod core; #[cfg(feature = "gui")] mod gui; mod selftest;

fn main() {
    if std::env::args().any(|a| a == "--selftest") {
        match selftest::run() { Ok(()) => println!("EOS-<APP>-SELFTEST-OK"),
                                 Err(e) => { eprintln!("EOS-<APP>-SELFTEST-FAIL: {e}"); std::process::exit(1); } }
        return;
    }
    #[cfg(feature = "gui")] gui::run();
}
```

In `gui::run()`, the first line installs the shared backend + fonts:

```rust
eos_ui::init("E-OS <App>");   // Slint platform over orbclient + font bootstrap
let win = MainWindow::new().unwrap();
// … wire callbacks to core.rs …
win.run().unwrap();
```

## 4. The `--selftest` contract

Every app ships a headless self-test that proves its non-visual core without a
display: exercise `core.rs` end-to-end and print `EOS-<APP>-SELFTEST-OK`. It is the
runtime gate — asserted from the boot serial via a throwaway `init.d` probe (see
§6) and run in the app's CI. Storage apps also assert `journal_mode == wal`.

## 5. Package it (in this meta repo)

1. **Recipe** `recipes/gui/eos-<app>/recipe.toml` (template `custom`): pin the
   GitHub rev, `cookbook_cargo`, then stage the binary, the launcher entry
   `usr/share/ui/apps/NN_eos-<app>`, and the icon `usr/share/ui/icons/apps/…`.
   If you bundle SQLite, append `-DSQLITE_DISABLE_LFS` to the target CFLAGS
   (relibc has no LFS64 aliases) — **append**, don't replace (they carry the
   sysroot include path).
2. **Enable it**: add `[packages.eos-<app>]` to `config/aarch64/eos.toml` and
   `config/x86_64/eos.toml`.
3. **Register the pin**: add the repo to [`repos.toml`](../repos.toml);
   `scripts/eos-repos.sh pins --strict` must stay green.

## 6. Verify (the three gates — see [CLAUDE.md](../CLAUDE.md))

- **Compile**: `cargo build --target aarch64-unknown-redox --release` in the
  container (link with `aarch64-unknown-redox-gcc`); `cargo run --no-default-features -- --selftest` on the host.
- **Integrate**: `make CI=1 ARCH=aarch64 CONFIG_NAME=eos all` + `ci-boot-smoke.sh`.
- **Runtime**: a throwaway `init.d` probe (`config` `[[files]]` running
  `eos-<app> --selftest`) → assert `EOS-<APP>-SELFTEST-OK` on the serial. **Never
  commit the probe.** Prove the GUI with a greeter-login screendump.

## 7. Ship it

Push the app repo to GitLab **and** GitHub, bump the pin, then push the meta change
with a `CHANGELOG.md` `[U-NNN]` entry and a `README` for the app. Done means all
seven of these steps — see the Definition of Done in [CLAUDE.md](../CLAUDE.md).
