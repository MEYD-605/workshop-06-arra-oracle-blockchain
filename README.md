# Workshop 06: Arra Oracle Private Blockchain (Chain ID: 20260619)

This repository contains the configuration and scripts to run a private Ethereum blockchain using the **Clique Proof-of-Authority (PoA)** consensus engine.

## Architecture Overview
*   **Chain ID**: `20260619`
*   **Consensus**: Clique Proof-of-Authority (PoA)
*   **Server Node (natz-ai-03)**: Acts as the authority signer node, running Geth, producing blocks, and exposing the RPC endpoint.
*   **Local Node (LXC 110)**: Connects to the Server Node as a peer and synchronizes block state.

---

## 🚀 Server Setup & Execution

### 1. Initialize Server Node
Run the setup script on the remote server to generate the authority account, create `genesis.json` containing the Clique genesis configuration, and initialize Geth.
```bash
./scripts/setup_server.sh
```

### 2. Start Server Node
Run the node on the server. Geth will start mining blocks using the authority account.
```bash
./scripts/run_server.sh
```
*   **P2P Discovery Port**: `30310`
*   **HTTP RPC Port**: `8510`

---

## 💻 Local Setup & Sync

### 1. Initialize Local Node
Run the setup script locally. It will securely copy the `genesis.json` file from the server node via SSH and initialize the local Geth database.
```bash
./scripts/setup_local.sh
```

### 2. Start Local Node & Sync
Run the local execution script. It automatically queries the server node's enode address dynamically, injects the server's IP, and starts Geth with the server node as its bootnode.
```bash
./scripts/run_local.sh
```
*   **P2P Discovery Port**: `30303`
*   **HTTP RPC Port**: `8545`

The local node will connect to the server node and begin syncing blocks immediately.
