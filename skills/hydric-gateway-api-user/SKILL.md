---
name: hydric-gateway-api-user
description: Expert skill for integrating the hydric Gateway API. Use this skill to search cross-chain liquidity, resolve multi-chain and single chain token identities, get token prices, and build high-fidelity DeFi dashboards.
---

# hydric Gateway API | Integration Instructions

You are a Senior Integration Engineer specializing in the **hydric Gateway API**. Your goal is to help developers implement high-fidelity DeFi data layers with institutional-grade security and accuracy.

---

## What is Hydric?

Hydric is a **normalized data layer** for DeFi liquidity. It acts as a "Universal Translator" that bridges the gap between fragmented, protocol-specific blockchain states (Uniswap, Algebra, etc.) and institutional-grade financial data.

The **Gateway API** is the consumption layer of the hydric Engine. Its purpose is to **Serve** normalized, high-fidelity data that has been indexed directly from smart contracts and translated into a unified schema. It enables developers to build DeFi dashboards, risk systems, and portfolio trackers without protocol-specific expertise or the overhead of maintaining custom indexers.

## First-Time Integration Workflow

1. **Read this skill** for patterns, gotchas, and operational logic.
2. **Fetch OpenAPI spec** from `https://api.hydric.org/v1/openapi.json` for exact request/response schemas.
3. **Use the examples** in `./examples/` for TypeScript, Python, and cURL implementations.

---

## Core Resources

| Resource        | URL                                      |
| --------------- | ---------------------------------------- |
| API Base URL    | `https://api.hydric.org/v1`              |
| OpenAPI Spec    | `https://api.hydric.org/v1/openapi.json` |
| API Reference   | `https://docs.hydric.org/api-reference`  |
| Docs MCP Server | `https://docs.hydric.org/mcp`            |

**Authentication:** Bearer Token in `Authorization` header.

---

## Operational Logic

- **Addresses:** Always **lowercase**. Input is case-insensitive, output is always lowercase.
- **Tickers:** **Case-sensitive** (e.g., `mUSD` ≠ `MUSD`).
- **Native Assets:** Zero address `0x0000000000000000000000000000000000000000`.
- **Chain IDs:** Ethereum (1), Base (8453), Scroll (534352), Monad (143), Unichain (130), Hyper EVM (999), Plasma (9745).

---

## Response Envelope

**Success:**

```json
{ "statusCode": 200, "timestamp": "...", "path": "/v1/...", "traceId": "...", "data": { ... } }
```

**Error:**

```json
{ "statusCode": 400, "timestamp": "...", "path": "/v1/...", "traceId": "...", "error": { "code": "VALIDATION_ERROR", "title": "...", "message": "...", "details": "...", "metadata": { ... } } }
```

---

## Pagination

All list endpoints support cursor-based pagination:

1. **First request:** Omit `config.cursor`.
2. **Response** includes `nextCursor` (or `null` if no more pages).
3. **Next page:** Pass `nextCursor` value as `config.cursor`.
4. **Important:** Do NOT change `orderBy` while paginating.

---

## Common Execution Patterns

### Pattern A: Multi-Chain Yield Discovery

Find best yield for a token across ALL chains:

1. `POST /v1/tokens/search` with `{ "search": "USDC" }` → get all chain addresses.
2. `POST /v1/pools/search` with those addresses in `tokensA`.
3. Set `config: { orderBy: { field: 'yield', direction: 'desc', timeframe: '24h' } }`.
4. Filter `filters: { minimumTotalValueLockedUsd: 50000 }` to avoid low-liquidity traps.

### Pattern B: Single-Chain Yield Discovery

Find best yield on a SPECIFIC chain:

1. `POST /v1/tokens/{chainId}/search` with `{ "search": "USDC" }`.
2. `POST /v1/pools/search` with single address + chainId.
3. Set `config: { orderBy: { field: 'yield', direction: 'desc', timeframe: '24h' } }`.

### Pattern C: Multi-Chain Token List

Get most liquid tokens across chains:

1. `POST /v1/tokens` with `config: { orderBy: { field: 'tvl', direction: 'desc' } }`.
2. Optionally filter by `filters: { chainIds: [1, 8453] }`.

### Pattern D: Token Baskets (Stablecoins, LSTs, etc.)

Get curated token groups:

1. `GET /v1/tokens/baskets` → list all basket IDs.
2. `GET /v1/tokens/baskets/{basketId}` → e.g., `usd-stablecoins`.
3. Use `addresses` field for all token addresses in that basket.

**Available Baskets:** `usd-stablecoins`, `eth-pegged-tokens`, `btc-pegged-tokens`, `eur-stablecoins`, `xau-stablecoins`, `monad-pegged-tokens`, `hype-pegged-tokens`.

### Pattern E: Token USD Price Lookup

Get current USD price:

```
GET /v1/tokens/prices/{chainId}/{tokenAddress}/usd
```

- Use zero address for native token price.
- Falls back to wrapped native if needed.

### Pattern F: Get Specific Pool

```
GET /v1/pools/{chainId}/{poolAddress}
```

- `poolAddress` can be 42-char address OR V4 bytes32 poolId.

---

## Pool Filters

The `/v1/pools/search` endpoint supports two filtering strategies:

### Include Filters (Allowlist)

Use `protocols` and `poolTypes` to restrict results to specific values:

```json
{
  "filters": {
    "protocols": ["uniswap-v3", "uniswap-v4"],
    "poolTypes": ["V3", "V4"]
  }
}
```

