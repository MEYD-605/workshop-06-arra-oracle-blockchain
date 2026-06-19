#!/bin/bash
set -e

# Configuration
CHAIN_ID=20260619
DATADIR="./data"
PASSWORD_FILE="password.txt"
GENESIS_FILE="genesis.json"

echo "=== Initializing Server PoA Node ==="

# Ensure geth is available in ~/bin or PATH
GETH_BIN="geth"
if [ -f "$HOME/bin/geth" ]; then
  GETH_BIN="$HOME/bin/geth"
fi
echo "Using Geth binary: $GETH_BIN"

# 1. Create password file
echo "no10password" > "$PASSWORD_FILE"
echo "Password file created."

# 2. Create account
echo "Creating new Ethereum signer account..."
ACCOUNT_OUTPUT=$($GETH_BIN account new --datadir "$DATADIR" --password "$PASSWORD_FILE")
echo "$ACCOUNT_OUTPUT"

# Extract address
ADDRESS_HEX=$(echo "$ACCOUNT_OUTPUT" | grep -oE "0x[a-fA-F0-9]{40}" | head -n 1)
ADDRESS_NO_0X=${ADDRESS_HEX#0x}
ADDRESS_LOWER=$(echo "$ADDRESS_NO_0X" | tr '[:upper:]' '[:lower:]')
ADDRESS_WITH_0X="0x$ADDRESS_LOWER"

echo "Signer address: $ADDRESS_WITH_0X"

# 3. Create genesis.json
echo "Generating $GENESIS_FILE..."
PREFIX="0000000000000000000000000000000000000000000000000000000000000000"
SEAL="0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
EXTRADATA="0x${PREFIX}${ADDRESS_LOWER}${SEAL}"

cat <<EOF > "$GENESIS_FILE"
{
  "config": {
    "chainId": $CHAIN_ID,
    "homesteadBlock": 0,
    "eip150Block": 0,
    "eip155Block": 0,
    "eip158Block": 0,
    "byzantiumBlock": 0,
    "constantinopleBlock": 0,
    "petersburgBlock": 0,
    "istanbulBlock": 0,
    "muirGlacierBlock": 0,
    "berlinBlock": 0,
    "londonBlock": 0,
    "arrowGlacierBlock": 0,
    "grayGlacierBlock": 0,
    "clique": {
      "period": 5,
      "epoch": 30000
    }
  },
  "difficulty": "1",
  "gasLimit": "30000000",
  "extradata": "$EXTRADATA",
  "alloc": {
    "$ADDRESS_WITH_0X": {
      "balance": "1000000000000000000000000000"
    }
  }
}
EOF

echo "genesis.json created successfully."

# 4. Initialize Geth datadir
echo "Initializing Geth database..."
$GETH_BIN init --datadir "$DATADIR" "$GENESIS_FILE"

echo "=== Server Setup Complete ==="
