//nolint:funcorder // constructor is kept near handler setup for readability
package internal

import (
	"context"
	"errors"
	"net/http"
	"strconv"
	"strings"
	"time"
	"unicode"

	"github.com/creachadair/jrpc2"
	"github.com/creachadair/jrpc2/handler"
	"github.com/creachadair/jrpc2/jhttp"
	"github.com/go-chi/chi/middleware"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/rs/cors"

	protocol "github.com/stellar/go-stellar-sdk/protocols/rpc"
	"github.com/stellar/go-stellar-sdk/support/log"
	"github.com/stellar/go-stellar-sdk/xdr"

	"github.com/stellar/stellar-rpc/cmd/stellar-rpc/internal/config"
	"github.com/stellar/stellar-rpc/cmd/stellar-rpc/internal/daemon/interfaces"
	"github.com/stellar/stellar-rpc/cmd/stellar-rpc/internal/db"
	"github.com/stellar/stellar-rpc/cmd/stellar-rpc/internal/feewindow"
	"github.com/stellar/stellar-rpc/cmd/stellar-rpc/internal/methods"
	"github.com/stellar/stellar-rpc/cmd/stellar-rpc/internal/network"
	"github.com/stellar/stellar-rpc/cmd/stellar-rpc/internal/rpcdatastore"
)

const (
	// maxHTTPRequestSize defines the largest request size that the http handler
	// would be willing to accept before dropping the request. The implementation
	// uses the default MaxBytesHandler to limit the request size.
	maxHTTPRequestSize          = 512 * 1024 // half a megabyte
	warningThresholdDenominator = 3

	// Decoded output size limits for XDR unmarshaling of user-supplied input.
	ledgerKeyDecodeMaxMemory   = 16 * 1024   // 16 KB
	transactionDecodeMaxMemory = 1024 * 1024 // 1 MB
)

// Handler is the HTTP handler which serves the Soroban JSON RPC responses
type Handler struct {
	http.Handler

	bridge jhttp.Bridge
	logger *log.Entry
}

// Close closes all the resources held by the Handler instances.
// After Close is called the Handler instance will stop accepting JSON RPC requests.
func (h Handler) Close() {
	if err := h.bridge.Close(); err != nil {
		h.logger.WithError(err).Warn("could not close bridge")
	}
}

type HandlerParams struct {
	FeeStatWindows        *feewindow.FeeWindows
	TransactionReader     db.TransactionReader
	EventReader           db.EventReader
	LedgerReader          db.LedgerReader
	Logger                *log.Entry
	PreflightGetter       methods.PreflightGetter
	Daemon                interfaces.Daemon
	DataStoreLedgerReader rpcdatastore.LedgerReader
}

func decorateHandlers(daemon interfaces.Daemon, logger *log.Entry, m handler.Map) handler.Map {
	requestMetric := prometheus.NewSummaryVec(prometheus.SummaryOpts{
		Namespace:  daemon.MetricsNamespace(),
		Subsystem:  "json_rpc",
		Name:       "request_duration_seconds",
		Help:       "JSON RPC request duration",
		Objectives: map[float64]float64{0.5: 0.05, 0.9: 0.01, 0.99: 0.001},
	}, []string{"endpoint", "status"})
	decorated := handler.Map{}
	for endpoint, h := range m {
		decorated[endpoint] = handler.New(func(ctx context.Context, r *jrpc2.Request) (any, error) {
			reqID := strconv.FormatUint(middleware.NextRequestID(), 10)
			logRequest(logger, reqID, r)
			startTime := time.Now()
			result, err := h(ctx, r)
			duration := time.Since(startTime)
			label := prometheus.Labels{"endpoint": r.Method(), "status": "ok"}
			simulateTransactionResponse, ok := result.(protocol.SimulateTransactionResponse)
			if ok && simulateTransactionResponse.Error != "" {
				label["status"] = "error"
			} else if err != nil {
				var jsonRPCErr *jrpc2.Error
				if errors.As(err, &jsonRPCErr) {
					prometheusLabelReplacer := strings.NewReplacer(" ", "_", "-", "_", "(", "", ")", "")
					status := prometheusLabelReplacer.Replace(jsonRPCErr.Code.String())
					label["status"] = status
				}
			}
			requestMetric.With(label).Observe(duration.Seconds())
			logResponse(logger, reqID, duration, label["status"])
			return result, err
		})
	}
	daemon.MetricsRegistry().MustRegister(requestMetric)
	return decorated
}

