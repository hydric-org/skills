---
name: hydric-gateway-sdk-user
description: Expert skill for integrating the hydric Gateway SDK (@hydric/gateway). Use this skill to orchestrate multi-chain liquidity, resolve token identities, and build high-fidelity DeFi dashboards with institution-grade precision.
---

# hydric Gateway SDK | Expert Integration Skill

You are an **SDK Integration Specialist** with deep expertise in the `@hydric/gateway` TypeScript SDK. Your mission is to help any AI or developer use this SDK with the same fluency as if they had built it themselves.

---

## � Core Resources

| Resource Type                | Location                                                            |
| :--------------------------- | :------------------------------------------------------------------ |
| **Official TypeScript Docs** | https://docs.hydric.org/sdk-reference/typescript                    |
| **MCP Docs Server**          | https://docs.hydric.org/mcp                                         |
| **Source Code**              | https://github.com/hydric-org/gateway-sdk/tree/main/sdks/typescript |
| **NPM Package**              | `@hydric/gateway`                                                   |

---

## 🎯 SDK Architecture

The SDK is structured around **three core resources**, each accessed via the `HydricGateway` client:

```typescript
import { HydricGateway } from '@hydric/gateway';

const hydric = new HydricGateway({
  apiKey: process.env.HYDRIC_API_KEY,
});

// Access resources via:
hydric.multichainTokens; // Global multi-chain token operations
hydric.singleChainTokens; // Performance-optimized single-chain operations
hydric.tokenBaskets; // Curated asset group discovery
```

---

## 🔑 Initialization & Authentication

### Basic Setup

```typescript
import { HydricGateway } from '@hydric/gateway';

const hydric = new HydricGateway({
  apiKey: 'sk_...', // Required: Get from https://dashboard.hydric.org or use any that the user provides
});
```

### The API Key Rule

- **Storage**: Always use environment variables (`process.env.HYDRIC_API_KEY`)
- **Validation**: The SDK throws `HydricInvalidParamsError` immediately if the key is missing
- **Server Validation**: The Gateway API will throw `HydricUnauthorizedError` if the key is invalid

---

## Resource 1: `multichainTokens`

**Purpose**: Aggregate data for tokens that exist across multiple blockchains.

### Methods

#### `list(params?)`

Returns tokens with multi-chain metadata.

```typescript
const { tokens, nextCursor } = await hydric.multichainTokens.list({
  config: {
    limit: 20,
    orderBy: { field: 'tvl', direction: 'desc' },
  },
  filters: {
    chainIds: [1, 8453], // Optional: Ethereum + Base only
  },
});

// Access chain-specific addresses
tokens.forEach((token) => {
  console.log(`${token.symbol} is on chains: ${token.chainIds.join(', ')}`);
  console.log(`Addresses:`, token.addresses); // Array of { chainId, address }
});
```

**Key Type**: `MultiChainTokenMetadata`

- `symbol`, `name`: Token identifiers
- `chainIds`: Array of chain IDs where this token has liquidity
- `addresses`: Array of `{ chainId, address }` pairs
- `logoUrl`: Verified icon URL

#### `search(params)`

Find tokens globally by name or ticker.

```typescript
const { tokens } = await hydric.multichainTokens.search({
  search: 'USDC',
  config: { limit: 5 },
  filters: { chainIds: [1, 8453] },
});
```

### When to Use

- Building a global token selector
- Portfolio trackers that need all chain instances
- Cross-chain yield comparison

---

## ⚡ Resource 2: `singleChainTokens`

**Purpose**: High-performance operations for a specific blockchain.

### Methods

#### `list(chainId, params?)`

Returns tokens on a single chain.

```typescript
const { tokens, nextCursor } = await hydric.singleChainTokens.list(8453, {
  config: {
    limit: 10,
    orderBy: { field: 'tvl', direction: 'desc' },
  },
  filters: {
    minimumTotalValuePooledUsd: 100000, // Deep liquidity only
  },
});
```

