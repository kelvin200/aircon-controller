package main

import (
	"encoding/json"
	"testing"
)

func TestBuildSystemPayloadDoesNotPropagateSetTempToZones(t *testing.T) {
	temp := 24.0
	payload := buildSystemPayload(SystemCmd{SetTemp: &temp})

	ac1, ok := payload.(map[string]any)["ac1"].(map[string]any)
	if !ok {
		t.Fatalf("expected ac1 payload, got %#v", payload)
	}

	info, ok := ac1["info"].(map[string]any)
	if !ok {
		t.Fatalf("expected info payload, got %#v", ac1["info"])
	}

	gotTemp, ok := info["setTemp"].(float64)
	if !ok {
		t.Fatalf("expected setTemp as float64, got %#v", info["setTemp"])
	}
	if gotTemp != temp {
		t.Fatalf("expected setTemp %v, got %v", temp, gotTemp)
	}

	if _, hasZones := ac1["zones"]; hasZones {
		t.Fatalf("expected no zones payload for main setTemp change, got %#v", ac1["zones"])
	}
}

func TestScheduleToPayloadDoesNotPopulateZonesForMainSetTemp(t *testing.T) {
	temp := 22.5
	schedule := Schedule{SetTemp: &temp}
	payload := scheduleToPayload(schedule)

	ac1, ok := payload.(map[string]any)["ac1"].(map[string]any)
	if !ok {
		t.Fatalf("expected ac1 payload, got %#v", payload)
	}

	if _, hasZones := ac1["zones"]; hasZones {
		t.Fatalf("expected no zones payload for a main-only schedule, got %#v", ac1["zones"])
	}
}

func TestScheduleToPayloadIncludesExplicitZones(t *testing.T) {
	zones := json.RawMessage(`{"z01":{"state":"off"}}`)
	schedule := Schedule{Zones: zones}
	payload := scheduleToPayload(schedule)

	ac1, ok := payload.(map[string]any)["ac1"].(map[string]any)
	if !ok {
		t.Fatalf("expected ac1 payload, got %#v", payload)
	}

	zonesPayload, ok := ac1["zones"].(map[string]any)
	if !ok {
		t.Fatalf("expected zones payload, got %#v", ac1["zones"])
	}

	if _, ok := zonesPayload["z01"]; !ok {
		t.Fatalf("expected explicit zone payload to be preserved, got %#v", zonesPayload)
	}
}
