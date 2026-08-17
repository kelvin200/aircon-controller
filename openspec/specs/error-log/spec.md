# error-log Specification

## Purpose

Defines how the system records server-side errors and how the app displays them in the Error Log screen.

## Requirements

### Requirement: Server persists errors to SQLite
The server SHALL write an error row to the `errors` table whenever a failure occurs, including: e-zone API unreachable, e-zone API returns non-200, scheduler dispatch failure, and HTTP handler errors. Each row SHALL record a Unix timestamp, a source label, and the error message.

#### Scenario: e-zone unreachable during status fetch
- **WHEN** the server cannot reach `<base>/getSystemData` (where `<base>` is the e-zone URL read from the `.env` file via the `EZONE_BASE` env var at runtime)
- **THEN** the server inserts a row into `errors` with source `"ezoneClient"` and the error message, and returns HTTP 502 to the caller

#### Scenario: Scheduler fails to dispatch an entry
- **WHEN** the scheduler calls setAircon and receives an error
- **THEN** the server inserts a row into `errors` with source `"scheduler"` and the error message; the entry is still marked fired so it is not retried

#### Scenario: Handler encounters an unexpected error
- **WHEN** an HTTP handler fails (e.g. DB error, malformed request)
- **THEN** the server inserts a row into `errors` with source `"handler"` and returns an appropriate HTTP error code

### Requirement: App displays error log screen
The app SHALL provide an Error Log screen that fetches all entries from `GET /errors` and displays them ordered by time descending (newest first), showing timestamp, source, and message for each entry. The screen SHALL also offer a "Clear all" action that deletes every error from the backend.

#### Scenario: Error log loads
- **WHEN** the user opens the Error Log screen
- **THEN** the app fetches `/errors` and renders each entry with its timestamp, source, and message

#### Scenario: No errors
- **WHEN** the errors table is empty
- **THEN** the screen shows an empty state message

#### Scenario: Clear all errors
- **WHEN** the user activates the "Clear all" action and confirms
- **THEN** the app sends `DELETE /errors`, the backend hard-deletes every row from the errors table, and the list reloads empty

### Requirement: Server deletes all errors

The server SHALL provide a `DELETE /errors` endpoint that hard-deletes every row from the errors table (no soft delete) and returns 200.

#### Scenario: Clear all succeeds
- **WHEN** a `DELETE /errors` request is received
- **THEN** the server deletes all rows from the errors table and responds 200
