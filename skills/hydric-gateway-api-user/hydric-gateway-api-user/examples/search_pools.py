"""
Hydric Gateway API - Pool Search Example (Python)

This example demonstrates how to search for liquidity pools
using the Hydric Gateway API.

Usage:
    1. Replace YOUR_API_KEY with your actual API key
    2. Install requests: pip install requests
    3. Run: python search_pools.py
"""

import requests
from typing import Optional

API_KEY = "YOUR_API_KEY"
BASE_URL = "https://api.hydric.org/v1"


class ChainId:
    ETHEREUM = 1
    BASE = 8453
    SCROLL = 534352
    MONAD = 143
    UNICHAIN = 130
    HYPER_EVM = 999
    PLASMA = 9745


class Tokens:
    ETH = "0x0000000000000000000000000000000000000000"
    WETH_BASE = "0x4200000000000000000000000000000000000006"
    USDC_ETH = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
    USDC_BASE = "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"


def search_pools(
    tokens_a: list[dict],
    tokens_b: Optional[list[dict]] = None,
    min_tvl: float = 0,
    limit: int = 10,
    order_by: str = "tvl",
    direction: str = "desc",
    timeframe: str = "24h",
    cursor: Optional[str] = None,
) -> dict:
    """Search for liquidity pools."""
    
    payload = {
        "tokensA": tokens_a,
        "config": {
            "limit": limit,
            "orderBy": {
                "field": order_by,
                "direction": direction,
                "timeframe": timeframe,
            },
        },
        "filters": {
            "minimumTotalValueLockedUsd": min_tvl,
        },
    }
    
    if tokens_b:
        payload["tokensB"] = tokens_b
    
    if cursor:
        payload["config"]["cursor"] = cursor
    
    response = requests.post(
        f"{BASE_URL}/pools/search",
        headers={
            "Authorization": f"Bearer {API_KEY}",
            "Content-Type": "application/json",
        },
        json=payload,
    )
    
    if not response.ok:
        error = response.json()
        raise Exception(f"API Error: {error.get('error', {}).get('message', response.text)}")
    
    return response.json()["data"]


def find_eth_pools():
    """Find all pools containing ETH on Ethereum."""
    print("=== Finding all ETH pools on Ethereum ===\n")
    
    result = search_pools(
        tokens_a=[{"chainId": ChainId.ETHEREUM, "address": Tokens.ETH}],
        min_tvl=1_000_000,
        limit=5,
    )
    
    print(f"Found {len(result['pools'])} pools:\n")
    for pool in result["pools"]:
        tokens = "-".join(t["symbol"] for t in pool["tokens"])
        print(f"  {pool['protocol']['name']} | {tokens}")
        print(f"    TVL: ${pool['balance']['totalValueLockedUsd']:,.2f}")
        print(f"    24h Yield: {pool['stats']['stats24h']['yield']:.2f}%")
        print(f"    Address: {pool['address']}\n")


def find_best_yield_eth_usdc_on_base():
    """Find ETH-USDC pair pools on Base sorted by yield."""
    print("=== Best ETH-USDC pools on Base by 24h yield ===\n")
    
    result = search_pools(
        tokens_a=[{"chainId": ChainId.BASE, "address": Tokens.WETH_BASE}],
        tokens_b=[{"chainId": ChainId.BASE, "address": Tokens.USDC_BASE}],
        min_tvl=50_000,
        limit=5,
        order_by="yield",
        timeframe="24h",
    )
    
    print(f"Found {len(result['pools'])} ETH-USDC pools:\n")
    for pool in result["pools"]:
        print(f"  {pool['protocol']['name']} ({pool['type']})")
        print(f"    TVL: ${pool['balance']['totalValueLockedUsd']:,.2f}")
        print(f"    24h Yield: {pool['stats']['stats24h']['yield']:.2f}%")
        print(f"    7d Yield: {pool['stats']['stats7d']['yield']:.2f}%")
        print(f"    Fee: {pool['feeTier']['feeTierPercentage']}%\n")


def get_token_price(chain_id: int, token_address: str) -> float:
    """Get the USD price of a token."""
    response = requests.get(
        f"{BASE_URL}/tokens/prices/{chain_id}/{token_address}/usd",
        headers={"Authorization": f"Bearer {API_KEY}"},
    )
    
    if not response.ok:
        raise Exception(f"Failed to get price: {response.text}")
    
    return response.json()["data"]["price"]


def calculate_portfolio_value():
    """Calculate the value of a sample portfolio."""
    print("=== Calculating Portfolio Value ===\n")
    
    portfolio = [
        {"chainId": ChainId.ETHEREUM, "address": Tokens.ETH, "amount": 2, "symbol": "ETH"},
        {"chainId": ChainId.ETHEREUM, "address": Tokens.USDC_ETH, "amount": 1000, "symbol": "USDC"},
    ]
    
    total_value = 0
    for token in portfolio:
        price = get_token_price(token["chainId"], token["address"])
        value = price * token["amount"]
        total_value += value
        print(f"  {token['amount']} {token['symbol']}: ${value:,.2f} (@ ${price:,.2f})")
    
    print(f"\n  Total Portfolio Value: ${total_value:,.2f}")


if __name__ == "__main__":
    try:
        find_eth_pools()
        print("\n" + "=" * 50 + "\n")
        find_best_yield_eth_usdc_on_base()
        print("\n" + "=" * 50 + "\n")
        calculate_portfolio_value()
    except Exception as e:
        print(f"Error: {e}")
