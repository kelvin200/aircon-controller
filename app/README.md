# gogo

Flutter app for the "gogo" home air-conditioning controller — a local-network
proxy to an Advantage Air e-zone unit controlling a Mitsubishi FDUA reverse-cycle
system. Android-only; built and run on the local network.

## Build

The server base URL is not committed and has no default. Pass it at build time:

```
flutter build apk --dart-define=API_BASE=http://<router-ip>:<port>
```

## Architecture

- Plain Flutter, no state-management library — `setState` only.
- Screens fetch from a small API client (`lib/api.dart`) that talks to the Go
  server (`/status`, `/system`, `/zones/:id`, `/schedules`, `/errors`).
- The zone grid lives behind the whole navigator so it shows through every
  screen.

## Zone names are private

The e-zone unit returns a `name` for each zone in `getSystemData`. These names
identify the home's room layout and are **private** — they must never be
hard-coded in the app, in tests, or in any committed config. The app resolves
zone display names from the backend status payload at runtime and falls back to
the zone id (`Z01`–`Z09`) when a name is missing. The backend keeps any real
names in a local, uncommitted config file.
