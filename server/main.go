package main

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/joho/godotenv"
)

var db *sql.DB

func cors(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "*")

		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}

		next.ServeHTTP(w, r)
	})
}

func main() {
	_ = godotenv.Load()

	ezoneBase := os.Getenv("EZONE_BASE")
	if ezoneBase == "" {
		println("EZONE_BASE not set")
		os.Exit(1)
	}
	setEzoneBase(ezoneBase)

	port := os.Getenv("PORT")
	if port == "" {
		println("PORT not set")
		os.Exit(1)
	}

	db = initDB("./gogo.db")

	http.HandleFunc("/status", handleStatus)
	http.HandleFunc("/system", handleSystem)
	http.HandleFunc("/zones/", handleZone)
	http.HandleFunc("/schedules/past", handleDeletePast)
	http.HandleFunc("/schedules/", handleSchedule)
	http.HandleFunc("/schedules", handleSchedules)
	http.HandleFunc("/errors", handleListErrors)

	go runScheduler(db)

	println("Server listening on :" + port)
	http.ListenAndServe(":"+port, cors(http.DefaultServeMux))
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(v)
}

func handleStatus(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	data, err := getSystemData()
	if err != nil {
		logError(db, "ezoneClient", err.Error())
		http.Error(w, "ezone unreachable", http.StatusBadGateway)
		return
	}
	writeJSON(w, http.StatusOK, data)
}

func handleSystem(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	var cmd SystemCmd
	if err := json.NewDecoder(r.Body).Decode(&cmd); err != nil {
		logError(db, "handler", err.Error())
		http.Error(w, "bad request", http.StatusBadRequest)
		return
	}
	if err := setAircon(buildSystemPayload(cmd)); err != nil {
		logError(db, "ezoneClient", err.Error())
		http.Error(w, "ezone error", http.StatusBadGateway)
		return
	}
	w.WriteHeader(http.StatusOK)
}

func handleZone(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	zoneId := strings.TrimPrefix(r.URL.Path, "/zones/")
	if zoneId == "" {
		http.Error(w, "missing zoneId", http.StatusBadRequest)
		return
	}
	var cmd ZoneCmd
	if err := json.NewDecoder(r.Body).Decode(&cmd); err != nil {
		logError(db, "handler", err.Error())
		http.Error(w, "bad request", http.StatusBadRequest)
		return
	}
	if err := setAircon(buildZonePayload(zoneId, cmd)); err != nil {
		logError(db, "ezoneClient", err.Error())
		http.Error(w, "ezone error", http.StatusBadGateway)
		return
	}
	w.WriteHeader(http.StatusOK)
}

// handleSchedules handles GET and POST /schedules
func handleSchedules(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		handleListSchedules(w, r)
	case http.MethodPost:
		handleCreateSchedule(w, r)
	default:
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
	}
}

func handleListSchedules(w http.ResponseWriter, r *http.Request) {
	rows, err := listSchedules(db)
	if err != nil {
		logError(db, "handler", err.Error())
		http.Error(w, "db error", http.StatusInternalServerError)
		return
	}
	if rows == nil {
		rows = []Schedule{}
	}
	writeJSON(w, http.StatusOK, rows)
}

func handleCreateSchedule(w http.ResponseWriter, r *http.Request) {
	var s Schedule
	if err := json.NewDecoder(r.Body).Decode(&s); err != nil {
		logError(db, "handler", err.Error())
		http.Error(w, "bad request", http.StatusBadRequest)
		return
	}
	created, err := insertSchedule(db, s)
	if err != nil {
		logError(db, "handler", err.Error())
		http.Error(w, "db error", http.StatusInternalServerError)
		return
	}
	writeJSON(w, http.StatusCreated, created)
}

func handleDeletePast(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodDelete {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	if err := deletePastSchedules(db); err != nil {
		logError(db, "handler", err.Error())
		http.Error(w, "db error", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusOK)
}

// handleSchedule handles DELETE /schedules/{id} and POST /schedules/{id}/trigger
func handleSchedule(w http.ResponseWriter, r *http.Request) {
	idStr := strings.TrimPrefix(r.URL.Path, "/schedules/")
	if strings.HasSuffix(idStr, "/trigger") {
		handleTriggerSchedule(w, r, strings.TrimSuffix(idStr, "/trigger"))
		return
	}
	if r.Method != http.MethodDelete {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		http.Error(w, "invalid id", http.StatusBadRequest)
		return
	}
	if err := deleteSchedule(db, id); err != nil {
		logError(db, "handler", err.Error())
		http.Error(w, "db error", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusOK)
}

// handleTriggerSchedule handles POST /schedules/{id}/trigger: applies the
// schedule's payload to the e-zone unit immediately and hard-deletes the entry.
func handleTriggerSchedule(w http.ResponseWriter, r *http.Request, idStr string) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		http.Error(w, "invalid id", http.StatusBadRequest)
		return
	}
	s, err := getSchedule(db, id)
	if err != nil {
		logError(db, "handler", err.Error())
		http.Error(w, "db error", http.StatusInternalServerError)
		return
	}
	if s == nil {
		http.Error(w, "not found", http.StatusNotFound)
		return
	}
	if err := setAircon(scheduleToPayload(*s)); err != nil {
		logError(db, "scheduler", err.Error())
	}
	if err := deleteSchedule(db, id); err != nil {
		logError(db, "handler", err.Error())
		http.Error(w, "db error", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusOK)
}

func handleListErrors(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodDelete {
		if err := deleteAllErrors(db); err != nil {
			logError(db, "handler", err.Error())
			http.Error(w, "db error", http.StatusInternalServerError)
			return
		}
		w.WriteHeader(http.StatusOK)
		return
	}
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	errs, err := listErrors(db)
	if err != nil {
		http.Error(w, "db error", http.StatusInternalServerError)
		return
	}
	if errs == nil {
		errs = []AppError{}
	}
	writeJSON(w, http.StatusOK, errs)
}

func runScheduler(db *sql.DB) {
	ticker := time.NewTicker(30 * time.Second)
	for range ticker.C {
		now := time.Now().Unix()
		entries, err := pendingSchedules(db, now)
		if err != nil {
			logError(db, "scheduler", err.Error())
			continue
		}
		for _, s := range entries {
			payload := scheduleToPayload(s)
			if err := setAircon(payload); err != nil {
				logError(db, "scheduler", err.Error())
			}
			if err := markFired(db, s.ID, now); err != nil {
				logError(db, "scheduler", err.Error())
			}
		}
	}
}

func scheduleToPayload(s Schedule) any {
	info := map[string]any{}
	if s.State != nil {
		info["state"] = *s.State
	}
	if s.Mode != nil {
		info["mode"] = *s.Mode
	}
	if s.Fan != nil {
		info["fan"] = *s.Fan
	}
	if s.SetTemp != nil {
		info["setTemp"] = *s.SetTemp
	}
	payload := map[string]any{"ac1": map[string]any{}}
	ac1 := payload["ac1"].(map[string]any)
	if len(info) > 0 {
		ac1["info"] = info
	}
	if len(s.Zones) > 0 {
		var zonesPayload map[string]any
		if err := json.Unmarshal(s.Zones, &zonesPayload); err == nil {
			if existing, ok := ac1["zones"].(map[string]any); ok {
				for k, v := range zonesPayload {
					existing[k] = v
				}
			} else {
				ac1["zones"] = zonesPayload
			}
		}
	}
	return payload
}
