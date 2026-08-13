# patches/ — reference copies, NOT applied at build time

**Nothing in the build applies these patches.** The changes they describe live
as real commits in the E-OS forks, and the recipes build from those forks at a
pinned `rev` (see `repos.toml`):

| Patch | Lives in fork | Branch |
|---|---|---|
| `bootloader-eos-red-black.patch` | [`eos-bootloader`](https://gitlab.com/e-os/eos-bootloader) — red/black theme + `"E-OS Bootloader"` banner | `eos-rebased` |
| `userutils-eos-login.patch` | [`eos-userutils`](https://gitlab.com/e-os/eos-userutils) — `redox login:` → `eos login:` prompt | `eos-july` |

They are kept here as **human-readable reference copies** of the branding
diffs: small, self-contained statements of *exactly what E-OS changes*, easy to
review without cloning a fork, and a re-application recipe if a fork ever has
to be rebuilt from upstream scratch. The `eos login:` prompt change is also
load-bearing beyond branding — `scripts/ci-boot-smoke.sh` asserts that exact
string to declare a boot successful.

Because they are copies, they can drift from the fork branches after a rebase.
When they matter (fork reconstruction), regenerate them from the fork instead
of trusting these blindly: `git format-patch <upstream-base>..<eos-branch>`.
