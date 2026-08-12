# scheduler-engine Specification

## Purpose

Defines the server-side scheduler that polls pending schedule entries, fires those that are due by applying only their non-NULL fields, and never re-executes an already-fired entry.

## Requirements

### Requirement: Poll and fire pending entries
The server SHALL run a background goroutine ticking every 30 seconds that queries for pending entries with `fire_at <= now`, executes their commands against e-zone, and marks them fired.

#### Scenario: Entry fires on time
- **WHEN** a schedule entry's `fire_at` is <= the current Unix timestamp and `fired_at` is NULL
- **THEN** the scheduler sends the appropriate `setAircon` request to e-zone and sets `fired_at` to the current time

#### Scenario: Multiple entries overdue in one tick
- **WHEN** multiple pending entries are overdue at the same tick
- **THEN** each is executed sequentially and all are marked fired

### Requirement: Only non-NULL fields are applied
The scheduler SHALL build the e-zone payload using only the non-NULL columns of the schedule entry, leaving all other AC settings unchanged.

#### Scenario: Fan-only entry
- **WHEN** an entry has only `fan = "low"` and all other fields NULL
- **THEN** the scheduler sends only `{"ac1":{"info":{"fan":"low"}}}` to e-zone

#### Scenario: State OFF entry
- **WHEN** an entry has `state = "off"`
- **THEN** the scheduler sends only `{"ac1":{"info":{"state":"off"}}}` regardless of other fields

### Requirement: Fired entries are never re-executed
The server SHALL never fire the same schedule entry twice.

#### Scenario: Already-fired entry skipped
- **WHEN** an entry has a non-NULL `fired_at`
- **THEN** it is excluded from the scheduler query and never sent to e-zone again
