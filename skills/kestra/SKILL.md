---
name: kestra
description: Trigger and monitor Kestra workflow flows in the OLS namespace at localhost:8080. List flows, run executions, check status, view logs. Use when asked to run a pipeline, trigger a flow, check pipeline status, or orchestrate data ingestion.
---

# Kestra — Workflow Orchestration

Kestra at `http://localhost:8080` orchestrates all OLS data pipelines.

**UI:** http://localhost:8080
**Namespace:** `ols`
**Tenant header (required on all requests):** `X-Kestra-Tenant: main`

---

## When This Skill Activates

**Explicit:** `/kestra`, "use kestra", "run a flow"

**Intent detection:**
- "Run the [flow name] pipeline"
- "Trigger the ingestion flow"
- "Check if my pipeline finished"
- "What Kestra flows do I have?"
- "Start the LanceDB ingestion"
- "Run the dataset prep flow"

---

## Setup Verification

```bash
curl -s http://localhost:8080/api/v1/flows/search?namespace=ols \
  -H "X-Kestra-Tenant: main" | python3 -c "
import sys,json
d=json.load(sys.stdin)
flows = d.get('results',[])
print(f'Kestra up — {len(flows)} flows in namespace ols')
"
```

---

## Quick Reference

| Task | Command |
|------|---------|
| List flows | `GET /api/v1/flows/search?namespace=ols` |
| Get flow detail | `GET /api/v1/flows/{namespace}/{flowId}` |
| Trigger flow | `POST /api/v1/executions/{namespace}/{flowId}` |
| Check execution | `GET /api/v1/executions/{executionId}` |
| List executions | `GET /api/v1/executions?namespace=ols` |
| Get logs | `GET /api/v1/logs/{executionId}` |
| KV get | `GET /api/v1/namespaces/ols/kv/{key}` |
| KV set | `PUT /api/v1/namespaces/ols/kv/{key}` |

**Headers required on every request:**
```bash
-H "X-Kestra-Tenant: main"
```

---

## Flows

### List all flows in OLS namespace
```bash
curl -s "http://localhost:8080/api/v1/flows/search?namespace=ols&size=50" \
  -H "X-Kestra-Tenant: main" | python3 -c "
import sys,json
d=json.load(sys.stdin)
flows = d.get('results',[])
print(f'Found {len(flows)} flows:\n')
for f in flows:
    print(f'  {f[\"namespace\"]}.{f[\"id\"]}')
    if f.get('description'): print(f'    {f[\"description\"]}')
"
```

### Get a specific flow's YAML
```bash
curl -s "http://localhost:8080/api/v1/flows/ols/<flow-id>" \
  -H "X-Kestra-Tenant: main" -H "Accept: application/x-yaml"
```

---

## Trigger Executions

### Trigger a flow (no inputs)
```bash
EXEC=$(curl -s -X POST "http://localhost:8080/api/v1/executions/ols/<flow-id>" \
  -H "X-Kestra-Tenant: main" \
  -H "Content-Type: multipart/form-data")
EXEC_ID=$(echo $EXEC | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")
echo "Execution: $EXEC_ID"
```

### Trigger a flow with inputs (form data)
```bash
EXEC=$(curl -s -X POST "http://localhost:8080/api/v1/executions/ols/<flow-id>" \
  -H "X-Kestra-Tenant: main" \
  -F "domain=sociology" \
  -F "limit=100")
EXEC_ID=$(echo $EXEC | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")
echo "Execution: $EXEC_ID"
```

**Note:** Kestra flow inputs use `-F "key=value"` (form-data), NOT JSON body.

---

## Monitor Executions

### Check execution status
```bash
curl -s "http://localhost:8080/api/v1/executions/$EXEC_ID" \
  -H "X-Kestra-Tenant: main" | python3 -c "
import sys,json
e = json.load(sys.stdin)
print(f'Flow:   {e[\"flowId\"]}')
print(f'State:  {e[\"state\"][\"current\"]}')
print(f'Start:  {e[\"state\"][\"startDate\"]}')
if e['state'].get('endDate'):
    print(f'End:    {e[\"state\"][\"endDate\"]}')
"
```

### Poll until execution completes
```bash
while true; do
  STATE=$(curl -s "http://localhost:8080/api/v1/executions/$EXEC_ID" \
    -H "X-Kestra-Tenant: main" | \
    python3 -c "import sys,json; print(json.load(sys.stdin)['state']['current'])")
  echo "State: $STATE"
  case $STATE in
    SUCCESS|FAILED|KILLED|WARNING) break ;;
  esac
  sleep 10
done
echo "Final state: $STATE"
```

### List recent executions
```bash
curl -s "http://localhost:8080/api/v1/executions?namespace=ols&size=10" \
  -H "X-Kestra-Tenant: main" | python3 -c "
import sys,json
d=json.load(sys.stdin)
execs = d.get('results',[])
for e in execs:
    state = e['state']['current']
    print(f'{e[\"id\"][:12]}  {e[\"flowId\"]:40s} {state}')
"
```

---

## Logs

### Get execution logs
```bash
curl -s "http://localhost:8080/api/v1/logs/$EXEC_ID?minLevel=INFO" \
  -H "X-Kestra-Tenant: main" | python3 -c "
import sys,json
logs = json.load(sys.stdin)
for l in logs.get('results',[]):
    print(f'[{l[\"level\"]}] {l[\"message\"]}')
" | tail -30
```

---

## KV Store

The KV store holds API keys and shared config for flows.

### Read a KV value
```bash
curl -s "http://localhost:8080/api/v1/namespaces/ols/kv/ANTHROPIC_API_KEY" \
  -H "X-Kestra-Tenant: main" | python3 -c "
import sys,json; d=json.load(sys.stdin); print(d.get('value',''))
"
```

### Set a KV value
```bash
curl -s -X PUT "http://localhost:8080/api/v1/namespaces/ols/kv/MY_KEY" \
  -H "X-Kestra-Tenant: main" \
  -H "Content-Type: text/plain" \
  -d "my-value"
```

**Note:** KV values use `Content-Type: text/plain`, not application/json.

### List all KV keys
```bash
curl -s "http://localhost:8080/api/v1/namespaces/ols/kv" \
  -H "X-Kestra-Tenant: main" | python3 -c "
import sys,json
keys = json.load(sys.stdin)
for k in keys: print(k.get('key',''))
"
```

---

## Common OLS Flows

| Flow ID | Purpose |
|---------|---------|
| LanceDB ingestion flows | Ingest papers into LanceDB domain tables |
| Dataset prep flows | Prepare training datasets |

Use `List all flows` command above to get current flow IDs — they may change between versions.

---

## Notes

- **Always include** `-H "X-Kestra-Tenant: main"` on every request
- Flow inputs use **form-data** (`-F`), not JSON body
- Kestra version: 1.3.3 — API paths use `/api/v1/`
- Docker compose at `~/kestra/` — working dir at `~/kestra/wd/`
- Process runner runs inside Kestra container; Docker runner can access host paths