> [!CAUTION] > **If your integration uses the `metadata` field, you MUST use allowlists.**
>
> While hydric normalizes top-level pool data, the `metadata` field contains protocol/architecture-specific structures (hooks, plugins, pool math addresses). If your logic depends on `metadata`, for example, to enable pool deposits or swaps, you must explicitly set `protocols` and `poolTypes`.
>
> **Why?** When hydric adds a new protocol or pool type, it may introduce novel `metadata` structures. Without allowlists, your application will receive these new structures and your integration will break because your code isn't designed to parse them.

### Blocked Filters (Blocklist)

Use `blockedProtocols` and `blockedPoolTypes` to exclude specific values:

```json
{
  "filters": {
    "blockedProtocols": ["sushiswap-v3"],
    "blockedPoolTypes": ["ALGEBRA"]
  }
}
```

**When to use:** Read-only dashboards that only display normalized fields (TVL, volume, yields) and don't interact with `metadata`, just want to filter out specific protocols or pool types.

### Precedence

- If `protocols` is provided, `blockedProtocols` is ignored.
- If `poolTypes` is provided, `blockedPoolTypes` is ignored.
- Empty arrays default to the blocklist approach.

### Available Pool Types

`V3`, `V4`, `ALGEBRA`, `SLIPSTREAM`

### Discovering Protocol IDs

Use `GET /v1/protocols` to get all supported protocol IDs (e.g., `uniswap-v3`, `algebra-integral`).

---

## Pool Type Metadata

The `metadata` field in the pool object varies by pool `type`:

| Type         | Key Metadata Fields                                                         |
| ------------ | --------------------------------------------------------------------------- |
| `V3`         | `latestSqrtPriceX96`, `latestTick`, `tickSpacing`, `positionManagerAddress` |
| `V4`         | V3 + `poolManagerAddress`, `stateViewAddress`, `permit2Address`, `hook`     |
| `ALGEBRA`    | V3 + `plugin`, `version`, `communityFeePercentage`, `deployer`              |
| `SLIPSTREAM` | Same as V3                                                                  |

**V4 Hooks:** `metadata.hook` is `{ address: "0x..." }` or `null`.
**Algebra Plugins:** `metadata.plugin` is `{ address: "0x...", config: 195 }` or `null`.

---

## Error Codes

### Authentication (401/403)

| Code                | HTTP | Meaning                          |
| ------------------- | ---- | -------------------------------- |
| `API_KEY_MISSING`   | 401  | No Authorization header provided |
| `API_KEY_INVALID`   | 401  | Token format is invalid          |
| `API_KEY_NOT_FOUND` | 401  | API key doesn't exist            |
| `API_KEY_EXPIRED`   | 403  | Key has expired                  |
| `API_KEY_DISABLED`  | 403  | Key is disabled                  |

### Validation (400)

| Code                         | Meaning                        |
| ---------------------------- | ------------------------------ |
| `VALIDATION_ERROR`           | Request body validation failed |
| `UNSUPPORTED_CHAIN_ID`       | Chain ID not supported         |
| `INVALID_POOL_ADDRESS`       | Pool address format invalid    |
| `INVALID_BLOCKCHAIN_ADDRESS` | Address/chainId pair malformed |
| `INVALID_PAGINATION_CURSOR`  | Cursor expired or malformed    |
| `INVALID_PROTOCOL_ID`        | Protocol ID not recognized     |
| `INVALID_BASKET_ID`          | Basket ID not recognized       |

### Not Found (404)

| Code                       | Meaning                            |
| -------------------------- | ---------------------------------- |
| `LIQUIDITY_POOL_NOT_FOUND` | Pool doesn't exist on that chain   |
| `TOKEN_NOT_FOUND`          | Token not indexed on that chain    |
| `TOKEN_BASKET_NOT_FOUND`   | Basket has no assets on that chain |
| `ROUTE_NOT_FOUND`          | Endpoint doesn't exist             |

---

## Code Examples

See `./examples/` directory for complete implementations:

- `search-pools.ts` — TypeScript pool search with pagination
- `search_pools.py` — Python yield discovery + portfolio valuation
- `curl_examples.sh` — 10 cURL examples covering all endpoints

---

## Protocols

Get all supported protocols with `GET /v1/protocols`. Use `protocol.id` in pool filters.

---

## 🩺 Error Resolution Protocol (Diagnostic First)

When an API request fails, do not attempt a "blind fix." You must perform a structured diagnosis using the hydric Error Envelope:

1. **Envelope Analysis:** Inspect the `error` object. Prioritize the `code`, `metadata` and `details` fields over the human-readable `message`.
2. **Metadata Inspection:** The `metadata` field contains the definitive cause (e.g., the specific invalid address or unsupported chainId). Extract this before proposing a fix.
3. **Validation Strategy:** If the error is a `VALIDATION_ERROR`, cross-reference the failing field with the `openapi.json` to verify the required data type, casing, or format (e.g., lowercase addresses).
4. **Uncertainty Guardrail:** If the cause is not 100% clear from the `metadata`, you are forbidden from guessing. You must search the `SKILL.md` or `openapi.json` specifically for that error code's context.

## 📐 Schema Fidelity & Strict Typing

Hallucination is a failure of grounding. To ensure 100% integration accuracy:

- **Zero-Assumption Policy:** Do not assume variable names, nesting levels, or decimal types. You must explicitly read the schema in `openapi.json` for every new endpoint implementation.
- **Interface Grounding:** Before writing TypeScript interfaces or DTOs, locate the `components/schemas` section in the OpenAPI spec. Mirror the spec exactly, especially regarding optional (`?`) vs. required fields.
- **Polymorphism Awareness:** Pay strict attention to the `metadata` object in pools. It changes structure based on the `type` (V3, V4, ALGEBRA). Always check the `type` discriminator before accessing nested metadata properties.
