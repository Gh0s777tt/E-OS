# Design: non-blocking endpoint transfers in `xhcid`

> Status: **IMPLEMENTED and verified (`U-057`, `eos-base` @ `a3a98fd4`).** This document is the
> design that was built; it now doubles as the reference for how the non-blocking path works. It
> lifted the one remaining blocker on `usbnetd` (a blocking bulk-IN read deadlocking a concurrent
> bulk-OUT write). Verified under QEMU: a full DHCP handshake flows through `usbnetd` concurrently
> with a `usb-storage` device, `login`, 0 exceptions; `usbscsid` still reaches `SCSI initialized`
> (blocking path untouched). Interactive HID input remains to be confirmed on an x86 rig.
> Companion to `U-056`/`U-057` (`docs/roadmap-connectivity.md`, `CHANGELOG`).

## The problem (proven)

`usbnetd`'s TX and RX both work end-to-end (an ARP request egressed and its reply was received
and unwrapped — verified in logs + a `filter-dump` pcap). But **continuous bidirectional flow
deadlocks**, and the cause is in `xhcid`, not `usbnetd`:

- `xhcid` serves its scheme with the single-threaded `redox-scheme` `Blocking`/`ReadinessBased`
  wrapper: `process_requests()` runs `for request in drain(..) { … }`, calling the scheme's
  `read`/`write` **synchronously** on one thread.
- Endpoint **data** reads/writes `block_on(self.on_read_endp_data(…))` /
  `block_on(self.on_write_endp_data(…))` (`xhci/scheme.rs` ~2287 / ~2356).
- So a blocking bulk-IN read (RX thread, waiting for data that only arrives *after* we TX) stalls
  the single request loop → the concurrent bulk-OUT write (TX) can't be serviced → nothing
  egresses → the RX read never completes. Deadlock.
- Empirically it also stalls a **second** USB subdriver's concurrent init on the same controller
  (boot with `usb-net` + `usb-storage` → both `usbscsid` and `usbnetd` hang mid-init, though the
  system still reaches `login` with 0 exceptions).

## Why the fix is additive (bounded blast radius)

The fix adds a **non-blocking path gated on `O_NONBLOCK`, for reads only**. The existing blocking
path is left byte-for-byte unchanged, so `usbhidd` (HID), `usbscsid` (storage) and `usbhubd` (hubs)
— which all use blocking transfers — **cannot regress at runtime**. Only `usbnetd`, which opts in
by opening its bulk-IN data fd `O_NONBLOCK`, exercises the new code. Writes stay blocking (a
bulk-OUT completes promptly once the device accepts it; only the *indefinite* RX read needs to be
non-blocking).

## The key enabler (makes it tractable)

`Xhci::next_transfer_event_trb(…)` (`xhci/irq_reactor.rs`) already returns
`impl Future<Output = NextEventTrb> + Send + Sync + 'static`. The completion future is **already
`'static`** — it owns its `message: Arc<Mutex<Option<NextEventTrb>>>`, the reactor channel
`Sender`, and the doorbell; it does **not** borrow `&self`. So we can **split** a transfer into:

1. **arm** — submit the TRB(s) + ring the doorbell (borrows `&self` briefly), returning the
   `'static` completion future + the DMA buffer; and
2. **poll** — poll that stored `'static` future with a no-op waker; the IRQ-reactor thread fills
   `message` on completion regardless of the waker, so a later poll observes it.

No `Weak<Xhci>` / self-referential-future gymnastics are needed.

## Plan

### 1. `xhci/scheme.rs` — split `transfer` into arm + await
- Refactor `transfer()` / `execute_transfer()` so the TRB-submission half returns the `'static`
  `impl Future<Output = NextEventTrb>` and the owned `Dma<[u8]>` buffer, instead of `.await`ing
  inline. Keep the existing `async fn transfer(…)` as a thin wrapper (`arm` then `.await`) so the
  blocking path is unchanged.
- Post-processing (bytes-transferred from `event.transfer_length()`, copy DMA→client buf) moves
  into the poll side.

