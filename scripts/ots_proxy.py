#!/usr/bin/env python3
import json
import urllib.request
import urllib.error
from http.server import HTTPServer, BaseHTTPRequestHandler
import sys

GETH_URL = "http://127.0.0.1:8512"

def post_to_geth(payload):
    req = urllib.request.Request(
        GETH_URL,
        data=json.dumps(payload).encode('utf-8'),
        headers={'Content-Type': 'application/json'}
    )
    try:
        with urllib.request.urlopen(req) as response:
            return json.loads(response.read().decode('utf-8'))
    except Exception as e:
        return {"jsonrpc": "2.0", "id": payload.get("id"), "error": {"code": -32603, "message": str(e)}}

def handle_single_request(req):
    method = req.get("method")
    params = req.get("params", [])
    req_id = req.get("id")
    
    if method == "ots_getApiLevel":
        return {"jsonrpc": "2.0", "id": req_id, "result": 8}
        
    elif method in ("erigon_getHeaderByNumber", "ots_getHeaderByNumber"):
        block_num = params[0] if params else "latest"
        geth_req = {
            "jsonrpc": "2.0",
            "method": "eth_getBlockByNumber",
            "params": [block_num, False],
            "id": req_id
        }
        res = post_to_geth(geth_req)
        return {"jsonrpc": "2.0", "id": req_id, "result": res.get("result")}
        
    elif method == "ots_getBlockDetails":
        block_num = params[0] if params else "latest"
        geth_req = {
            "jsonrpc": "2.0",
            "method": "eth_getBlockByNumber",
            "params": [block_num, True],
            "id": req_id
        }
        res = post_to_geth(geth_req)
        block = res.get("result")
        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "result": {
                "block": block,
                "totalFees": "0x0",
                "issuance": {
                    "blockReward": "0x0",
                    "uncleReward": "0x0",
                    "issuance": "0x0"
                }
            }
        }
        
    elif method == "ots_getBlockDetailsByHash":
        block_hash = params[0] if params else ""
        geth_req = {
            "jsonrpc": "2.0",
            "method": "eth_getBlockByHash",
            "params": [block_hash, True],
            "id": req_id
        }
        res = post_to_geth(geth_req)
        block = res.get("result")
        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "result": {
                "block": block,
                "totalFees": "0x0",
                "issuance": {
                    "blockReward": "0x0",
                    "uncleReward": "0x0",
                    "issuance": "0x0"
                }
            }
        }
        
    elif method == "ots_hasCode":
        address = params[0] if params else ""
        block_num = params[1] if len(params) > 1 else "latest"
        geth_req = {
            "jsonrpc": "2.0",
            "method": "eth_getCode",
            "params": [address, block_num],
            "id": req_id
        }
        res = post_to_geth(geth_req)
        code = res.get("result", "0x")
        has_code = code != "0x" and code != "0x0" and len(code) > 3
        return {"jsonrpc": "2.0", "id": req_id, "result": has_code}
        
    elif method in ("ots_searchTransactionsBefore", "ots_searchTransactionsAfter"):
        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "result": {
                "txs": [],
                "receipts": [],
                "firstPage": True,
                "lastPage": True
            }
        }
        
    elif method == "ots_getTransactionError":
        return {"jsonrpc": "2.0", "id": req_id, "result": "0x"}
        
    elif method == "ots_getContractCreator":
        return {"jsonrpc": "2.0", "id": req_id, "result": None}
        
    elif method == "ots_getInternalOperations":
        return {"jsonrpc": "2.0", "id": req_id, "result": []}
        
    else:
        # Forward directly to Geth
        return post_to_geth(req)

class ProxyHTTPRequestHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        # Suppress logging to prevent file bloat
        pass

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.end_headers()

    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        
        try:
            req_json = json.loads(post_data.decode('utf-8'))
        except Exception as e:
            self.send_response(400)
            self.end_headers()
            self.wfile.write(b"Invalid JSON")
            return
            
        if isinstance(req_json, list):
            # Batch request
            res_json = [handle_single_request(r) for r in req_json]
        else:
            # Single request
            res_json = handle_single_request(req_json)
            
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(json.dumps(res_json).encode('utf-8'))

    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain')
        self.end_headers()
        self.wfile.write(b"No.10 Otterscan RPC Shim Proxy is active")

def run(port=8510):
    server_address = ('', port)
    httpd = HTTPServer(server_address, ProxyHTTPRequestHandler)
    print(f"Starting Otterscan RPC proxy on port {port}...")
    httpd.serve_forever()

if __name__ == '__main__':
    port = 8510
    if len(sys.argv) > 1:
        port = int(sys.argv[1])
    run(port)
