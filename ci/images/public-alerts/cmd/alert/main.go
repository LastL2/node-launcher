package main

import (
	"os"
	"public-alerts/internal/config"
	"public-alerts/internal/monitor"
	"public-alerts/internal/notify"
	"time"

	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
)

////////////////////////////////////////////////////////////////////////////////
// MAIN
////////////////////////////////////////////////////////////////////////////////

func main() {
	// Set logger
	// unix time and JSON logging in the cluster, otherwise make it pretty
	if _, err := os.Stat("/run/secrets/kubernetes.io"); err == nil {
		zerolog.TimeFieldFormat = zerolog.TimeFormatUnix
	} else {
		log.Logger = log.Output(zerolog.ConsoleWriter{Out: os.Stderr})
	}
	log.Logger = log.With().Caller().Logger()
	log.Info().Msg("Starting public-alerts")

	// Create Alert Channel
	alertQueue := make(chan notify.Alert, 1)

	// Chain Lag Monitor
	chainLagMonitor := &monitor.ChainLagMonitor{}
	// poll every 5 mins
	monitor.Spawn(chainLagMonitor, alertQueue, 5*time.Minute)

	// Spawn more monitors as needed...

	for alert := range alertQueue {
		notify.Notify(alert)
	}
	// alert if the queue is closed
	notify.Notify(notify.Alert{
		Webhooks: config.Get().Webhooks.Errors,
		Message:  "alertQueue was unexpectedly closed",
	},
	)
	log.Fatal().Msg("alertQueue was unexpectedly closed")

}
