# Design: E-OS Desktop Environment — "Crimson" (red/black glassmorphic shell)

> Grounded implementation plan for the desktop vision (deep-black + blood-red, diamond Start,
> floating taskbar, glassmorphism, red glowing icons, smoke-particle background, modern file
> manager / terminal / settings). Every claim below is checked against the actual Orbital /
> orbutils / orbdata / cosmic sources in the E-OS tree.

## The two hard constraints (everything follows from these)

1. **No GPU acceleration on Redox.** All graphics are CPU-rasterized to a 2D framebuffer
   (`virtio-gpud`/`vesad` are framebuffer-only; DRM is nascent; the Intel GPU driver only *began*
   upstream in 2025/26; software GL exists via llvmpipe but is CPU). So the shell must be designed
   for **software compositing** — dirty-rect updates, cached surfaces, capped framerate — not cheap
   GPU blur/compositing.
2. **Orbital's compositor does only `blit` (opaque copy) and `blend` (per-pixel ARGB source-over).**
   Per-window transparency is real (`WindowFlag::Transparent` → `Window::draw` `blend()`,
   `orbital/src/window.rs:242-257`). **There is no blur, drop-shadow, rounded-corner, or backdrop
   filter anywhere.** So "glassmorphism" = a **translucent red-tinted flat fill** today; *true*
   backdrop blur is a compositor extension (Phase 4) that costs O(area·kernel) CPU per frame.

## Architecture: what to reuse vs build

Orbital is a single-process **display server + window manager + software compositor**. The desktop
*chrome* is **four separate orbclient programs** you already own as E-OS forks — rewrite them
without touching the compositor:

| Layer | Program / file | Role | Plan |
|---|---|---|---|
| Compositor | `eos-orbital` | windowing, alpha compositing, input, decorations | **keep**; recolor via config; optional effects in Phase 4 |
| Taskbar + Start + menu | `eos-orbutils` `launcher/src/main.rs` | bottom bar (already `Transparent`), start menu | **rewrite** → floating red-glass bar + diamond Start + tray |
| Wallpaper | `eos-orbutils` `orbutils/src/background/main.rs` | draws one static image, `Back+Async` window | **rewrite** → animated smoke-particle loop |
| Greeter | `eos-orbutils` `orbutils/src/orblogin/main.rs` | fullscreen login | **restyle** red/black |
| Theme assets | `eos-orbdata` `usr/share/{ui,icons,fonts}` | cursors, window buttons, icons, `orbital.toml` | **replace** PNGs + add colors |
| Apps (files/term/settings) | COSMIC (`cosmic-files`, `cosmic-term`, `cosmic-settings`) | already build & render **in software** (tiny-skia + softbuffer + winit-orbital) via `--no-default-features` | **adopt + theme** via `cosmic-theme` |

