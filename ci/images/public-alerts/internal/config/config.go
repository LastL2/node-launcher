package config

import (
	"fmt"

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
		ThornodeAPI string `mapstructure:"thornodeapi"`
	} `mapstructure:"endpoints"`
	Webhooks struct {
		Activity Webhooks `mapstructure:"activity"`
		Info     Webhooks `mapstructure:"info"`
		Updates  Webhooks `mapstructure:"updates"`
		Security Webhooks `mapstructure:"security"`
		Errors   Webhooks `mapstructure:"errors"`
	} `mapstructure:"webhooks"`
	// each monitor can have its own configuration params
	ChainLagMonitor ChainLagMonitorConfig
}

////////////////////////////////////////////////////////////////////////////////
// Helpers
////////////////////////////////////////////////////////////////////////////////

// Try to bind an environment variable to a viper key.
func ensureBindEnv(key, envVar string) {
	if err := viper.BindEnv(key, envVar); err != nil {
		log.Fatal().Err(err).Msgf("Failed to bind environment variable for %s", key)
	}
}

////////////////////////////////////////////////////////////////////////////////
// Init
////////////////////////////////////////////////////////////////////////////////

var config Config

func init() {
	viper.AutomaticEnv()
	viper.SetDefault("endpoints.thornodeapi", "https://thornode.ninerealms.com")
	viper.SetEnvPrefix("public_alert") // Prefix for environment variables

	// Use the newly named utility function to bind environment variables
	ensureBindEnv("endpoints.thornodeapi", "PUBLIC_ALERT_ENDPOINTS_THORNODE_API")
	ensureBindEnv("webhooks.activity.slack", "PUBLIC_ALERT_WEBHOOKS_ACTIVITY_SLACK")
	ensureBindEnv("webhooks.errors.slack", "PUBLIC_ALERT_WEBHOOKS_ERRORS_SLACK")
	ensureBindEnv("webhooks.activity.discord", "PUBLIC_ALERT_WEBHOOKS_ACTIVITY_DISCORD")

	// Initialize ChainLagMonitor with hardcoded values
	config.ChainLagMonitor = NewChainLagMonitorConfig()

	// Unmarshal the configuration into the config struct
	if err := viper.Unmarshal(&config); err != nil {
		log.Fatal().Err(err).Msg("Unable to unmarshal config")
	}
}

func Get() Config {
	return config
}
