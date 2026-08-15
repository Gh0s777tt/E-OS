# 🧱 E-OS Architecture

> This page covers the **internals** (boot flow, schemes, the trusted computing
> base). For the top-level repo/component map, the layer diagram, and how the
> project is assembled + hosted, start at [`ARCHITECTURE.md`](../ARCHITECTURE.md)
> at the repo root.

E-OS inherits Redox's **microkernel** design: keep the kernel tiny, push
everything else (drivers, filesystems, networking, display) into **user space**
as isolated processes that communicate via **schemes**.

## Boot flow

```mermaid
%%{init: {'theme':'base','themeVariables':{'primaryColor':'#E50914','primaryTextColor':'#fff','primaryBorderColor':'#E50914','lineColor':'#E50914','fontFamily':'Fira Code'}}}%%
flowchart LR
    A["UEFI / OVMF"] --> B["E-OS Bootloader"]
    B --> C["Mount RedoxFS"]
    C --> D["Load microkernel"]
    D --> E["init → switchroot"]
    E --> F["Spawn drivers<br/>nvmed · ahcid · xhcid · e1000d · ihdad"]
    F --> G["orbital + E-OS DE"]
    G --> H["login:"]
    classDef red fill:#E50914,stroke:#E50914,color:#fff;
    class D red;
```

## The kernel (trusted computing base)

The microkernel does only what *must* be privileged:

- **Scheduling** and process/thread management
- **Memory** management (virtual memory, page tables)
- **IPC** and the **scheme** mechanism
- Minimal architecture glue (interrupts, syscalls)

Everything else is a normal process. A crashing driver cannot panic the kernel.

## Schemes — "everything is a URL"

Resources are named like URLs and provided by **scheme handlers**:

| Scheme | Provided by | Example |
|--------|-------------|---------|
| `file:` | RedoxFS server | `file:/home/user/notes.txt` |
| `disk:` / `nvme:` | `nvmed` | block storage |
| `network:` / `tcp:` | net stack | sockets |
| `display:` / `orbital:` | display server | the screen |
| `pty:`, `pipe:`, `rand:` | kernel/servers | terminals, pipes, entropy |

A process opens a scheme path; the kernel routes the request to the handler.
This gives a uniform, **capability-style** model: hand a process only the scheme
handles it needs.

## Component map

```mermaid
%%{init: {'theme':'base','themeVariables':{'primaryColor':'#E50914','primaryTextColor':'#fff','primaryBorderColor':'#E50914','lineColor':'#E50914','secondaryColor':'#1f1f1f','fontFamily':'Fira Code'}}}%%
flowchart TD
    K["microkernel"]
    subgraph servers["User-space servers"]
        FS["redoxfs"]
        NET["netstack"]
        DRV["drivers"]
        DISP["orbital (display server + WM + software compositor)"]
    end
    subgraph user["User programs"]
        LIBC["relibc + libstd"]
        SH["ion shell · coreutils"]
        APP["COSMIC apps"]
    end
    K --- servers
    servers --- user
    classDef red fill:#E50914,stroke:#E50914,color:#fff;
    class K red;
```

| Component | Description |
|-----------|-------------|
| **kernel** | The microkernel — scheduling, memory, IPC, schemes. |
| **relibc** | C standard library, written in Rust (Redox + Linux targets). |
| **RedoxFS** | Copy-on-write, optionally-encrypted filesystem. |
| **drivers** | `nvmed`, `ahcid`, `xhcid`, `e1000d`, `ihdad`, … — user space. |
| **orbital** | The display server, window manager and software compositor — one process. The desktop *chrome* (greeter, launcher, wallpaper, desktop icons) is `eos-orbutils` on top of it; COSMIC apps run as clients. `cosmic-comp` is **not** used. |
| **cookbook** | Recipe/package build system producing `pkgar` packages. |

## How E-OS differs from upstream Redox

Today E-OS is the **Genesis** base — architecturally identical to upstream Redox.
Divergence is **additive** and tracked on the [roadmap](../ROADMAP.md): branding,
a curated `eos.toml` config, hardening (signed images, SBOM), and licensing
(AGPL-3.0). We deliberately **do not** fork the kernel; we re-base on upstream to
stay current. See [`REDOX-README.md`](REDOX-README.md) for the upstream overview.
