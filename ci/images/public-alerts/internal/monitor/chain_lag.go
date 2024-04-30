package monitor

import (
	"encoding/json"
	"fmt"
	"net/http"
	"public-alerts/internal/config"
	"public-alerts/internal/notify"
	"strings"
	"time"

	"github.com/rs/zerolog/log"
	openapi "gitlab.com/thorchain/thornode/openapi/gen"
)

var (
	lastChainLag = make(map[string]int)
	lastAlert    = time.Now()
)

type ChainLagMonitor struct {
}

func (clm *ChainLagMonitor) Name() string {
	return "ChainLagMonitor"
}

func max(slice []int) int {
	max := slice[0]
	for _, v := range slice {
		if v > max {
			max = v
		}
	}
	return max
}

func (clm *ChainLagMonitor) Check() ([]notify.Alert, error) {

	alerts, err := checkChainLag()
	return alerts, err

}

func checkChainLag() ([]notify.Alert, error) {
	// checks chain lag by comparing the heights of all nodes
	log.Logger.Info().Msg("[Info] Checking chain lag...")
	cfg := config.Get()

	maxChainLag := cfg.ChainLagMonitor.MaxChainLag

	var nodes []openapi.Node

	// TODO: abstract http requests into a common function, thornode utility
	resp, err := http.Get(fmt.Sprintf("%s/thorchain/nodes", cfg.Endpoints.ThornodeAPI))
	if err != nil {
		return nil, fmt.Errorf("error making request: %w", err)
	}
	defer resp.Body.Close()

	dec := json.NewDecoder(resp.Body)
	if err := dec.Decode(&nodes); err != nil {
		return nil, fmt.Errorf("error decoding JSON: %w", err)
	}

	chainHeights := make(map[string][]int)
	activeNodes := 0
	for _, node := range nodes {
		if node.Status != "Active" {
			continue
		}
		for _, c := range node.ObserveChains {
			chainHeights[c.Chain] = append(chainHeights[c.Chain], int(c.GetHeight()))
		}
		activeNodes++
	}

	// check the difference between the highest and lowest node for each chain
	var msgs []string
	for chain, heights := range chainHeights {
		maxLag, ok := maxChainLag[chain]

		if !ok {
			continue
		}

		maxHeight := max(heights)
		lagCount := 0
		for _, h := range heights {
			if maxHeight-h > maxLag {
				lagCount++
			}
		}

		if lagCount > activeNodes/4 {
			lastLag := lastChainLag[chain]
			if lastLag < 3 { // must fail 3 checks in a row
				lastChainLag[chain]++
				continue
			}

			log.Warn().
				Str("chain", chain).
				Int("maxLag", maxLag).
				Int("lagCount", lagCount).
				Msg("Lagging by over maxLag blocks on lagCount nodes.")

			msgs = append(msgs, fmt.Sprintf("[%s] Lagging by over %d blocks on %d nodes.", chain, maxLag, lagCount))
		} else {
			lastChainLag[chain] = 0
		}
	}

	if len(msgs) > 0 && time.Since(lastAlert) > time.Hour {
		msg := "```" + fmt.Sprintln(strings.Join(msgs, "\n")) + "```"
		lastAlert = time.Now()

		// return alerts, can add more based on severity
		alerts := []notify.Alert{
			{Webhooks: config.Get().Webhooks.Activity, Message: msg},
		}
		return alerts, nil

	}
	return nil, nil
}
