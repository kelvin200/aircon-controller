# server-api Specification

## Purpose

Defines the HTTP API the server exposes to the app: proxying e-zone status and system/zone commands, and managing schedule and error-log entries.

## Requirements

### Requirement: GET /status returns current AC state
The server SHALL proxy `getSystemData` from the e-zone controller and return a simplified JSON object with system info and all zone states.

#### Scenario: Successful fetch
- **WHEN** a client calls `GET /status`
- **THEN** the server GETs `<base>/getSystemData` (where `<base>` is the e-zone URL read from the `.env` file via the `EZONE_BASE` env var at runtime), extracts `ac1.info` and `ac1.zones`, and returns them as JSON with HTTP 200

### Requirement: POST /system applies partial system command
The server SHALL accept any combination of `state`, `mode`, `fan`, `setTemp` and forward only the provided fields to e-zone. Setting `setTemp` SHALL broadcast to all 9 zones.

#### Scenario: Set state and mode
- **WHEN** a client POSTs `{"state":"on","mode":"cool"}` to `/system`
- **THEN** the server sends `GET /setAircon?json={"ac1":{"info":{"state":"on","mode":"cool"}}}` and returns HTTP 200

#### Scenario: Set temperature
- **WHEN** a client POSTs `{"setTemp":22}` to `/system`
- **THEN** the server sends setAircon with `info.setTemp` and all z01–z09 `setTemp` set to 22

### Requirement: POST /zones/{zoneId} applies partial zone command
The server SHALL accept `state` and/or `setTemp` for a single zone and forward to e-zone.

#### Scenario: Open a zone
- **WHEN** a client POSTs `{"state":"open"}` to `/zones/z01`
- **THEN** the server sends `GET /setAircon?json={"ac1":{"zones":{"z01":{"state":"open"}}}}` and returns HTTP 200

### Requirement: GET /schedules returns all entries
The server SHALL return all rows from the schedules table as a JSON array, including both pending and fired entries.

#### Scenario: List all
- **WHEN** a client calls `GET /schedules`
- **THEN** the server returns all schedule rows as JSON with HTTP 200

### Requirement: POST /schedules creates an entry
The server SHALL insert a new row from the request body and return the created entry with its assigned id.

#### Scenario: Create
- **WHEN** a client POSTs a valid schedule JSON
- **THEN** the server inserts the row and returns HTTP 201 with the created entry including `id`

### Requirement: DELETE /schedules/{id} removes one entry
The server SHALL delete the schedule entry with the given id and return HTTP 200.

#### Scenario: Delete by id
- **WHEN** a client sends `DELETE /schedules/5`
- **THEN** the row with id=5 is deleted

### Requirement: DELETE /schedules/past removes all fired entries
The server SHALL delete all rows where `fired_at IS NOT NULL`.

#### Scenario: Clear past
- **WHEN** a client sends `DELETE /schedules/past`
- **THEN** all fired entries are deleted and HTTP 200 is returned

### Requirement: GET /errors returns all error log entries
The server SHALL return all rows from the errors table as a JSON array, ordered by `occurred_at` descending (newest first).

#### Scenario: List errors
- **WHEN** a client calls `GET /errors`
- **THEN** the server returns all error rows as JSON with HTTP 200, ordered newest first