**Framework decision.** For *apps*, libcosmic/iced is the proven path — E-OS already ships
`cosmic-edit/files/term` rendering in pure software on Orbital. For the *shell chrome* (bar,
launcher, wallpaper), stay on **orbclient**: it's lightweight, gives pixel-level control, and is
what the existing programs use. Don't build the bar in iced — iced makes apps, not compositor
chrome, and orbclient is a better fit for a translucent always-on bar. (Slint is a fine fallback
for apps if libcosmic's fork-sync burden grows; it also runs in software on Redox out of the box.)

---

## Phase 0 — Theme foundation (biggest visual win, least code)

**Goal:** the whole desktop turns red/black on the next boot, with zero new programs.

1. **Orbital chrome colors.** The color fields in `orbital/src/config.rs:36-45` are
   `#[serde(default)]`, so they can be set from `orbdata/usr/share/ui/orbital.toml` (which today
   sets only image paths). Add:
   - `background_color = rgb(10,0,0)` (near-black, faint red)
   - `bar_color = rgba(20,0,0,200)`, `bar_highlight_color = rgba(120,0,0,200)`
   - `text_color = rgb(235,235,235)`, `text_highlight_color = rgb(255,60,60)`
   Also change the duplicated constants in `launcher/src/theme.rs:3-5` (they're hardcoded, not read
   from the toml — fix that too, or at least match).
2. **Red window buttons + cursor.** Swap `orbdata` `ui/window_{close,max}*.png` and `ui/left_ptr.png`
   / corner cursors for red/black variants (paths already in `orbital.toml:1-10`).
3. **Red glowing icons.** Replace `orbdata` `icons/mimetypes/inode-directory.png` (folder),
   `icons/apps/*`, `icons/places/start-here.png` with pre-baked red-glow PNGs. **The glow must be
   painted into the PNG** — there is no runtime glow/shader. Provide @1x and @2x for HiDPI.
4. **COSMIC app theme.** Ship a red/black `cosmic-theme` (dark, accent = crimson) so
   `cosmic-files/term/settings` match. This is config, not code.
5. **Wallpaper.** Replace `orbdata` `ui/background.jpg` + `login.png` with the deep-black/crimson art.

*Effort:* days. *Testable:* graphical greeter boot (QEMU aarch64, `gui_boot_test.sh`). *Risk:* low.

---

## Phase 1 — Floating glass taskbar + diamond Start + tray (rewrite `launcher`)

Rewrite `eos-orbutils` `launcher`. The bar window is already `Async+Borderless+Transparent`
(`launcher/src/main.rs:347-358`), so translucency works immediately.

1. **Floating geometry.** Inset the bar from the screen edges (margins, e.g. 12px) and give it a
   rounded, red-tinted translucent fill (`rgba(20,0,0,180)`) with a 1px crimson glow border
   (pre-baked into a 9-slice PNG or drawn as lines). Round corners = pre-rendered corner sprites
   blended over the fill (no compositor rounding).
2. **Diamond Start.** Replace the `start-here.png` blit at x=0 (`main.rs:396-412`) with a glowing
   red **diamond** PNG (transparent corners composite fine because the window is `Transparent`).
   Optional: a subtle pulse animation (swap between 2–3 pre-rendered glow frames on a timer).
3. **Start menu.** Restyle `start_window` (`main.rs:470-549`): big search field at top, sections
   *Pinned / Recommended / All apps*, a grid of red app icons. It's a `Borderless+Transparent`
   popup already — make it a floating red-glass panel.
4. **System tray.** New — today the bar only has a clock (`main.rs:378-387`). Add clock + volume +
   network + battery indicators (read `/scheme/audio`, the `network.*`/`netcfg` schemes, and ACPI
   battery if present). Each is a small icon + click-through popup.
5. **Compositor coupling.** Update the hardcoded reserved-strip height
   (`compositor.rs:92-104`, `taskbar_h = 48*…`) to match the floating bar's footprint — or
   implement the standing `TODO` there (have the launcher register its geometry over the scheme)
   so maximized windows don't slide under a floating bar.

*Effort:* 2–4 weeks. *Testable:* graphical boot. *Risk:* medium (new tray plumbing).

---

## Phase 2 — Animated smoke-particle background (rewrite `background`)

Rewrite `eos-orbutils` `background`. Today it scales one image into a `Back+Async+Borderless`
window (`background/main.rs:325-399`); replace the static blit with a per-frame particle loop.

- **Model:** a few hundred soft crimson particles (position, velocity, life, alpha) drifting upward
  with turbulence + occasional sparks. Draw each as a small pre-blurred radial-gradient sprite
  (`blend`), over a dark base. Pre-baked sprites avoid per-pixel blur.
- **Performance (CPU-only!):** cap at ~30 fps; **dirty-rect** the changed regions only (Orbital +
  the window buffer support partial `sync()`), or accept a full-screen `Back`-layer repaint at
  reduced resolution/framerate. Keep particle count tunable in `orbital.toml`. Fall back to a static
  wallpaper on slow targets (config flag).
- Already handles multi-display + resize (`background/main.rs`), so keep that.

*Effort:* 1–2 weeks + art. *Testable:* graphical boot; watch CPU%. *Risk:* medium (perf tuning).

---

## Phase 3 — Apps: file manager, terminal, settings (adopt + theme COSMIC)

The vision's "modern file manager (sidebar + grid + search), dark red terminal, settings panels"
already exist as **COSMIC apps that render in software on Orbital today**:

- **File manager** = `cosmic-files` (has sidebar *This PC/Network/Favorites/Recent*, grid/list
  views, search, context menus). *Theme it red/black* via `cosmic-theme`; add the red folder icons
  from Phase 0. No new app needed.
- **Terminal** = `cosmic-term` — dark, monospaced; theme red accents + a red/black color scheme.
- **Settings** = `cosmic-settings` (currently deferred on the *aarch64 build host* only — the
  `host:gperf` toolchain publishes x86_64-linux only; builds on the x86 rig). Theme red/black.
- Context menus (New Folder / Open with / Compress / Properties / …) are drawn by each COSMIC app
  and are themeable — no compositor work.

*Alternative* if you'd rather not carry the libcosmic fork weight: restyle the lighter **orbutils**
`orbutils-files`/`orbterm` (orbclient) instead — smaller, but you rebuild the modern file-manager
UX yourself. Recommendation: **use COSMIC apps** (reuse >> rewrite) and theme them.

*Effort:* days–weeks (mostly theming + icons). *Testable:* graphical boot + open each app. *Risk:* low.

---

## Phase 4 — *Optional* real compositor effects (true glassmorphism)

Only if fake-glass (translucent fill) isn't enough. These require extending **`orbital` itself**
and cost real CPU:

- **Backdrop blur** behind translucent windows/bar: before `blend()`-ing a `Transparent` window
  (`window.rs:242-257`), box-blur the framebuffer region under it. O(area·kernel)/frame on CPU →
  only viable for small panels, cached until the backdrop changes (damage-tracked), or downscaled.
- **Drop shadows / per-window red glow:** an extra `blend` pass of a pre-blurred shadow/glow sprite
  around each window in `Compositor::redraw` (`compositor.rs:189-290`).
- **Rounded window corners:** mask window corners during `blit`/`blend` (alpha corner sprites).

*Effort:* weeks, with careful profiling. *Risk:* high (touches the verified compositor core + CPU
budget). Do this last, behind a config toggle, and keep the fake-glass path as default.

---

## Cross-cutting: performance & testability

- **Design for software rendering:** damage/dirty-rect everywhere, cache static surfaces, cap
  animation framerate, downscale expensive effects, expose particle/blur toggles in `orbital.toml`.
- **What's QEMU-testable on this Mac:** everything visual via the graphical greeter boot
  (`~/eos/out/gui_boot_test.sh`, screendump). **Not** testable headless: interactive click-through
  of menus (mouse input reaches the guest but automating GUI clicks is unreliable under QEMU-macOS)
  — verify interaction on the x86 rig or via screendumps of scripted states.
- **Fork sync:** `eos-orbital`/`eos-orbutils`/`eos-orbdata` currently just track upstream with **no
  theme applied**. All Phase 0–2 work lands in those forks; keep the rebase discipline already used
  for kernel/base.

## Suggested order & rough budget

0. Theme foundation — **days** (do first; instant red/black desktop).
1. Floating glass taskbar + diamond Start + tray — **2–4 wk**.
2. Smoke-particle background — **1–2 wk**.
3. COSMIC apps themed (files/term/settings) — **days–wk**.
4. *(optional)* real blur/shadow/rounded in the compositor — **weeks, high risk**.

Phases 0–3 deliver the entire vision *except real backdrop blur*, all on the software stack that
boots today. Phase 4 is the only part that needs compositor surgery.
