/**
 * Hydric Gateway API - Pool Search Example (TypeScript)
 *
 * This example demonstrates how to search for liquidity pools
 * using the Hydric Gateway API.
 *
 * Usage:
 *   1. Replace YOUR_API_KEY with your actual API key
 *   2. Run: npx ts-node search-pools.ts
 */

const API_KEY = 'YOUR_API_KEY';
const BASE_URL = 'https://api.hydric.org/v1';

// Chain IDs for reference
const ChainId = {
  ETHEREUM: 1,
  BASE: 8453,
  SCROLL: 534352,
  MONAD: 143,
  UNICHAIN: 130,
  HYPER_EVM: 999,
  PLASMA: 9745,
} as const;

// Well-known token addresses
const TOKENS = {
  ETH: '0x0000000000000000000000000000000000000000',
  WETH_BASE: '0x4200000000000000000000000000000000000006',
  USDC_ETH: '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48',
  USDC_BASE: '0x833589fcd6edb6e08f4c7c32d4f71b54bda02913',
};

interface BlockchainAddress {
  chainId: number;
  address: string;
}

interface SearchPoolsRequest {
  tokensA: BlockchainAddress[];
  tokensB?: BlockchainAddress[];
  filters?: {
    minimumTotalValueLockedUsd?: number;
    blockedPoolTypes?: string[];
    blockedProtocols?: string[];
  };
  config?: {
    limit?: number;
    orderBy?: {
      field: 'tvl' | 'yield';
      direction: 'asc' | 'desc';
      timeframe?: '24h' | '7d' | '30d' | '90d';
    };
    cursor?: string;
  };
}

async function searchPools(request: SearchPoolsRequest) {
  const response = await fetch(`${BASE_URL}/pools/search`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(request),
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(`API Error: ${error.error?.message || response.statusText}`);
  }

  const json = await response.json();
  return json.data;
}

// Example 1: Find all pools containing ETH on Ethereum
async function findEthPools() {
  console.log('=== Finding all ETH pools on Ethereum ===\n');

  const result = await searchPools({
    tokensA: [{ chainId: ChainId.ETHEREUM, address: TOKENS.ETH }],
    config: {
      limit: 5,
      orderBy: { field: 'tvl', direction: 'desc' },
    },
    filters: {
      minimumTotalValueLockedUsd: 1000000,
    },
  });

  console.log(`Found ${result.pools.length} pools:\n`);
  for (const pool of result.pools) {
    const tokens = pool.tokens.map((t: any) => t.symbol).join('-');
    console.log(`  ${pool.protocol.name} | ${tokens}`);
    console.log(`    TVL: $${pool.balance.totalValueLockedUsd.toLocaleString()}`);
    console.log(`    24h Yield: ${pool.stats.stats24h.yield.toFixed(2)}%`);
    console.log(`    Address: ${pool.address}\n`);
  }
}

// Example 2: Find ETH-USDC pair pools on Base sorted by yield
async function findBestYieldEthUsdcOnBase() {
  console.log('=== Best ETH-USDC pools on Base by 24h yield ===\n');

  const result = await searchPools({
    tokensA: [{ chainId: ChainId.BASE, address: TOKENS.WETH_BASE }],
    tokensB: [{ chainId: ChainId.BASE, address: TOKENS.USDC_BASE }],
    config: {
      limit: 5,
      orderBy: { field: 'yield', direction: 'desc', timeframe: '24h' },
    },
    filters: {
      minimumTotalValueLockedUsd: 50000,
    },
  });

  console.log(`Found ${result.pools.length} ETH-USDC pools:\n`);
  for (const pool of result.pools) {
    console.log(`  ${pool.protocol.name} (${pool.type})`);
    console.log(`    TVL: $${pool.balance.totalValueLockedUsd.toLocaleString()}`);
    console.log(`    24h Yield: ${pool.stats.stats24h.yield.toFixed(2)}%`);
    console.log(`    7d Yield: ${pool.stats.stats7d.yield.toFixed(2)}%`);
    console.log(`    Fee: ${pool.feeTier.feeTierPercentage}%\n`);
  }
}

// Example 3: Paginate through all results
async function paginateThroughPools() {
  console.log('=== Paginating through all ETH pools ===\n');

  let cursor: string | null = null;
  let page = 1;
  let totalPools = 0;

  do {
    const result = await searchPools({
      tokensA: [{ chainId: ChainId.ETHEREUM, address: TOKENS.ETH }],
      config: {
        limit: 10,
        cursor: cursor || undefined,
      },
    });

    totalPools += result.pools.length;
    console.log(`Page ${page}: ${result.pools.length} pools`);
    cursor = result.nextCursor;
    page++;

    // Stop after 3 pages for this demo
    if (page > 3) break;
  } while (cursor);

  console.log(`\nTotal pools fetched: ${totalPools}`);
}

// Run all examples
async function main() {
  try {
    await findEthPools();
    console.log('\n' + '='.repeat(50) + '\n');
    await findBestYieldEthUsdcOnBase();
    console.log('\n' + '='.repeat(50) + '\n');
    await paginateThroughPools();
  } catch (error) {
    console.error('Error:', error);
  }
}

main();
