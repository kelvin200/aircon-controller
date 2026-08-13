# schedule Specification

## Purpose

Defines schedule management: creating timed entries that set system or zone state, viewing pending and historical schedules, and deleting entries.

## Requirements

### Requirement: Create a schedule entry
The app SHALL allow the user to create a schedule entry with a datetime and any partial combination of: state, mode, fan speed, set temperature, and per-zone settings. Omitted fields are not applied when the entry fires.

#### Scenario: Create entry with state ON
- **WHEN** the user sets a datetime, sets state to ON, optionally adds mode/fan/temp/zones, and saves
- **THEN** the app POSTs to `/schedules` with all provided fields and the entry appears in Pending

#### Scenario: Create entry with state OFF
- **WHEN** the user sets state to OFF
- **THEN** the form hides all other setting fields and only `{"state":"off"}` is included in the POST

#### Scenario: Create entry with no state
- **WHEN** the user creates an entry without specifying state (e.g. only fan speed)
- **THEN** the entry is saved and only the specified fields are applied when it fires; power state is unchanged

### Requirement: View pending schedules
The app SHALL show a Pending Schedules screen listing all entries that have not yet fired, sorted by fire time ascending (soonest first).

#### Scenario: Pending list display
- **WHEN** the user opens the Pending Schedules screen
- **THEN** only entries with no `firedAt` are shown, ordered ascending by `fireAt`

### Requirement: Navigate to all schedules
The app SHALL provide a button on the Pending Schedules screen to navigate to the All Schedules screen.

#### Scenario: Navigate
- **WHEN** the user taps the "All Schedules" button
- **THEN** the app navigates to the All Schedules screen

### Requirement: View all schedules including history
The app SHALL show an All Schedules screen with every entry sorted by fire time ascending. Fired entries are visually dimmed.

#### Scenario: All schedules display
- **WHEN** the user opens the All Schedules screen
- **THEN** all entries are shown sorted by `fireAt` ascending; entries with a `firedAt` value are rendered dimmed

### Requirement: Clear past schedule entries
The app SHALL allow the user to delete all fired entries in one action from the All Schedules screen.

#### Scenario: Clear past
- **WHEN** the user taps "Clear Past"
- **THEN** the app sends `DELETE /schedules/past` and the list refreshes showing only pending entries

### Requirement: Delete a single schedule entry
The app SHALL allow the user to delete any individual schedule entry from either schedule screen.

#### Scenario: Delete entry
- **WHEN** the user deletes an entry
- **THEN** the app sends `DELETE /schedules/{id}` and the entry is removed from the list

### Requirement: Zone settings use a grid editor

When creating or editing a schedule entry, the app SHALL present the per-zone settings as a 3-column grid of zone cells, matching the visual language of the Zones page (name + damper value per cell), rather than a vertical list.

#### Scenario: Schedule zone editor renders as a grid
- **WHEN** the user opens the schedule editor and the current status is loaded
- **THEN** the zone controls appear as a grid of cells (one per zone), consistent with the Zones page layout

#### Scenario: Zone cells reflect the projected diff
- **WHEN** a zone's open/close state or damper value differs from the status at the chosen time
- **THEN** that cell is highlighted to indicate the change, consistent with how the Zones page shows state
