# Local Scope

Local Scope is a macOS SwiftUI network utility for:
- local subnet host discovery,
- basic port presence checks for common remote-access protocols,
- launching system/external clients for remote connections.

This README reflects the **actual implementation in source code** as of March 29, 2026.

## Current Feature Status (source-truth)

| Area | Status | What is implemented now | Gaps / limits |
|---|---|---|---|
| Network scanning | **Partial, functional** | Gets local IPv4 from `en0/en1`, pings `/24`, parses `arp -a`, then probes ports 22/3389/21/5900 using `NWConnection`. | Hardcoded `/24`, interface assumptions (`en0/en1` only), no CIDR/range selection, no IPv6, no hostnames from DNS/mDNS. |
| SSH | **Launcher only** | Opens `Terminal.app` and runs `ssh user@host -p port`. | No in-app SSH session, password is not injected/used, no key management, no connection success verification. |
| FTP/SFTP | **Launcher only** | Opens `Terminal.app` with `ftp host port` or `sftp -P port user@host`. | No in-app file browser/transfer pipeline, saved password not used in command, protocol tab is FTP-focused while SFTP is only partially represented in model/UI logic. |
| RDP | **Launcher-level / weak integration** | UI builds `rdp://` URL and asks macOS to open it; there is also a TCP reachability test client class. | No guaranteed client handling on macOS, no in-app RDP session, reachability test is not wired into user flow, credentials are not securely/fully integrated. |
| VNC | **Launcher only** | Opens `vnc://` URL via `NSWorkspace` (Screen Sharing/external handler). | No embedded VNC renderer/session handling, no robust auth/session state tracking. |

## Architecture Summary

- `NetworkScannerViewModel` orchestrates scanning, history, and credentials persistence.
- `NetworkScanner` performs local IP detection, subnet ping warm-up, and ARP parsing.
- `PortScanner` checks if key ports are reachable.
- Protocol client classes (`SSHClient`, `FTPClient`, `RDPClient`, `VNCClient`) mostly wrap OS-level launch behavior.
- `UniversalTerminalView` acts as a connection launcher UI, not a terminal/desktop implementation.

## Important Reality Notes

1. "Connected" statuses in protocol clients mostly mean "launch command/URL was issued", not that a session was fully negotiated.
2. Credentials are stored in `UserDefaults` for convenience, not in Keychain.
3. The app is macOS-specific and depends on system tools/apps (`ping`, `arp`, Terminal, URL handlers).

## Documentation

- Source-truth audit report: `Docs/LocalScope_Truth_Report.md`

## Recommended Next Priorities

1. Decide product direction per protocol: launcher utility vs true integrated client.
2. If keeping launcher mode, simplify terminology ("Open client" vs "Connected").
3. Move secrets to Keychain and harden credential flow.
4. Add scan settings (interface/subnet selection) and improve discovery fidelity.
