---
name: hydric-token-baskets-user
description: Comprehensive guide for interacting with the hydric Token Baskets system. Use this skill when you need to discover, fetch, or validate curated lists of tokens (baskets) like Stablecoins, LSTs, or Pegged Assets across various blockchain networks.
---

# hydric Token Baskets User Guide

The **hydric Token Baskets** repository is a source of truth for curated collections of tokens sharing specific characteristics (e.g., "USD Stablecoins", "BTC Pegged Tokens"). These baskets are maintained across multiple networks and are publicly accessible via CDN.

## 1. Quick Start

**Base URL Pattern:**

```
https://cdn.jsdelivr.net/gh/hydric-org/token-baskets/baskets/{chainId}/{basketId}.json
```

**Example: Get all USD Stablecoins on Ethereum (Chain ID 1):**
`https://cdn.jsdelivr.net/gh/hydric-org/token-baskets/baskets/1/usd-stablecoins.json`

## 2. Core Concepts

### 2.1 Supported Basket IDs

These IDs allow you to select the _category_ of tokens you are interested in.

**Source of Truth:**
For the most up-to-date list of available baskets, criteria, and IDs, please refer to the `BasketsRegistry` in the official repository:
[src/baskets-registry.ts](https://github.com/hydric-org/token-baskets/blob/main/src/baskets-registry.ts)

### 2.2 Supported Network (Chain) IDs

Use these IDs to select the _network_ you are querying.

**Source of Truth:**
For the list of supported networks and their Chain IDs, strictly refer to:
[src/domain/enums/chain-id.ts](https://github.com/hydric-org/token-baskets/blob/main/src/domain/enums/chain-id.ts)

## 3. Data Schema

When you fetch a basket JSON file, the response follows the `IBasket` interface:

```typescript
interface IBasket {
  id: string; // The Basket ID (e.g., "usd-stablecoins")
  name: string; // Human-readable name (e.g., "USD Stablecoins")
  logo: string; // URL to the basket's logo image
  description: string; // Description of the basket's criteria
  lastUpdated: string; // ISO 8601 Timestamp of the last update
  index: string[]; // Array of Token Addresses (always lowercase). The zero address represents the native token.
}
```

**Note:** The zero address (`0x0000000000000000000000000000000000000000`) is explicitly used to represent the Native Coin of the network (e.g., ETH on ID 1, MATIC on ID 137).

### Response Example

```json
{
  "id": "usd-stablecoins",
  "name": "USD Stablecoins",
  "logo": "https://cdn.jsdelivr.net/...",
  "description": "A curated list of multiple USD Stablecoins...",
  "lastUpdated": "2024-10-24T10:00:00Z",
  "index": [
    "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
    "0xdac17f958d2ee523a2206206994597c13d831ec7"
  ]
}
```

## 4. Usage Patterns

### Scenario: Finding Safe Asset Tokens

If you are building a DeFi application and need to verify if a user's token is a recognized stablecoin, you can fetch the basket and check for inclusion.

**Implementation Logic (Pseudo-code):**

```javascript
async function isVerifiedStablecoin(chainId, tokenAddress) {
  const basketId = "usd-stablecoins";
  const url = `https://cdn.jsdelivr.net/gh/hydric-org/token-baskets/baskets/${chainId}/${basketId}.json`;

  try {
    const response = await fetch(url);
    if (!response.ok) return false; // Basket might not exist for this chain

    const data = await response.json();
    // Normalize to lowercase for comparison
    const allowedTokens = new Set(data.index.map((t) => t.toLowerCase()));

    return allowedTokens.has(tokenAddress.toLowerCase());
  } catch (error) {
    console.error("Failed to fetch basket", error);
    return false;
  }
}
```

### Scenario: displaying Token Options

When a user selects a chain, you can offer them curated lists of tokens to swap or deposit.

1.  **Select Chain**: User selects Base (8453).
2.  **Fetch Lists**: Fetch `usd-stablecoins` and `eth-pegged-tokens` for ChainID 8453.
3.  **Display**: Show the tokens from the `index` array, using the `name` and `logo` from the basket metadata for the group header.

### Scenario: Discovering Sector-Specific Liquidity Pools

You can use the tokens in a basket to filter for relevant liquidity pools. For example, finding all "Gold" pools on a DEX indexer.

**Implementation Logic (Pseudo-code):**

```javascript
async function getGoldPools(chainId) {
  // 1. Get the authoritative list of Gold tokens for this chain
  const goldBasketUrl = `https://cdn.jsdelivr.net/gh/hydric-org/token-baskets/baskets/${chainId}/xau-stablecoins.json`;
  const basketResponse = await fetch(goldBasketUrl);
  const basketData = await basketResponse.json();
  const goldTokens = basketData.index; // ['0x...', '0x...']

  // 2. Query your Indexer/API for pools containing ANY of these tokens
  // Example using a hypothetical Indexer API
  const pools = await indexerApi.query({
    where: {
      chainId: chainId,
      tokens: { containsAny: goldTokens },
    },
  });

  return pools;
}
```

## 5. Best Practices

1.  **Caching**: The baskets are static files served via CDN. You should cache them in your application to reduce network requests. Use the `lastUpdated` field to determine if re-fetching is necessary later, or simply set a reasonable TTL (e.g., 1 hour).
2.  **Error Handling**: Not all baskets exist on all chains. If a fetch returns a 404, it simply means that specific basket type is not tracked or available on that specific network. Handle this gracefully (e.g., treat it as an empty list).
3.  **Case Sensitivity**: The `index` array strictly contains **lowercase** addresses. Ensure you normalize your input or comparison tokens to lowercase to match successfully.

## 6. How Baskets are Curated

The baskets are generated by an automated agentic system that:

1.  **Scans**: Finds potential tokens based on keywords and market data.
2.  **Validates**: Uses LLMs (`validationPrompt`) to verify project legitimacy, price peg adherence (e.g., strict 0.9-1.1 range for USD), and contract safety.
3.  **Filters**: Excludes scams, unpegged assets, and malicious impersonators.
4.  **Updates**: Commits changes to the repo, which are then reflected on the CDN.
