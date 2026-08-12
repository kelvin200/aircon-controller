package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
)

var ezoneBase = ""

func setEzoneBase(base string) {
	ezoneBase = base
}

type EzoneInfo struct {
	State     string  `json:"state"`
	Mode      string  `json:"mode"`
	Fan       string  `json:"fan"`
	SetTemp   float64 `json:"setTemp"`
	MyZone    int     `json:"myZone"`
	NoOfZones int     `json:"noOfZones"`
}

type EzoneZone struct {
	Name         string  `json:"name"`
	Number       int     `json:"number"`
	State        string  `json:"state"`
	SetTemp      float64 `json:"setTemp"`
	MeasuredTemp float64 `json:"measuredTemp"`
	Value        int     `json:"value"`
}

type SystemData struct {
	Info  EzoneInfo            `json:"info"`
	Zones map[string]EzoneZone `json:"zones"`
}

type ezoneResponse struct {
	Aircons struct {
		Ac1 struct {
			Info  EzoneInfo            `json:"info"`
			Zones map[string]EzoneZone `json:"zones"`
		} `json:"ac1"`
	} `json:"aircons"`
}

func getSystemData() (*SystemData, error) {
	resp, err := http.Get(ezoneBase + "/getSystemData")
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("ezone returned %d", resp.StatusCode)
	}
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	var raw ezoneResponse
	if err := json.Unmarshal(body, &raw); err != nil {
		return nil, err
	}
	return &SystemData{
		Info:  raw.Aircons.Ac1.Info,
		Zones: raw.Aircons.Ac1.Zones,
	}, nil
}

func setAircon(payload any) error {
	b, err := json.Marshal(payload)
	if err != nil {
		return err
	}
	reqURL := ezoneBase + "/setAircon?json=" + url.QueryEscape(string(b))
	resp, err := http.Get(reqURL)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode != 200 {
		return fmt.Errorf("ezone returned %d", resp.StatusCode)
	}
	return nil
}

// SystemCmd holds pointer fields so nil means "don't change"
type SystemCmd struct {
	State   *string  `json:"state"`
	Mode    *string  `json:"mode"`
	Fan     *string  `json:"fan"`
	SetTemp *float64 `json:"setTemp"`
}

// ZoneCmd holds pointer fields so nil means "don't change"
type ZoneCmd struct {
	State   *string  `json:"state"`
	Value   *int     `json:"value"`
	SetTemp *float64 `json:"setTemp,omitempty"`
}

var zoneKeys = []string{"z01", "z02", "z03", "z04", "z05", "z06", "z07", "z08", "z09"}

func buildSystemPayload(cmd SystemCmd) any {
	info := map[string]any{}
	if cmd.State != nil {
		info["state"] = *cmd.State
	}
	if cmd.Mode != nil {
		info["mode"] = *cmd.Mode
	}
	if cmd.Fan != nil {
		info["fan"] = *cmd.Fan
	}
	if cmd.SetTemp != nil {
		info["setTemp"] = *cmd.SetTemp
	}
	return map[string]any{"ac1": map[string]any{"info": info}}
}

func buildZonePayload(zoneId string, cmd ZoneCmd) any {
	zone := map[string]any{}
	if cmd.State != nil {
		zone["state"] = *cmd.State
	}
	if cmd.Value != nil {
		zone["value"] = *cmd.Value
	} else if cmd.SetTemp != nil {
		zone["value"] = int(*cmd.SetTemp)
	}
	return map[string]any{"ac1": map[string]any{"zones": map[string]any{zoneId: zone}}}
}
