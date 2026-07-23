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

### Read side (any uid)

`sys::net()` reads the **live** scheme and derives the display fields, falling
back to the persistent `/etc/net/*` files when the scheme isn't up (and to empty
on a host, where neither exists):

- interface ← first entry of `ifaces` (default `eth0`);
- IP + netmask ← `ifaces/<if>/addr/list`, parsed to `ip/prefix` then the prefix
  expanded to a dotted mask (`parse_addr_list`, `prefix_to_netmask`);
- gateway ← the `default` line's `via` token in `route/list`
  (`parse_default_gateway`), else `/etc/net/ip_router`;
- DNS ← `resolv/nameserver`, else `/etc/net/dns`;
- MAC ← `ifaces/<if>/mac` (informational).

smolnetd's placeholder strings (`Not configured`, `Device not found`) are mapped
to "unknown" so they can never masquerade as a real value.

### Write side (root, via the shim)

The *Sieć* tab has a small static editor (IP, prefix, gateway, DNS) pre-filled
from the live config. Applying is a **two-step confirm** that reveals a password
field, then spawns **`eos-netcfg`** with the values on argv and the password on
**stdin** — the same never-run-the-GUI-as-root pattern as `eos-power`:

1. `eos-netcfg` elevates via the shared [`elevate::to_root`](design-eos-power.md)
   handshake (open `/scheme/sudo`, write the password, elevate our procfd,
   `setns`).
2. Now root, it writes, **in order**:
   1. `ifaces/<if>/addr/set` ← `ip/prefix` — smolnetd applies the address live
      and inserts the on-link network route;
   2. if a gateway was given: `route/rm` ← `0.0.0.0/0` (idempotent — drop any old
      default), then `route/add` ← `default via <gw>` (needs step 1's address so
      the gateway is on-link);
   3. if a DNS was given: `resolv/nameserver` ← `<dns>`.

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
- **A live DHCP↔static toggle in the pane** — deferred, honestly: "DHCP" means a
  `dhcpd` lifecycle (it's a one-shot today, `R-906`) plus writing the persistent
  `/etc/net/*`; a trustworthy toggle belongs with the installer/OOBE
  (`R-603`/`R-902` follow-up), not a mid-session GUI switch. The pane does the
  honest, well-defined thing — apply a static config live — and says so.

## Security properties

Identical trust model to eos-power: the **GUI never runs as root**; elevation is
**password-gated** by `/scheme/sudo` (wrong password / non-sudo user → no change);
the shim has **minimal capability** (it writes only `netcfg:` paths, never
`exec`s an arbitrary command); and there is **no password leakage** (stdin, never
argv, cleared after confirm). Blast radius even if abused is a local network
reconfiguration, which already requires the user's password + local access.

## Verification

- **Contract** — the read parsers and the write payloads are verified against the
  smolnetd source (the `cfg_node!` tree + `route_table` `Display`), not guessed.
- **Headless (host `--selftest`)** — `net_core` exercises every pure helper
  (`parse_addr_list`, `prefix_to_netmask` ↔ `netmask_to_prefix`, `valid_ipv4`,
  `valid_prefix`, `parse_default_gateway`) and the read path, and asserts
  `apply_static` **rejects** bad input before spawning; the shim itself is only
  *referenced* (a valid-input call would reconfigure the live network mid-boot),
  exactly as `power_core`/`audio_core` treat their setters. `EOS-CONTROL-SELFTEST-OK`.
- **Gated to CI / boot render-verify** — the gui cross-compile + boot are gated by
  the heavy CI `build-image` job (the pin bump triggers it). The **live apply**
  (type a static IP, confirm with the password, watch the *Sieć* tiles update) is
  the render-test proof, run on the built image — the same class of proof as
  eos-power's power-off. A local render screendump is **deferred**: this build host
  has no cooked tree, so a screendump needs a full from-scratch OS build.

## Follow-up (`R-902` remaining)

Persistent DHCP/static selection (managing `dhcpd` + `/etc/net/*`), IPv6 (blocked
on `R-903`), and the same pane in the installer front-ends (`R-603`). Tracked on
the roadmap; the shipped increment is live-read + static live-apply.