### 2. `xhci/scheme.rs` — per-endpoint pending state
- Add to `EndpointState` (or a sibling map) a field like
  `pending_rx: Option<PendingRead>` where
  `PendingRead { fut: Pin<Box<dyn Future<Output = NextEventTrb> + Send>>, dma: Dma<[u8]>, len: usize }`.
- `EndpIfState` (scheme.rs:91) already models the ctl/data handshake
  (`WaitingForDataPipe { direction, … }` → `WaitingForTransferResult(status)`); the non-blocking
  read keeps the state in `WaitingForDataPipe` across `EAGAIN` retries until the poll completes,
  then transitions to `WaitingForTransferResult` exactly as today.

### 3. `xhci/scheme.rs` — non-blocking read handler
- Plumb the fd's fcntl flags into `on_read_endp_data` (the `read` trait method already receives
  `_fcntl_flags: u32`; today it's dropped at the `block_on` call site — pass it down).
- Behaviour when `O_NONBLOCK`:
  - no `pending_rx` yet → **arm** (submit TRB, build DMA buffer of `buf.len()`), poll once with a
    no-op waker; if `Ready` copy out + return, else store `pending_rx` and return `EAGAIN`.
  - `pending_rx` present → **poll**; if `Ready` copy DMA→`buf`, clear state, set
    `WaitingForTransferResult`, return the byte count; else `EAGAIN`.
- Without `O_NONBLOCK` → unchanged (`block_on`).
- No-op waker: `core::task::{RawWaker, RawWakerVTable}` or `futures::task::noop_waker` (the
  `futures` crate is already a dep — `futures::executor::block_on` is used).

### 4. `driver_interface.rs` — client non-blocking read API
- Add a poll-style read to `XhciEndpHandle`, e.g. `arm_read(count)` (writes the
  `XhciEndpCtlReq::Transfer { In, count }` ctl request once) + `poll_read(buf) -> Result<Option<PortTransferStatus>>`
  that does a non-blocking `data.read` (returns `Ok(None)` on `EWOULDBLOCK`, `Ok(Some(status))`
  when complete after reading `ctl_res`). Open the data fd with `O_NONBLOCK`
  (`open_endpoint_data` variant, or `fcntl(F_SETFL)`).
- Leave the existing blocking `transfer_read`/`transfer_write` untouched.

### 5. `usbnetd` — opt into non-blocking RX
- RX thread: `arm_read(2048)` once, then loop `poll_read`: on `None` sleep ~1 ms and retry (this
  is what frees the xhcid loop so TX interleaves); on `Some` unwrap RNDIS, queue the frame, poke
  the notify pipe, and re-arm. (A follow-up can replace the 1 ms poll with an `fevent` the reactor
  posts on completion, but spin-poll is correct and sufficient first.)
- TX (`write_packet`) stays blocking — unchanged.

## Verification (all but HID are QEMU-checkable on this Mac)
- `usbscsid`: `-device usb-storage` still reaches `SCSI initialized` + reads block 0 (blocking
  path unchanged — must stay green).
- `usbhubd`: `-device usb-hub` topology still enumerates.
- `usbnetd`: `-device usb-net` — ARP self-test **and** a continuous exchange
  (`dhcpd`/ping-equivalent) now flow both ways without deadlock; re-run the two-device
  (`usb-net` + `usb-storage`) boot and confirm **both** now finish init.
- **HID (`usbhidd`) input is NOT verifiable headless under QEMU-on-macOS** — the blocking path is
  untouched so HID *should* be unaffected, but confirm on an x86 hardware rig with a real
  keyboard/mouse before treating it as proven.

## Risk
Contained: the blocking transfer path is unchanged, so the 4 existing USB drivers keep their exact
runtime behaviour. New risk is confined to the `O_NONBLOCK` read path (async split correctness,
DMA-buffer lifetime across `EAGAIN` retries, ctl/data state machine). Revert is trivial — the
change is additive and self-contained.
