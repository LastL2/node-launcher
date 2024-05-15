package config

import (
	"fmt"
	"strings"

	"github.com/rs/zerolog/log"
	"github.com/spf13/viper"
)

////////////////////////////////////////////////////////////////////////////////
// Monitor Configuration
////////////////////////////////////////////////////////////////////////////////

type MonitorConfig interface {
	Validate() error // Validates the monitor-specific configuration
}

// ///////////////////////
// ChainLagMonitorConfig
// ///////////////////////
type ChainLagMonitorConfig struct {
	MaxChainLag map[string]int
}

func (c ChainLagMonitorConfig) Validate() error {
	// Iterate over the map and check if any values are 0
	for k, v := range c.MaxChainLag {
		if v == 0 {
			// Use fmt.Errorf to format the error message with the chain key
			return fmt.Errorf("ChainLag Monitor testValue cannot be 0 for chain %s", k)
		}
	}

	return nil
}

// NewChainLagMonitorConfig creates a new ChainLagMonitorConfig with default settings.
func NewChainLagMonitorConfig() ChainLagMonitorConfig {
	return ChainLagMonitorConfig{
		MaxChainLag: map[string]int{
			"BCH":  3,
			"BTC":  3,
			"BNB":  1800,
			"DOGE": 30,
			"ETH":  70,
			"LTC":  6,
			"GAIA": 175,
			"AVAX": 900,
		},
	}
}

/////////////////////////
// SolvencyMonitorConfig
/////////////////////////

type SolvencyMonitorConfig struct {
	AlertWindowThreshold  int
	AlertPercentThreshold float64
	AlertUSDThreshold     float64
	AlertCooldownSeconds  int
}

func (s SolvencyMonitorConfig) Validate() error {
	// TODO: Implement validation

	return nil
}

// NewSolvencyMonitorConfig creates a new SolvencyMonitorConfig with default settings.
func NewSolvencyMonitorConfig() SolvencyMonitorConfig {
	return SolvencyMonitorConfig{
		AlertWindowThreshold:  60,
		AlertPercentThreshold: 0.02,
		AlertUSDThreshold:     5000,
		AlertCooldownSeconds:  60 * 60 * 12, // 12 hours
	}
}

// ///////////////////////
// StuckOutboundMonitorConfig
// ///////////////////////
type StuckOutboundMonitorConfig struct {
	BlockAgeThreshold int
}

func (sobm StuckOutboundMonitorConfig) Validate() error {
	// TODO(Orion): add validation
	return nil
}

func NewStuckOutboundMonitorConfig() StuckOutboundMonitorConfig {
	return StuckOutboundMonitorConfig{
		BlockAgeThreshold: 7200, // ~12 hours
	}
}

////////////////////////////////////////////////////////////////////////////////
// Configuration
////////////////////////////////////////////////////////////////////////////////

type Webhooks struct {
	Slack     string `mapstructure:"slack"`
	Discord   string `mapstructure:"discord"`
	PagerDuty string `mapstructure:"pagerduty"`
}

type Config struct {
	Endpoints struct {
		ThornodeAPI   string `mapstructure:"thornode_api"`
		ThornodeRPC   string `mapstructure:"thornode_rpc"`
		NineRealmsAPI string `mapstructure:"ninerealms_api"`
		MidgardAPI    string `mapstructure:"midgard_api"`
		ExplorerURL   string `mapstructure:"explorer_url"`
	} `mapstructure:"endpoints"`
	Webhooks struct {
		Activity Webhooks `mapstructure:"activity"`
		Info     Webhooks `mapstructure:"info"`
		Updates  Webhooks `mapstructure:"updates"`
		Security Webhooks `mapstructure:"security"`
		Errors   Webhooks `mapstructure:"errors"`
	} `mapstructure:"webhooks"`
	// each monitor can have its own configuration params
	ChainLagMonitor      ChainLagMonitorConfig
	SolvencyMonitor      SolvencyMonitorConfig
	StuckOutboundMonitor StuckOutboundMonitorConfig
}

// //////////////////////////////////////////////////////////////////////////////
// Init
// //////////////////////////////////////////////////////////////////////////////
var config Config

func init() {

	assert := func(err error) {
		if err != nil {
			log.Fatal().Err(err).Msg("Failed to bind environment variable")
		}
	}

	viper.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
	viper.AutomaticEnv()

	// Initialize ChainLagMonitor with hardcoded values
	config.ChainLagMonitor = NewChainLagMonitorConfig()
	config.SolvencyMonitor = NewSolvencyMonitorConfig()
	config.StuckOutboundMonitor = NewStuckOutboundMonitorConfig()

	assert(viper.BindEnv("endpoints.thornode_api", "ENDPOINTS_THORNODE_API"))
	assert(viper.BindEnv("endpoints.thornode_rpc", "ENDPOINTS_THORNODE_RPC"))
	assert(viper.BindEnv("endpoints.ninerealms_api", "ENDPOINTS_NINEREALMS_API"))
	assert(viper.BindEnv("endpoints.midgard_api", "ENDPOINTS_MIDGARD_API"))
	// EXPLORER_URL = "https://runescan.io/tx"
	assert(viper.BindEnv("endpoints.explorer_url", "ENDPOINTS_EXPLORER_URL"))
	assert(viper.BindEnv("webhooks.activity.slack", "WEBHOOKS_ACTIVITY_SLACK"))
	assert(viper.BindEnv("webhooks.activity.discord", "WEBHOOKS_ACTIVITY_DISCORD"))
	assert(viper.BindEnv("webhooks.errors.slack", "WEBHOOKS_ERRORS_SLACK"))

	// Unmarshal the configuration into the config struct
	if err := viper.Unmarshal(&config); err != nil {
		log.Fatal().Err(err).Msg("Unable to unmarshal config")
	}
}

func Get() Config {
	return config
}
