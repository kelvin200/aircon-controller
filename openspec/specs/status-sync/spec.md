# status-sync Specification

## Purpose

Defines how the app keeps the displayed system state consistent with the server while commands are in flight and polling runs: optimistic changes are only reverted when the command that made them fails, poll responses that are stale or out of order are dropped, and the UI holds the commanded state through the AC unit's propagation window instead of flashing back to the old state.

## Requirements

### Requirement: Optimistic state is reverted only by command failure

A user-initiated change SHALL be reflected immediately in the UI and SHALL be reverted only if the command that performs that change fails. Failure of a follow-up operation (such as creating an auto follow-up schedule or refreshing status afterwards) SHALL NOT revert a change whose command succeeded.

#### Scenario: Turning the system on with a failing follow-up
- **WHEN** the user turns the system on, the power command succeeds, but a follow-up schedule creation fails
- **THEN** the UI continues to show the system as on and does not revert to off

#### Scenario: Turning the system on with a failing power command
- **WHEN** the user turns the system on and the power command itself fails
- **THEN** the UI reverts to the previous (off) state

### Requirement: No backward flash during command propagation

After the user issues a state-changing command, the UI SHALL keep showing the commanded state until the server reports the commanded state, or a short grace period elapses, at which point the server's reported state is shown. The UI SHALL NOT display the previous state in between.

#### Scenario: Poll returns stale state during propagation
- **WHEN** the user turns the system on and a poll returns the previous (off) state while the command is still propagating
- **THEN** the UI continues to show on, and switches to showing the server's state only once the server reports on (or after the grace period)

#### Scenario: Grace period ends without confirmation
- **WHEN** the server has not reported the commanded state within the grace period after a command
- **THEN** the UI shows the server's reported state

### Requirement: Stale and out-of-order poll responses are dropped

When multiple status fetches overlap, only the newest fetch's response SHALL be applied; an older response arriving after a newer one SHALL be discarded so it cannot overwrite newer state.

#### Scenario: Out-of-order responses
- **WHEN** an earlier status fetch completes after a later fetch has already been applied
- **THEN** the earlier (stale) response is ignored and the UI keeps the newer state

### Requirement: Guards apply to all optimistic control paths

The revert-scope and propagation-hold behaviour SHALL apply consistently to every control that optimistically updates state: power on/off, mode, fan, temperature, and per-zone open/close and value changes.

#### Scenario: Zone toggle held during propagation
- **WHEN** the user toggles a zone open and a poll returns the previous (closed) state while the command propagates
- **THEN** the UI keeps showing the zone as open until the server reports it open (or the grace period elapses)

#### Scenario: Zone toggle failure reverts
- **WHEN** the user toggles a zone and the zone command fails
- **THEN** the UI reverts that zone to its previous state