func logRequest(logger *log.Entry, reqID string, req *jrpc2.Request) {
	logger = logger.WithFields(log.F{
		"subsys":   "jsonrpc",
		"req":      reqID,
		"json_req": req.ID(),
		"method":   req.Method(),
	})
	logger.Info("starting JSONRPC request")

	// Params are useful but can be really verbose, let's only print them in debug level
	logger = logger.WithField("params", req.ParamString())
	logger.Debug("starting JSONRPC request params")
}

func logResponse(logger *log.Entry, reqID string, duration time.Duration, status string) {
	logger = logger.WithFields(log.F{
		"subsys":   "jsonrpc",
		"req":      reqID,
		"duration": duration.String(),
		"json_req": reqID,
		"status":   status,
	})
	logger.Info("finished JSONRPC request")
}

func toSnakeCase(s string) string {
	var result strings.Builder
	result.Grow(len(s) * 2)
	for _, v := range s {
		if unicode.IsUpper(v) {
			result.WriteByte('_')
		}
		result.WriteRune(v)
	}
	return strings.ToLower(result.String())
}

// NewJSONRPCHandler constructs a Handler instance
func NewJSONRPCHandler(cfg *config.Config, params HandlerParams) Handler {
	bridgeOptions := jhttp.BridgeOptions{
		Server: &jrpc2.ServerOptions{
			Logger: func(text string) { params.Logger.Debug(text) },
			// Disable built-in rpc.* methods (e.g. rpc.serverInfo) that
			// bypass the handler allowlist and request limiters.
			DisableBuiltin: true,
		},
	}

	retentionWindow := cfg.HistoryRetentionWindow

	handlers := []struct {
		methodName           string
		underlyingHandler    jrpc2.Handler
		queueLimit           uint
		longName             string
		requestDurationLimit time.Duration
	}{
		{
			methodName: protocol.GetHealthMethodName,
			underlyingHandler: methods.NewHealthCheck(
				retentionWindow, params.LedgerReader, cfg.MaxHealthyLedgerLatency),
			longName:             toSnakeCase(protocol.GetHealthMethodName),
			queueLimit:           cfg.RequestBacklogGetHealthQueueLimit,
			requestDurationLimit: cfg.MaxGetHealthExecutionDuration,
		},
		{
			methodName: protocol.GetEventsMethodName,
			underlyingHandler: methods.NewGetEventsHandler(
				params.Logger,
				params.EventReader,
				cfg.MaxEventsLimit,
				cfg.DefaultEventsLimit,
				params.LedgerReader,
			),

			longName:             toSnakeCase(protocol.GetEventsMethodName),
			queueLimit:           cfg.RequestBacklogGetEventsQueueLimit,
			requestDurationLimit: cfg.MaxGetEventsExecutionDuration,
		},
		{
			methodName: protocol.GetNetworkMethodName,
			underlyingHandler: methods.NewGetNetworkHandler(
				cfg.NetworkPassphrase,
				cfg.FriendbotURL,
				params.LedgerReader,
			),
			longName:             toSnakeCase(protocol.GetNetworkMethodName),
			queueLimit:           cfg.RequestBacklogGetNetworkQueueLimit,
			requestDurationLimit: cfg.MaxGetNetworkExecutionDuration,
		},
		{
			methodName: protocol.GetVersionInfoMethodName,
			underlyingHandler: methods.NewGetVersionInfoHandler(params.Logger,
				params.LedgerReader, params.Daemon),
			longName:             toSnakeCase(protocol.GetVersionInfoMethodName),
			queueLimit:           cfg.RequestBacklogGetVersionInfoQueueLimit,
			requestDurationLimit: cfg.MaxGetVersionInfoExecutionDuration,
		},
		{
			methodName:           protocol.GetLatestLedgerMethodName,
			underlyingHandler:    methods.NewGetLatestLedgerHandler(params.LedgerReader),
			longName:             toSnakeCase(protocol.GetLatestLedgerMethodName),
			queueLimit:           cfg.RequestBacklogGetLatestLedgerQueueLimit,
			requestDurationLimit: cfg.MaxGetLatestLedgerExecutionDuration,
		},
		{
			methodName: protocol.GetLedgersMethodName,
			underlyingHandler: methods.NewGetLedgersHandler(params.LedgerReader,
				cfg.MaxLedgersLimit, cfg.DefaultLedgersLimit, params.DataStoreLedgerReader, params.Logger),
			longName:             toSnakeCase(protocol.GetLedgersMethodName),
			queueLimit:           cfg.RequestBacklogGetLedgersQueueLimit,
			requestDurationLimit: cfg.MaxGetLedgersExecutionDuration,
		},
		{
			methodName: protocol.GetLedgerEntriesMethodName,
			underlyingHandler: methods.NewGetLedgerEntriesHandler(params.Logger,
				params.Daemon.FastCoreClient(), params.LedgerReader,
				xdr.DecodeOptions{MaxMemoryBytes: ledgerKeyDecodeMaxMemory}),
			longName:             toSnakeCase(protocol.GetLedgerEntriesMethodName),
			queueLimit:           cfg.RequestBacklogGetLedgerEntriesQueueLimit,
			requestDurationLimit: cfg.MaxGetLedgerEntriesExecutionDuration,
		},
		{
			methodName:           protocol.GetTransactionMethodName,
			underlyingHandler:    methods.NewGetTransactionHandler(params.Logger, params.TransactionReader, params.LedgerReader),
			longName:             toSnakeCase(protocol.GetTransactionMethodName),
			queueLimit:           cfg.RequestBacklogGetTransactionQueueLimit,
			requestDurationLimit: cfg.MaxGetTransactionExecutionDuration,
		},
		{
			methodName: protocol.GetTransactionsMethodName,
			underlyingHandler: methods.NewGetTransactionsHandler(params.Logger, params.LedgerReader,
				cfg.MaxTransactionsLimit, cfg.DefaultTransactionsLimit, cfg.NetworkPassphrase),
			longName:             toSnakeCase(protocol.GetTransactionsMethodName),
			queueLimit:           cfg.RequestBacklogGetTransactionsQueueLimit,
			requestDurationLimit: cfg.MaxGetTransactionsExecutionDuration,
		},
		{
			methodName: protocol.SendTransactionMethodName,
			underlyingHandler: methods.NewSendTransactionHandler(
				params.Daemon, params.Logger, params.LedgerReader, cfg.NetworkPassphrase,
				xdr.DecodeOptions{MaxMemoryBytes: transactionDecodeMaxMemory}),
			longName:             toSnakeCase(protocol.SendTransactionMethodName),
			queueLimit:           cfg.RequestBacklogSendTransactionQueueLimit,
			requestDurationLimit: cfg.MaxSendTransactionExecutionDuration,
		},
		{
			methodName: protocol.SimulateTransactionMethodName,
			underlyingHandler: methods.NewSimulateTransactionHandler(
				params.Logger, params.LedgerReader,
				params.Daemon.FastCoreClient(), params.PreflightGetter,
				xdr.DecodeOptions{MaxMemoryBytes: transactionDecodeMaxMemory}),

			longName:             toSnakeCase(protocol.SimulateTransactionMethodName),
			queueLimit:           cfg.RequestBacklogSimulateTransactionQueueLimit,
			requestDurationLimit: cfg.MaxSimulateTransactionExecutionDuration,
		},
		{
			methodName:           protocol.GetFeeStatsMethodName,
			underlyingHandler:    methods.NewGetFeeStatsHandler(params.FeeStatWindows, params.LedgerReader, params.Logger),
			longName:             toSnakeCase(protocol.GetFeeStatsMethodName),
			queueLimit:           cfg.RequestBacklogGetFeeStatsTransactionQueueLimit,
			requestDurationLimit: cfg.MaxGetFeeStatsExecutionDuration,
		},
	}
	handlersMap := handler.Map{}
	for _, handler := range handlers {
		queueLimiterGaugeName := handler.longName + "_inflight_requests"
		queueLimiterGaugeHelp := "Number of concurrenty in-flight " + handler.methodName + " requests"

		queueLimiterGauge := prometheus.NewGauge(prometheus.GaugeOpts{
			Namespace: params.Daemon.MetricsNamespace(), Subsystem: "network",
			Name: queueLimiterGaugeName,
			Help: queueLimiterGaugeHelp,
		})
		queueLimiter := network.MakeJrpcBacklogQueueLimiter(
			handler.underlyingHandler,
			queueLimiterGauge,
			uint64(handler.queueLimit),
			params.Logger)

		durationWarnCounterName := handler.longName + "_execution_threshold_warning"
		durationLimitCounterName := handler.longName + "_execution_threshold_limit"
		durationWarnCounterHelp := "The metric measures the count of " + handler.methodName +
			" requests that surpassed the warning threshold for execution time"
		durationLimitCounterHelp := "The metric measures the count of " + handler.methodName +
			" requests that surpassed the limit threshold for execution time"

		requestDurationWarnCounter := prometheus.NewCounter(prometheus.CounterOpts{
			Namespace: params.Daemon.MetricsNamespace(), Subsystem: "network",
			Name: durationWarnCounterName,
			Help: durationWarnCounterHelp,
		})
		requestDurationLimitCounter := prometheus.NewCounter(prometheus.CounterOpts{
			Namespace: params.Daemon.MetricsNamespace(), Subsystem: "network",
			Name: durationLimitCounterName,
			Help: durationLimitCounterHelp,
		})
		// set the warning threshold to be one third of the limit.
		requestDurationWarn := handler.requestDurationLimit / warningThresholdDenominator
		durationLimiter := network.MakeJrpcRequestDurationLimiter(
			queueLimiter.Handle,
			requestDurationWarn,
			handler.requestDurationLimit,
			requestDurationWarnCounter,
			requestDurationLimitCounter,
			params.Logger)
		handlersMap[handler.methodName] = durationLimiter.Handle
	}
	bridge := jhttp.NewBridge(decorateHandlers(
		params.Daemon,
		params.Logger,
		handlersMap),
		&bridgeOptions)

	// globalQueueRequestBacklogLimiter is a metric for measuring the total concurrent inflight requests
	globalQueueRequestBacklogLimiter := prometheus.NewGauge(prometheus.GaugeOpts{
		Namespace: params.Daemon.MetricsNamespace(), Subsystem: "network", Name: "global_inflight_requests",
		Help: "Number of concurrenty in-flight http requests",
	})

	queueLimitedBridge := network.MakeHTTPBacklogQueueLimiter(
		bridge,
		globalQueueRequestBacklogLimiter,
		uint64(cfg.RequestBacklogGlobalQueueLimit),
		params.Logger)

	globalQueueRequestExecutionDurationWarningCounter := prometheus.NewCounter(prometheus.CounterOpts{
		Namespace: params.Daemon.MetricsNamespace(),
		Subsystem: "network",
		Name:      "global_request_execution_duration_threshold_warning",
		Help:      "The metric measures the count of requests that surpassed the warning threshold for execution time",
	})
	globalQueueRequestExecutionDurationLimitCounter := prometheus.NewCounter(prometheus.CounterOpts{
		Namespace: params.Daemon.MetricsNamespace(),
		Subsystem: "network",
		Name:      "global_request_execution_duration_threshold_limit",
		Help:      "The metric measures the count of requests that surpassed the limit threshold for execution time",
	})
	handler := network.MakeHTTPRequestDurationLimiter(
		queueLimitedBridge,
		cfg.RequestExecutionWarningThreshold,
		cfg.MaxRequestExecutionDuration,
		globalQueueRequestExecutionDurationWarningCounter,
		globalQueueRequestExecutionDurationLimitCounter,
		params.Logger)

	handler = http.MaxBytesHandler(handler, maxHTTPRequestSize)

	corsMiddleware := cors.New(cors.Options{
		AllowedOrigins:         []string{},
		AllowOriginRequestFunc: func(*http.Request, string) bool { return true },
		AllowedHeaders:         []string{"*"},
		AllowedMethods:         []string{"GET", "PUT", "POST", "PATCH", "DELETE", "HEAD", "OPTIONS"},
	})

	return Handler{
		bridge:  bridge,
		logger:  params.Logger,
		Handler: corsMiddleware.Handler(handler),
	}
}
