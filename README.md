# gogo — Home AC Controller

A local-network controller for **Advantage Air e-zone** home climate systems. It replaces the stock app with a cleaner, glanceable UI and a more flexible scheduling engine.

> ⚠️ **Personal project.** Built for home usage. Not affiliated with or endorsed by Advantage Air. Use at your own risk.

## Features

- Clean status screen: power, set temperature, mode/fan, and all 9 damper zones in a grid — active zones coloured, tap to toggle, long-press for a damper-value slider
- Advanced scheduling: timed entries that set system or zone state, with automatic follow-ups (fan down, then off)
- Runs entirely on your local network — no cloud, no account, no internet

## Architecture

```
┌─────────────┐   HTTP :<port>   ┌────────────┐   e-zone API :2025   ┌───────────┐
│  Flutter    │ ───────────────► │  Go server │ ───────────────────► │ e-zone AC │
│  (Android)  │                  │  (router)  │                      │  system   │
└─────────────┘                  └────────────┘                      └───────────┘
```

- `app/` — Flutter Android app
- `server/` — Go proxy + scheduler (SQLite-backed), runs on a GL.iNet **Flint 2** router (OpenWrt, arm64)

## Requirements

- An Advantage Air e-zone system reachable on your LAN
- A device to run the server — a Flint 2 router, or any linux/arm64 box on your network
- **Go 1.25+** to build the server; **Flutter 3.x** to build the app

## Configuration

No addresses are committed in the source. All three values live in a local `.env` file (not committed):

| Variable | What it is | Example |
|---|---|---|
| `EZONE_BASE` | URL of the e-zone unit (the AC's API) | `http://<ezone-unit-ip>:2025` |
| `PORT` | Port the server listens on | `<port>` |
| `API_BASE` | URL the app uses to talk to the server | `http://<router-ip>:<port>` |

Copy `.env.example` to `.env` and edit for your network. The `.env` file is **gitignored** and never leaves your machine.

## Build & run the server on the Flint 2

The server reads `EZONE_BASE` and `PORT` from its environment at runtime (no build-time flags). You just need the binary and a `.env` on the target.

Cross-compile from any machine:

```sh
cd server
./build.sh   # → ac-server
```

Copy the binary and your `.env` to the router:

```sh
scp ac-server .env root@<flint2-ip>:/root/
ssh root@<flint2-ip>
chmod +x /root/ac-server
cd /root && ./ac-server &
```

It reads `EZONE_BASE` and `PORT` from `/root/.env` (or the environment). State is stored in `./gogo.db` next to the binary.

**Start at boot (OpenWrt)** — add `/etc/init.d/gogo-server`:

```sh
#!/bin/sh /etc/rc.common
START=99
start() {
  cd /root && . .env && /root/ac-server >/var/log/gogo-server.log 2>&1 &
}
stop() {
  killall ac-server
}
```

```sh
chmod +x /etc/init.d/gogo-server
/etc/init.d/gogo-server enable
/etc/init.d/gogo-server start
```

**Verify:** `curl http://<flint2-ip>:<port>/status` (using your `PORT`) returns the current AC state (HTTP 502 "ezone unreachable" while the unit is off the network).

## Build the Android app

The app reads `API_BASE` from a `.env` at build time via the provided script:

```sh
cd app
../build_apk.sh
```

This reads `API_BASE` from the root `.env` and passes it to the build. Or manually:

```sh
cd app
flutter pub get
flutter build apk --debug --dart-define=API_BASE=http://<router-ip>:<port>
```

Install `build/app/outputs/flutter-apk/app-debug.apk` on your phone.

## Server API

| Method | Path | Purpose |
|---|---|---|
| GET | `/status` | Current system + zone state |
| POST | `/system` | Partial system command (state / mode / fan / setTemp) |
| POST | `/zones/{zoneId}` | Partial zone command (open / close / value) |
| GET / POST | `/schedules` | List / create schedule entries |
| DELETE | `/schedules/{id}` | Delete one entry |
| DELETE | `/schedules/past` | Clear fired entries |
| GET | `/errors` | Error log |

## Project layout

```
.
├── app/       Flutter Android app
├── server/    Go proxy + scheduler (SQLite)
├── openspec/  Spec-driven development artifacts (OpenSpec)
└── build.sh   Cross-compile the server for the router
```

## Tools & acknowledgments

Developed with [OpenSpec](https://openspec.dev/) (spec-driven development) and [Claude Code](https://claude.com/code), assisted by several AI models.

## Disclaimer

This is a **personal, non-commercial** project for my own home use. It is **not affiliated with, endorsed by, or connected to Advantage Air**, and does not infringe their copyright — it talks to the e-zone unit over its local API, on your own network, the way the stock app does. It comes with **no warranty**; use it at your own risk.
