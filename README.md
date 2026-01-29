# hydric Ecosystem Agent Skills

A collection of skills for AI agents to interact with the hydric ecosystem, including products, APIs, indexers, etc.

## Installation

These skills are designed to be used with [skills.sh](https://skills.sh/).

To install a specific skill to your agent, run:

```bash
npx skills add https://github.com/hydric-org/skills --skill <skill-name>
```

For example:

```bash
npx skills add https://github.com/hydric-org/skills --skill hydric-token-baskets-user
```

## Available Skills

### [Hydric Liquidity Pools Indexer User](./skills/hydric-liquidity-pools-indexer-user)

**Name:** `hydric-liquidity-pools-indexer-user`

Comprehensive guide for interacting with the hydric Liquidity Pools Indexer (Envio/HyperIndex). Use this skill when you need to:

1. Query real-time Liquidity Pool data (TVL, Volume, Fees, Yields, etc.).
2. Fetch token metadata, prices, and liquidity pool metrics.
3. Aggregate liquidity pool protocols data.
4. Retrieve historical time-series data about liquidity pools.
