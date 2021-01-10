package main

import (
	"fmt"
	"log"
	"net/http"
	"strings"

	"github.com/egnd/cookbook/internal/commands"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

var appVersion = "dev"

func main() {
	// define services
	var cfg *viper.Viper
	var logger *zap.Logger
	app := &cobra.Command{
		Use:     "cookbook",
		Long:    "Cookbook application",
		Version: appVersion,
		PersistentPreRunE: func(cmd *cobra.Command, args []string) (err error) {
			cfgPath, _ := cmd.Flags().GetString("config")
			cfgPrefix, _ := cmd.Flags().GetString("var-prefix")

			if cfg, err = InitConfig(cfgPath, cfgPrefix); err != nil {
				return
			}

			logger, err = InitLogger(cfg)

			return
		},
	}
	app.PersistentFlags().String("config", "configs/app.yml", "Config file path.")
	app.PersistentFlags().String("var-prefix", "CB", "Prefix for env variables.")

	// define commands
	app.AddCommand(
		&cobra.Command{
			Use:   "run",
			Short: "Run cookbook web app",
			RunE: func(cmd *cobra.Command, args []string) (err error) {
				http.HandleFunc("/", func(w http.ResponseWriter, req *http.Request) {
					fmt.Fprintf(w, "Hello, World!")
				})
				err = http.ListenAndServe(fmt.Sprintf(":%d", cfg.GetInt("app.port")), nil)

				return
			},
		},
		&cobra.Command{
			Use:   "import",
			Short: "Import recipes",
			RunE:  commands.NewCmd(), // @TODO:
		},
		&cobra.Command{
			Use:   "dump",
			Short: "Dump recipes",
			RunE:  commands.NewCmd(), // @TODO:
		},
	)

	// run app
	if err := app.Execute(); err != nil {
		if logger == nil {
			log.Fatal(err)
		}
		logger.Fatal("", zap.Error(err))
	}
}

func InitConfig(path string, prefix string) (cfg *viper.Viper, err error) {
	cfg = viper.New()
	cfg.SetEnvPrefix(prefix)
	cfg.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
	cfg.AutomaticEnv()
	cfg.SetConfigFile(path)
	err = cfg.ReadInConfig()
	return
}

func InitLogger(cfg *viper.Viper) (*zap.Logger, error) {
	var loggerCfg zap.Config
	switch cfg.GetString("logging.format") {
	case "pretty":
		loggerCfg = zap.NewDevelopmentConfig()
		loggerCfg.EncoderConfig.EncodeLevel = zapcore.CapitalColorLevelEncoder
	default:
		loggerCfg = zap.NewProductionConfig()
	}
	return loggerCfg.Build()
}
