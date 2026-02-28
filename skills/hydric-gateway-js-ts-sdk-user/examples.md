# Quick Reference Examples

## Initialization

```typescript
import { HydricGateway } from '@hydric/gateway';
const hydric = new HydricGateway({ apiKey: process.env.HYDRIC_API_KEY });
```

## Multi-Chain Tokens

```typescript
// List top tokens globally
const { tokens } = await hydric.multichainTokens.list({
  config: { limit: 20, orderBy: { field: 'tvl', direction: 'desc' } },
});

// Search globally
const { tokens } = await hydric.multichainTokens.search({ search: 'USDC' });
```

## Single-Chain Tokens

```typescript
// List tokens on Base (8453)
const { tokens } = await hydric.singleChainTokens.list(8453, {
  config: { orderBy: { field: 'tvl', direction: 'desc' } },
});

// Search on Ethereum (1)
const { tokens } = await hydric.singleChainTokens.search(1, { search: 'WETH' });

// Get price
const { priceUsd } = await hydric.singleChainTokens.getPriceUsd({
  chainId: 8453,
  tokenAddress: '0x833589fcd6edb6e08f4c7c32d4f71b54bda02913',
});
```

## Token Baskets

```typescript
// List all baskets
const { baskets } = await hydric.tokenBaskets.list();

// Get multi-chain basket
const { basket } = await hydric.tokenBaskets.getMultiChainById({
  basketId: 'usd-stablecoins',
});

// Get single-chain basket
const { basket } = await hydric.tokenBaskets.getSingleChainById({
  chainId: 8453,
  basketId: 'usd-stablecoins',
});
```

## Liquidity Pools

```typescript
// 1. Basic Pair Search (Tokens A + Tokens B)
// Find any USDC-ETH pools on Ethereum
const { pools } = await hydric.liquidityPools.search({
  tokensA: [{ chainId: 1, address: '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48' }], // USDC
  tokensB: [{ chainId: 1, address: '0x0000000000000000000000000000000000000000' }], // ETH
  filters: { minimumTotalValueLockedUsd: 10000 },
});

// 2. Cross-Sector Search (Baskets A + Tokens B)
// Find pools matching ANY Stablecoin vs Wrapped ETH on Base
const { pools } = await hydric.liquidityPools.search({
  basketsA: [{ basketId: 'usd-stablecoins', chainIds: [8453] }],
  tokensB: [{ chainId: 8453, address: '0x4200000000000000000000000000000000000006' }], // WETH
});

// 3. Direct Pair Matching (Basket A + Basket B)
// Find liquidity between any Stablecoin and any BTC-pegged token
const { pools } = await hydric.liquidityPools.search({
  basketsA: [{ basketId: 'usd-stablecoins' }],
  basketsB: [{ basketId: 'btc-pegged-tokens' }],
  config: { limit: 10 },
});
```

## Error Handling

```typescript
import { HydricRateLimitError, HydricNotFoundError, HydricUnauthorizedError } from '@hydric/gateway';

try {
  const data = await hydric.tokenBaskets.getSingleChainById({
    chainId: 1,
    basketId: 'usd-stablecoins',
  });
} catch (error) {
  if (error instanceof HydricRateLimitError) {
    // Implement backoff
  } else if (error instanceof HydricNotFoundError) {
    // Handle not found
  } else if (error instanceof HydricUnauthorizedError) {
    // Check API key
  }
}
```

## Pagination

```typescript
let cursor = null;
do {
  const { tokens, nextCursor } = await hydric.multichainTokens.list({
    config: { limit: 100, cursor },
  });
  // Process tokens...
  cursor = nextCursor;
} while (cursor);
```
