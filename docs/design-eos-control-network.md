# eos-control: the Network settings pane (live netcfg + static apply)

**What this is:** the design of E-OS Control's *Sieć* (Network) tab — how it reads
the live network configuration and how it applies a **static** IPv4 config to the
running stack through the privileged `eos-netcfg` shim. Read it before touching
the network path in eos-control (`src/sys.rs`, `src/netcfg.rs`,
`src/elevate.rs`, `ui/control.slint`). Shipped in U-112 (`R-902`). Sibling of
[eos-power](design-eos-power.md), which established the shim pattern this reuses.

## The backend: smolnetd's `netcfg:` scheme

The network stack (`smolnetd`, from `netstack`) serves the `netcfg:` scheme. Its
node tree — recon'd from the smolnetd source (`src/smolnetd/scheme/netcfg`), the
same source-of-truth discipline U-110 used for audiod — is:

| Path | Mode | Payload |
|------|------|---------|
| `ifaces` | RO (dir) | newline list of interfaces (smolnetd serves a single `eth0`) |
| `ifaces/<if>/addr/list` | RO | `10.0.2.15/24` (or `Not configured` / `Device not found`) |
| `ifaces/<if>/addr/set` | **WO** | an `IpCidr` to assign, e.g. `10.0.2.15/24` (must be unicast) |
| `ifaces/<if>/mac` | RW | `52:54:00:12:34:56` |
| `route/list` | RO | routing table: `default  via 10.0.2.2 dev eth0 src 10.0.2.15` … |
| `route/add` | **WO** | `default via 10.0.2.2` (the `via` must already be on-link) |
| `route/rm` | **WO** | a CIDR to drop; `0.0.0.0/0` is the default route |
| `resolv/nameserver` | RW | a single IPv4 DNS server |

The one hard constraint that shapes everything: **`write()` rejects any caller
whose uid isn't 0** with `EACCES`. Reads are open to anyone; every *change* is
root-only.

## What we do

### Read side — `/etc/net/*` is the effective source in the GUI

`sys::net()` tries the `netcfg:` scheme first and falls back to the persistent
`/etc/net/*` files. **In the desktop GUI the files always win**, because — the
render-verify's key finding (`U-113`) — the desktop user's **orbital session
namespace does not include `netcfg:`**: `ls /scheme` as the user shows the
`ip`/`tcp`/`udp` sockets but *not* the privileged `netcfg:` config scheme, so
every `netcfg:` open fails for the GUI and the `/etc/net/*` fallback is what's
shown. (The scheme branch still matters for a *privileged* caller — e.g. a boot
probe — and it's why `read_netcfg` uses a plain `File::open`+`read` loop, not
`read_to_string`, which errors on scheme files.) The fields:

- interface — first entry of `ifaces` (default `eth0`);
- IP + netmask — `ifaces/<if>/addr/list` → `ip/prefix`; else `/etc/net/ip` +
  `/etc/net/ip_subnet`;
- gateway — the `default` route's `via`; else `/etc/net/ip_router`;
- DNS — `resolv/nameserver`; else `/etc/net/dns`;
- MAC — `ifaces/<if>/mac` (informational; unavailable to the GUI, so `—`).

Because the GUI reads `/etc/net/*`, the apply **must** update those files for the
change to be visible — see the write side.

### Write side (root, via the shim)

The *Sieć* tab has a small static editor (IP, prefix, gateway, DNS) pre-filled
from the live config. Applying is a **two-step confirm** that reveals a password
field, then spawns **`eos-netcfg`** with the values on argv and the password on
**stdin** — the same never-run-the-GUI-as-root pattern as `eos-power`:

1. `eos-netcfg` elevates via the shared [`elevate::to_root`](design-eos-power.md)
   handshake (open `/scheme/sudo`, write the password, elevate our procfd,
   `setns`).
2. Now root, it writes the **live** scheme, **in order**:
   1. `ifaces/<if>/addr/set` ← `ip/prefix` — smolnetd applies the address live
      and inserts the on-link network route;
   2. if a gateway was given: `route/rm` ← `0.0.0.0/0` (idempotent — drop any old
      default), then `route/add` ← `default via <gw>` (needs step 1's address so
      the gateway is on-link);
   3. if a DNS was given: `resolv/nameserver` ← `<dns>`.
3. It then writes the **persistent** files `/etc/net/{ip,ip_subnet,ip_router,dns}`
   to match. This is not optional: the GUI reads those files (it can't reach
   `netcfg:`), so without this step the applied config is invisible in the tiles;
   it also makes the change **survive a reboot**. Best-effort — a file-write
   failure doesn't undo the live change.

