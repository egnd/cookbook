package commands

import (
	"github.com/spf13/cobra"
	"go.uber.org/zap"
)

// ILogger is interface for logger instance.
type ILogger interface {
	Info(string, ...zap.Field)
	Warn(string, ...zap.Field)
	Error(string, ...zap.Field)
	Fatal(string, ...zap.Field)
	Debug(string, ...zap.Field)
	With(...zap.Field) *zap.Logger
}

type CmdHandler func(cmd *cobra.Command, args []string) error

func NewCmd() CmdHandler {
	return func(cmd *cobra.Command, args []string) (err error) {
		return
	}
}