**Important**: First parameter is the `chainId` (numeric), followed by optional params.

#### `search(chainId, params)`

Search tokens on a specific chain.

```typescript
const { tokens } = await hydric.singleChainTokens.search(1, {
  search: 'WETH',
});
```

**Key Type**: `SingleChainTokenMetadata`

- `address`, `chainId`: Exact on-chain location
- `symbol`, `name`, `decimals`: Token metadata

### When to Use

- Transaction simulation (need exact address for swaps)
- Latency-sensitive apps (dashboard widgets)
- User has already selected their target chain

---

## 🗂️ Resource 3: `tokenBaskets`

**Purpose**: Discover curated groups of related tokens (Stablecoins, LSTs, BTCs).

### Methods

#### `list(params?)`

Get all available baskets.

```typescript
// All baskets across all chains
const { baskets } = await hydric.tokenBaskets.list();

// Filter to specific chains
const { baskets } = await hydric.tokenBaskets.list({
  chainIds: [1, 8453],
});
```

#### `getMultiChainById({ basketId, chainIds? })`

Get a basket with multi-chain view.

```typescript
const { basket } = await hydric.tokenBaskets.getMultiChainById({
  basketId: 'usd-stablecoins',
  chainIds: [1, 8453], // Optional filter
});

console.log(`${basket.name} is available on ${basket.chains.length} chains`);
basket.tokens.forEach((token) => {
  console.log(`${token.symbol}: ${token.addresses.length} deployments`);
});
```

#### `getSingleChainById({ chainId, basketId })`

Get a basket for a specific chain.

```typescript
const { basket } = await hydric.tokenBaskets.getSingleChainById({
  chainId: 8453,
  basketId: 'usd-stablecoins',
});

// Direct access to single-chain token data
basket.tokens.forEach((token) => {
  console.log(`${token.symbol}: ${token.address}`);
});
```

### Available Basket IDs

For the complete list of available basket IDs, see: https://docs.hydric.org/sdk-reference/typescript/token-baskets#available-baskets

---

## ⚠️ Error Handling

The SDK uses **named error classes** for precise handling:

```typescript
import { HydricError, HydricInvalidParamsError, HydricUnauthorizedError, HydricNotFoundError, HydricRateLimitError } from '@hydric/gateway';

try {
  const data = await hydric.tokenBaskets.getSingleChainById({
    chainId: 1,
    basketId: 'invalid-basket',
  });
} catch (error) {
  if (error instanceof HydricRateLimitError) {
    // Implement exponential backoff
    console.error('Rate limited. Retry after delay.');
  } else if (error instanceof HydricNotFoundError) {
    // Resource doesn't exist on this chain
    console.error('Basket not found on this chain.');
  } else if (error instanceof HydricUnauthorizedError) {
    // API key issue
    console.error('Check your API key.');
  } else if (error instanceof HydricInvalidParamsError) {
    // Client-side validation failed
    console.error('Invalid parameters:', error.message);
  } else {
    // Generic error
    console.error('Unexpected error:', error);
  }
}
```

### Error Properties

All errors extend `HydricError` with:

- `name`: Error class name
- `message`: Human-readable explanation

---

## 🧭 Common Integration Patterns

### Pattern 1: Global Token Discovery

```typescript
// User searches for "USDC" without specifying chain
const { tokens } = await hydric.multichainTokens.search({
  search: 'USDC',
  config: { limit: 10 },
});

// Show all chain deployments
tokens.forEach((token) => {
  token.addresses.forEach(({ chainId, address }) => {
    console.log(`${token.symbol} on chain ${chainId}: ${address}`);
  });
});
```

### Pattern 2: Single-Chain Deep Dive

```typescript
// User selected Base (8453) in UI
const chainId = 8453;

// Get top tokens by TVL
const { tokens } = await hydric.singleChainTokens.list(chainId, {
  config: {
    limit: 50,
    orderBy: { field: 'tvl', direction: 'desc' },
  },
});

// Enrich with live prices
const enriched = await Promise.all(
  tokens.map(async (token) => {
    const price = await hydric.singleChainTokens.getPriceUsd({
      chainId,
      tokenAddress: token.address,
    });
    return { ...token, priceUsd: price.priceUsd };
  }),
);
```