Inputs are validated **twice**: `sys::apply_static` rejects a bad IP / prefix /
gateway / DNS before ever spawning the shim (a clear message, no half-write), and
`eos-netcfg` re-validates its argv before elevating.

## Why this shape (alternatives rejected)

- **Write `/etc/net/*` and restart the stack** — rejected as the *primary* path:
  it's a persistent-config edit that only takes effect on a stack restart / reboot
  and doesn't change the running system; the netcfg scheme is the live,
  authoritative surface. (The persistent DHCP/static *default* is better decided
  at install/OOBE time — see the follow-up below.)
- **Run E-OS Control as root** — rejected for the same reason as eos-power: a
  large Slint GUI is far too much surface for uid 0. Only the ~90-line
  single-purpose `eos-netcfg` child elevates, for the moment it takes to write a
  handful of scheme files.
- **A second copy of the sudo handshake** — rejected: the elevation is factored
  into `src/elevate.rs` and shared by both shims (CLAUDE.md §6, shared code over
  copies), so there is one audited copy of the security-critical code.
- **A live DHCP↔static toggle in the pane** — *was* deferred, and this section used to
  explain why: "DHCP" means a `dhcpd` lifecycle (a one-shot today, `R-906`) plus
  writing the persistent `/etc/net/*`, so a trustworthy toggle looked like
  installer/OOBE work. **Shipped anyway in `U-132`** (eos-control `40dc67f`): the
  toggle persists the mode through a marker file and `eos-netcfg` grew subcommands
  for it, with the parser, the read path and the `valid_iface` guard asserted by
  `--selftest`. The reasoning above is kept because it is still the right shape of
  question to ask — but the answer changed, and a design doc that argues for a
  deferral the code no longer honours is worse than no doc.

## Security properties

Identical trust model to eos-power: the **GUI never runs as root**; elevation is
**password-gated** by `/scheme/sudo` (wrong password / non-sudo user → no change);
the shim has **minimal capability** (it writes only the `netcfg:` control paths +
`/etc/net/*`, never `exec`s an arbitrary command); and there is **no password
leakage** (stdin, never argv, cleared after confirm). Blast radius even if abused
is a local network reconfiguration, which already requires the user's password +
local access.

## Verification

- **Contract** — the read parsers and the write payloads are verified against the
  smolnetd source (the `cfg_node!` tree + `route_table` `Display`), not guessed.
- **Headless (host `--selftest`)** — `net_core` exercises every pure helper
  (`parse_addr_list`, `prefix_to_netmask` ↔ `netmask_to_prefix`, `valid_ipv4`,
  `valid_prefix`, `parse_default_gateway`) and the read path, and asserts
  `apply_static` **rejects** bad input before spawning; the shim itself is only
  *referenced*. `EOS-CONTROL-SELFTEST-OK`.
- **On-device render-verify (`U-113`)** — the built aarch64 image, driven through
  the real desktop in QEMU (greeter → OOBE → launcher → eos-control → *Sieć*),
  render-verified the tab and the whole static-apply flow (edit → confirm →
  password → `eos-netcfg` elevates + exits 0 → "Zastosowano konfigurację sieci").
  It also **caught the namespace gap**: the applied IP didn't reflect because the
  GUI reads `/etc/net/*` (no `netcfg:` in the session namespace), which the
  netcfg-only writes hadn't touched — the reason the shim now also writes
  `/etc/net/*` (proven root cause via a serial probe + `ls /scheme`). **After the
  fix, re-verified on-screen:** editing the IP to `10.0.2.50` and confirming
  flipped the *Adres IP* tile from `10.0.2.15` → `10.0.2.50` (the shim wrote
  `/etc/net/ip`; the refresh read it back) — the reflection that was missing
  before.

## Follow-up (`R-902` remaining)

~~Persistent DHCP/static selection (managing `dhcpd`)~~ and ~~the same pane in the
installer front-ends~~ both **landed in `U-132`** — the recipe pins were bumped to
eos-control `40dc67f` and eos-installer `ed6eb7c` after a full gate run (`cargo check`
both arches, `make … all` EXIT=0, boot-smoke PASS, `EOS-CONTROL-SELFTEST-OK`), which
closed `R-902`. Still open: IPv6 (blocked on `R-903`), full `dhcpd` lifecycle
management beyond the persisted mode (`R-906`), and one honest debt — the toggle's
**on-screen render has never been screendumped** (CLAUDE.md §4 counts a GUI render as
proven only by screendump; the pane and its apply flow were, in `U-113`).
