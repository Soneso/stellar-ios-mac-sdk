#!/usr/bin/env python3
"""
Horizon API Query Parameters Dictionary

This module contains a comprehensive mapping of all Horizon API endpoints
to their supported query parameters, extracted from the Horizon Go codebase.

Source: https://github.com/stellar/stellar-horizon
Analyzed from: internal/actions/*.go files
Last Updated: 2026-01-06

Each entry is a tuple of (endpoint_path, http_method) mapping to a list of
supported query parameter names.

Standard Pagination Parameters (included where applicable):
- cursor: Pagination cursor for result set navigation
- limit: Maximum number of records to return
- order: Sort order (asc/desc)

Author: Generated for Stellar iOS/Mac SDK Compatibility Matrix
"""

from typing import Dict, List, Tuple

# Standard pagination parameters used across most list endpoints
PAGINATION_PARAMS = ["cursor", "limit", "order"]

# Complete mapping of Horizon endpoints to their query parameters
HORIZON_PARAMS: Dict[Tuple[str, str], List[str]] = {
    # ========================================================================
    # Core Endpoints
    # ========================================================================
    ("/", "GET"): [],
    ("/health", "GET"): [],

    # ========================================================================
    # Account Endpoints
    # ========================================================================
    ("/accounts", "GET"): [
        "signer",           # Filter by signer account ID
        "asset",            # Filter by asset (format: code:issuer or native)
        "sponsor",          # Filter by sponsor account ID
        "liquidity_pool",   # Filter by liquidity pool ID (SHA256)
        *PAGINATION_PARAMS
    ],
    ("/accounts/{account_id}", "GET"): [],  # No query params, only path param
    ("/accounts/{account_id}/data/{key}", "GET"): [],
    ("/accounts/{account_id}/offers", "GET"): PAGINATION_PARAMS,
    ("/accounts/{account_id}/trades", "GET"): PAGINATION_PARAMS,
    ("/accounts/{account_id}/effects", "GET"): PAGINATION_PARAMS,
    ("/accounts/{account_id}/operations", "GET"): [
        "include_failed",   # Include failed transactions
        "join",            # Join related resources (e.g., "transactions")
        *PAGINATION_PARAMS
    ],
    ("/accounts/{account_id}/payments", "GET"): [
        "include_failed",
        "join",
        *PAGINATION_PARAMS
    ],
    ("/accounts/{account_id}/transactions", "GET"): [
        "include_failed",
        *PAGINATION_PARAMS
    ],

    # ========================================================================
    # Asset Endpoints
    # ========================================================================
    ("/assets", "GET"): [
        "asset_code",      # Filter by asset code
        "asset_issuer",    # Filter by asset issuer
        *PAGINATION_PARAMS
    ],

    # ========================================================================
    # Claimable Balance Endpoints
    # ========================================================================
    ("/claimable_balances", "GET"): [
        "asset",           # Filter by asset (native or code:issuer)
        "sponsor",         # Filter by sponsor account ID
        "claimant",        # Filter by claimant account ID
        *PAGINATION_PARAMS
    ],
    ("/claimable_balances/{id}", "GET"): [],
    ("/claimable_balances/{id}/transactions", "GET"): [
        "include_failed",
        *PAGINATION_PARAMS
    ],
    ("/claimable_balances/{id}/operations", "GET"): [
        "include_failed",
        "join",
        *PAGINATION_PARAMS
    ],

    # ========================================================================
    # Effects Endpoints
    # ========================================================================
    ("/effects", "GET"): PAGINATION_PARAMS,

    # ========================================================================
    # Fee Stats Endpoint
    # ========================================================================
    ("/fee_stats", "GET"): [],

    # ========================================================================
    # Ledger Endpoints
    # ========================================================================
    ("/ledgers", "GET"): PAGINATION_PARAMS,
    ("/ledgers/{ledger_id}", "GET"): [],
    ("/ledgers/{ledger_id}/transactions", "GET"): [
        "include_failed",
        *PAGINATION_PARAMS
    ],
    ("/ledgers/{ledger_id}/operations", "GET"): [
        "include_failed",
        "join",
        *PAGINATION_PARAMS
    ],
    ("/ledgers/{ledger_id}/payments", "GET"): [
        "include_failed",
        "join",
        *PAGINATION_PARAMS
    ],
    ("/ledgers/{ledger_id}/effects", "GET"): PAGINATION_PARAMS,

    # ========================================================================
    # Liquidity Pool Endpoints
    # ========================================================================
    ("/liquidity_pools", "GET"): [
        "reserves",        # Filter by reserves (comma-separated assets)
        "account",         # Filter by account
        *PAGINATION_PARAMS
    ],
    ("/liquidity_pools/{liquidity_pool_id}", "GET"): [],
    ("/liquidity_pools/{liquidity_pool_id}/transactions", "GET"): [
        "include_failed",
        *PAGINATION_PARAMS
    ],
    ("/liquidity_pools/{liquidity_pool_id}/operations", "GET"): [
        "include_failed",
        "join",
        *PAGINATION_PARAMS
    ],
    ("/liquidity_pools/{liquidity_pool_id}/effects", "GET"): PAGINATION_PARAMS,
    ("/liquidity_pools/{liquidity_pool_id}/trades", "GET"): PAGINATION_PARAMS,

    # ========================================================================
    # Offer Endpoints
    # ========================================================================
    ("/offers", "GET"): [
        "seller",          # Filter by seller account ID
        "selling",         # Filter by selling asset
        "buying",          # Filter by buying asset
        "sponsor",         # Filter by sponsor account ID
        *PAGINATION_PARAMS
    ],
    ("/offers/{offer_id}", "GET"): [],
    ("/offers/{offer_id}/trades", "GET"): PAGINATION_PARAMS,

    # ========================================================================
    # Operation Endpoints
    # ========================================================================
    ("/operations", "GET"): [
        "include_failed",
        "join",
        *PAGINATION_PARAMS
    ],
    ("/operations/{op_id}", "GET"): [
        "join",            # Join related resources (e.g., "transactions")
    ],
    ("/operations/{op_id}/effects", "GET"): PAGINATION_PARAMS,

    # ========================================================================
    # Order Book Endpoint
    # ========================================================================
    ("/order_book", "GET"): [
        "selling_asset_type",    # Asset type for selling side
        "selling_asset_code",    # Asset code for selling side
        "selling_asset_issuer",  # Asset issuer for selling side
        "buying_asset_type",     # Asset type for buying side
        "buying_asset_code",     # Asset code for buying side
        "buying_asset_issuer",   # Asset issuer for buying side
        "limit",                 # Max results (default: 20, max: 200)
    ],

    # ========================================================================
    # Path Finding Endpoints
    # ========================================================================
    ("/paths", "GET"): [
        # Deprecated - redirects to /paths/strict-receive
        "source_account",
        "source_assets",
        "destination_account",
        "destination_asset_type",
        "destination_asset_code",
        "destination_asset_issuer",
        "destination_amount",
    ],
    ("/paths/strict-receive", "GET"): [
        "source_account",           # Source account ID (optional)
        "source_assets",            # Comma-separated list of source assets
        "destination_account",      # Destination account ID (optional)
        "destination_asset_type",   # Destination asset type
        "destination_asset_code",   # Destination asset code
        "destination_asset_issuer", # Destination asset issuer (optional)
        "destination_amount",       # Amount to be received
    ],
    ("/paths/strict-send", "GET"): [
        "source_asset_type",    # Source asset type
        "source_asset_code",    # Source asset code
        "source_asset_issuer",  # Source asset issuer (optional)
        "source_amount",        # Amount to be sent
        "destination_account",  # Destination account ID (optional)
        "destination_assets",   # Comma-separated list of destination assets
    ],

    # ========================================================================
    # Payment Endpoints
    # ========================================================================
    ("/payments", "GET"): [
        "include_failed",
        "join",
        *PAGINATION_PARAMS
    ],

    # ========================================================================
    # Trade Endpoints
    # ========================================================================
    ("/trades", "GET"): [
        "offer_id",             # Filter by offer ID
        "account_id",           # Filter by account ID
        "liquidity_pool_id",    # Filter by liquidity pool ID
        "trade_type",           # Filter by trade type (orderbook/liquidity_pool)
        "base_asset_type",      # Base asset type
        "base_asset_code",      # Base asset code
        "base_asset_issuer",    # Base asset issuer
        "counter_asset_type",   # Counter asset type
        "counter_asset_code",   # Counter asset code
        "counter_asset_issuer", # Counter asset issuer
        *PAGINATION_PARAMS
    ],
    ("/trade_aggregations", "GET"): [
        "start_time",           # Start time in milliseconds
        "end_time",             # End time in milliseconds
        "resolution",           # Aggregation resolution in milliseconds
        "offset",               # Time offset in milliseconds
        "base_asset_type",      # Base asset type
        "base_asset_code",      # Base asset code
        "base_asset_issuer",    # Base asset issuer
        "counter_asset_type",   # Counter asset type
        "counter_asset_code",   # Counter asset code
        "counter_asset_issuer", # Counter asset issuer
        *PAGINATION_PARAMS
    ],

    # ========================================================================
    # Transaction Endpoints
    # ========================================================================
    ("/transactions", "GET"): [
        "include_failed",
        *PAGINATION_PARAMS
    ],
    ("/transactions", "POST"): [
        "tx",  # Base64-encoded XDR TransactionEnvelope
    ],
    ("/transactions/{tx_id}", "GET"): [],
    ("/transactions/{tx_id}/operations", "GET"): [
        "include_failed",
        "join",
        *PAGINATION_PARAMS
    ],
    ("/transactions/{tx_id}/payments", "GET"): [
        "include_failed",
        "join",
        *PAGINATION_PARAMS
    ],
    ("/transactions/{tx_id}/effects", "GET"): PAGINATION_PARAMS,

    # ========================================================================
    # Async Transaction Submission
    # ========================================================================
    ("/transactions_async", "POST"): [
        "tx",  # Base64-encoded XDR TransactionEnvelope
    ],
}