### Pattern 3: Basket-Based Portfolio Builder

```typescript
// Get all stablecoins
const { basket } = await hydric.tokenBaskets.getMultiChainById({
  basketId: 'usd-stablecoins',
});

// For each token, get price from primary chain
const portfolio = await Promise.all(
  basket.tokens.map(async (token) => {
    const primaryChain = token.addresses[0];
    try {
      const { priceUsd } = await hydric.singleChainTokens.getPriceUsd({
        chainId: primaryChain.chainId,
        tokenAddress: primaryChain.address,
      });
      return { ...token, priceUsd };
    } catch {
      return { ...token, priceUsd: null };
    }
  }),
);
```

### Pattern 4: Pagination

```typescript
let cursor: string | null = null;
const allTokens = [];

do {
  const { tokens, nextCursor } = await hydric.multichainTokens.list({
    config: {
      limit: 100,
      cursor, // Pass previous cursor
      orderBy: { field: 'tvl', direction: 'desc' },
    },
  });

  allTokens.push(...tokens);
  cursor = nextCursor;
} while (cursor);

console.log(`Fetched ${allTokens.length} total tokens`);
```

---

## 🚨 Critical Rules

### 1. Resource Selection

- **ALWAYS** prefer `singleChainTokens` if the user has specified a single chain
- `multichainTokens` is for global aggregation only
- Never mix resource types for the same query

### 2. Type Safety

- Import types from `'@hydric/gateway'`
- Never guess type names - they are exported from the SDK
- Use `SupportedChainId` for chain ID parameters

### 3. Chain IDs

For the complete list of supported networks and their numeric chain IDs, see: https://docs.hydric.org/overview/supported-blockchains

Always use numeric chain IDs (e.g., `1` for Ethereum, `8453` for Base).

### 4. Addresses

- **Always lowercase** in responses
- Use `0x0000000000000000000000000000000000000000` for native assets

---

## �️ Implementation Checklist

When implementing a feature with this SDK:

- [ ] Initialize `HydricGateway` with API key from environment
- [ ] Choose correct resource (e.g `multichain` vs `singleChain`)
- [ ] Import and use SDK types (no manual type definitions)
- [ ] Wrap calls in `try/catch` with specific error handling
- [ ] Handle pagination if fetching large datasets
- [ ] Use semantic variable names (no `addr`, `tkn`, etc.)

---

## 🔍 Quick Method Reference

| Task                      | Method                                      | Resource            |
| :------------------------ | :------------------------------------------ | :------------------ |
| List tokens globally      | `list()`                                    | `multichainTokens`  |
| List tokens on one chain  | `list(chainId, params)`                     | `singleChainTokens` |
| Search global             | `search({ search })`                        | `multichainTokens`  |
| Search on chain           | `search(chainId, { search })`               | `singleChainTokens` |
| Get token USD price       | `getPriceUsd({ chainId, tokenAddress })`    | `singleChainTokens` |
| List baskets              | `list()`                                    | `tokenBaskets`      |
| Get basket (multichain)   | `getMultiChainById({ basketId })`           | `tokenBaskets`      |
| Get basket (single chain) | `getSingleChainById({ chainId, basketId })` | `tokenBaskets`      |

---

## 📖 Additional Resources

For detailed documentation on every method parameter and response field:

- Call the MCP server: https://docs.hydric.org/mcp
- Read the full docs: https://docs.hydric.org/sdk-reference/typescript
- Read the source code: https://github.com/hydric-org/gateway-sdk/tree/main/sdks/typescript

Use this skill to provide SDK integrations that are:

- **Type-safe**: Always use exported types
- **Performant**: Choose the right resource for the job
- **Robust**: Handle all error cases explicitly
- **Readable**: Use semantic naming and clear orchestration logic
