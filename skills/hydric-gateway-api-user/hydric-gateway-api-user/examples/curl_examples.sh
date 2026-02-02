#!/bin/bash
#
# Hydric Gateway API - cURL Examples
#
# This script demonstrates how to use the Hydric Gateway API
# using cURL commands.
#
# Usage:
#   1. Replace YOUR_API_KEY with your actual API key
#   2. Run: chmod +x curl_examples.sh && ./curl_examples.sh
#

API_KEY="YOUR_API_KEY"
BASE_URL="https://api.hydric.org/v1"

echo "=== Hydric Gateway API cURL Examples ==="
echo ""

# -----------------------------------------------------------------------------
# Example 1: Get ETH price on Ethereum
# -----------------------------------------------------------------------------
echo "1. Getting ETH price on Ethereum..."
curl -s "$BASE_URL/tokens/prices/1/0x0000000000000000000000000000000000000000/usd" \
  -H "Authorization: Bearer $API_KEY" | jq '.data.price'
echo ""

# -----------------------------------------------------------------------------
# Example 2: Get USDC price on Base
# -----------------------------------------------------------------------------
echo "2. Getting USDC price on Base..."
curl -s "$BASE_URL/tokens/prices/8453/0x833589fcd6edb6e08f4c7c32d4f71b54bda02913/usd" \
  -H "Authorization: Bearer $API_KEY" | jq '.data.price'
echo ""

# -----------------------------------------------------------------------------
# Example 3: Search for top ETH pools by TVL
# -----------------------------------------------------------------------------
echo "3. Searching for top ETH pools by TVL..."
curl -s -X POST "$BASE_URL/pools/search" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "tokensA": [{"chainId": 1, "address": "0x0000000000000000000000000000000000000000"}],
    "config": {
      "limit": 3,
      "orderBy": {"field": "tvl", "direction": "desc"}
    },
    "filters": {"minimumTotalValueLockedUsd": 1000000}
  }' | jq '.data.pools[] | {protocol: .protocol.name, tokens: [.tokens[].symbol] | join("-"), tvl: .balance.totalValueLockedUsd, yield_24h: .stats.stats24h.yield}'
echo ""

# -----------------------------------------------------------------------------
# Example 4: Search for ETH-USDC pools by yield
# -----------------------------------------------------------------------------
echo "4. Searching for best yield ETH-USDC pools on Base..."
curl -s -X POST "$BASE_URL/pools/search" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "tokensA": [{"chainId": 8453, "address": "0x4200000000000000000000000000000000000006"}],
    "tokensB": [{"chainId": 8453, "address": "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"}],
    "config": {
      "limit": 3,
      "orderBy": {"field": "yield", "direction": "desc", "timeframe": "24h"}
    },
    "filters": {"minimumTotalValueLockedUsd": 50000}
  }' | jq '.data.pools[] | {protocol: .protocol.name, type: .type, tvl: .balance.totalValueLockedUsd, yield_24h: .stats.stats24h.yield, fee: .feeTier.feeTierPercentage}'
echo ""

# -----------------------------------------------------------------------------
# Example 5: Get a specific pool by address
# -----------------------------------------------------------------------------
echo "5. Getting specific pool data..."
curl -s "$BASE_URL/pools/1/0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8" \
  -H "Authorization: Bearer $API_KEY" | jq '.data.pool | {address, protocol: .protocol.name, tvl: .balance.totalValueLockedUsd}'
echo ""

# -----------------------------------------------------------------------------
# Example 6: Search for tokens by name
# -----------------------------------------------------------------------------
echo "6. Searching for tokens named 'USD'..."
curl -s -X POST "$BASE_URL/tokens/search" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "search": "USD",
    "config": {"limit": 5}
  }' | jq '.data.tokens[] | {symbol, name, chains: .chainIds}'
echo ""

# -----------------------------------------------------------------------------
# Example 7: Get all stablecoins basket
# -----------------------------------------------------------------------------
echo "7. Getting USD stablecoins basket..."
curl -s "$BASE_URL/tokens/baskets/usd-stablecoins" \
  -H "Authorization: Bearer $API_KEY" | jq '.data.basket | {id, name, tokens: [.tokens[].symbol]}'
echo ""

# -----------------------------------------------------------------------------
# Example 8: List all protocols
# -----------------------------------------------------------------------------
echo "8. Listing all supported protocols..."
curl -s "$BASE_URL/protocols" \
  -H "Authorization: Bearer $API_KEY" | jq '.data.protocols[] | {id, name}'
echo ""

# -----------------------------------------------------------------------------
# Example 9: Get token info on specific chain
# -----------------------------------------------------------------------------
echo "9. Getting USDC info on Ethereum..."
curl -s "$BASE_URL/tokens/1/0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48" \
  -H "Authorization: Bearer $API_KEY" | jq '.data.token'
echo ""

# -----------------------------------------------------------------------------
# Example 10: Find token across all chains
# -----------------------------------------------------------------------------
echo "10. Finding USDC across all chains..."
curl -s "$BASE_URL/tokens/0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48" \
  -H "Authorization: Bearer $API_KEY" | jq '.data.tokens[] | {chainId, symbol, address}'
echo ""

echo "=== Examples Complete ==="
