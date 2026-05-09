# Local Scope — Source-Truth Audit Report

Date: 2026-03-29
Scope: full repository audit against code as source of truth.

> Note: `LocalScope_Codex_Review_Brief.md` was requested as the primary brief, but no file with that name exists in this repository snapshot.

## 1) File Classification: canonical / transitional / junk

### Canonical (active project artifacts)

- `Local Scope.xcodeproj/project.pbxproj` (project definition)
- `Local Scope/Local_ScopeApp.swift`
- `Local Scope/Models/*.swift`
- `Local Scope/ViewModels/*.swift`
- `Local Scope/Services/**/*.swift`
- `Local Scope/Views/**/*.swift`
- `Local Scope/Assets.xcassets/**`
- `Local Scope/Local_Scope.entitlements`
- `Local Scope/README.md`
- `Local Scope.xcodeproj/project.xcworkspace/contents.xcworkspacedata`

### Transitional (historical/developer-local/supporting; not core runtime logic)

- `Local Scope.xcodeproj/project.xcworkspace/xcuserdata/**` (developer user state)
- `Local Scope.xcodeproj/xcuserdata/**` (developer-local IDE state)
- `Local Scope/Docs/LocalScope_Truth_Report.md` (this audit doc)

### Junk (cleanup candidates)

- `Original` — appears to be an old pasted git diff / backup blob, not project-consumable source.
- `Local Scope/App Icon` — stray placeholder Swift file named as an asset-like file; excluded from build in project exceptions.

## 2) Implementation Status Verification

## Scanning

Status: **partially implemented and operational for basic LAN cases**.

Implemented behavior:
- Detects local IPv4 by scanning interfaces and selecting `en0` or `en1`.
- Derives subnet by dropping final octet and assumes `/24`.
- Pings `.1...254` in parallel via `/sbin/ping`.
- Parses `arp -a` output and filters obvious broadcast/network artifacts.
- Checks open ports via `NWConnection` for SSH/RDP/FTP/VNC signatures.

Limitations:
- Hardcoded `/24` behavior.
- No interface selection beyond `en0/en1`.
- No IPv6 discovery.
- ARP parsing is format-sensitive and can produce misses on edge output variations.

## SSH

Status: **not an integrated SSH client**.

Implemented behavior:
- Launches Terminal and executes `ssh user@host -p port`.

Limitations:
- Password field is collected but not used for auth handoff.
- No in-app PTY/session channel, no handshake-level success check.
- Connection state is optimistic (time-delayed "opened").

## FTP / SFTP

Status: **launcher-only, partial SFTP integration**.

Implemented behavior:
- Opens Terminal with either `ftp host port` or `sftp -P port user@host`.

Limitations:
- No in-app transfer engine or file browsing UX.
- Password field is not used for terminal command auth.
- Port scan detects FTP (21) but does not independently discover SFTP capability model-wise.

## RDP

Status: **incomplete integration; effectively external-launch attempt**.

Implemented behavior:
- Constructs an `rdp://` URL and opens it through `NSWorkspace`.
- Separate `RDPClient` performs TCP reachability test, then marks status.

Limitations:
- `RDPClient` is not the primary path used by `UniversalTerminalView` for connection flow.
- No embedded RDP session.
- Success status can be reported without full remote desktop session establishment.

## VNC

Status: **external launcher only**.

Implemented behavior:
- Opens `vnc://` URLs via `NSWorkspace`.

Limitations:
- No in-app renderer/session lifecycle.
- "Connected" reflects URL launch, not negotiated interactive session readiness.

## 3) Code-vs-Docs Contradictions Found

The previous README overstated maturity in multiple places:

1. Claimed "all bugs fixed" and complete protocol functionality, while source still uses launcher-style wrappers and partial integration.
2. Claimed robust protocol support but implementations are mostly `Terminal` command dispatch / URL opening.
3. Claimed FTP issue fully resolved, yet there is no in-app FTP session manager and auth workflow is incomplete.
4. Claimed RDP reliability while code relies on URL handler availability and has split, partially-unused RDP logic.
5. Claimed full architecture correctness while repository still contains transitional/junk artifacts.

## 4) Documentation Updates Completed

Updated in this audit:
- Rewrote `README.md` to reflect real implementation status conservatively.
- Added this source-truth report with file classification, feature status, contradictions, and priorities.

## 5) Cleanup Steps (proposed)

1. Remove junk files:
   - `Original`
   - `Local Scope/App Icon`
2. Exclude or remove developer-local user data from version control:
   - `xcuserdata` and workspace user state paths.
3. Normalize comments/language mix (RU/EN) in code for maintainability.
4. Replace optimistic "connected" wording with accurate action-oriented statuses.
5. Add a dedicated `docs/architecture.md` for runtime boundaries (scanner vs launcher responsibilities).

## Next Implementation Priorities (proposed)

1. **Security baseline**: move stored credentials from `UserDefaults` to Keychain.
2. **Truthful UX**: rename actions/statuses to "Launch client" where appropriate.
3. **Scanning robustness**: support configurable interface/subnet/CIDR and richer host metadata.
4. **Protocol depth decision**:
   - Option A: stay launcher-first and harden integration checks.
   - Option B: embed at least one real protocol stack end-to-end (start with SSH).
5. **RDP/VNC reliability**: add preflight checks for registered handlers and user feedback when absent.
