# Quick Reference Examples

## Initialization

```typescript
import { HydricGateway } from "@hydric/gateway";
const hydric = new HydricGateway({ apiKey: process.env.HYDRIC_API_KEY });
```

## Multi-Chain Tokens

```typescript
// List top tokens globally
const { tokens } = await hydric.multichainTokens.list({
  config: { limit: 20, orderBy: { field: "tvl", direction: "desc" } },
});

// Search globally
const { tokens } = await hydric.multichainTokens.search({ search: "USDC" });
```

## Single-Chain Tokens

```typescript
// List tokens on Base (8453)
const { tokens } = await hydric.singleChainTokens.list(8453, {
  config: { orderBy: { field: "tvl", direction: "desc" } },
});

// Search on Ethereum (1)
const { tokens } = await hydric.singleChainTokens.search(1, { search: "WETH" });

// Get price
const { priceUsd } = await hydric.singleChainTokens.getPriceUsd({
  chainId: 8453,
  tokenAddress: "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913",
});
```

## Token Baskets

```typescript
// List all baskets
const { baskets } = await hydric.tokenBaskets.list();

// Get multi-chain basket
const { basket } = await hydric.tokenBaskets.getMultiChainById({
  basketId: "usd-stablecoins",
});

// Get single-chain basket
const { basket } = await hydric.tokenBaskets.getSingleChainById({
  chainId: 8453,
  basketId: "usd-stablecoins",
});
```

## Error Handling

```typescript
import {
  HydricRateLimitError,
  HydricNotFoundError,
  HydricUnauthorizedError,
} from "@hydric/gateway";

try {
  const data = await hydric.tokenBaskets.getSingleChainById({
    chainId: 1,
    basketId: "usd-stablecoins",
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
