# Ollama Controller Integration - Required Changes

This document lists all the files and changes needed to switch from direct Ollama connections to using the Ollama Controller system.

## Summary

**Current State:**
- GTD system connects directly to Ollama at `http://localhost:11434/v1/chat/completions`
- Uses OpenAI-compatible API format
- Direct connection, no throttling or queuing

**Target State:**
- GTD system connects to Ollama Controller API at `http://<NODE_IP>:31080/api/chat`
- Uses Ollama-native API format (needs adapter)
- Benefits: Throttling, queuing, monitoring, reliability

## Required Changes

### 1. Infrastructure Changes

#### A. Create NodePort Service for Controller API
**File:** `external_services/ollama_controller/kubernetes/ollama-controller-api-nodeport.yaml` (NEW)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: ollama-controller-api-nodeport
  namespace: ollama-controller
  labels:
    app: ollama-controller-api
    service-type: nodeport
spec:
  type: NodePort
  ports:
  - port: 8080
    targetPort: 8080
    nodePort: 31080
    protocol: TCP
    name: api
  selector:
    app: ollama-controller-api
```

**Action:** Create this file and deploy with `kubectl apply`

#### B. Update verify-nodeport Script
**File:** `bin/verify-nodeport`

**Changes:**
- Add check for Ollama Controller API NodePort (31080)
- Add connectivity test for controller API
- Update documentation

**Location:** After RabbitMQ checks, add Ollama Controller API section

### 2. Configuration Changes

#### A. Update configure-ollama-kubernetes Script
**File:** `bin/configure-ollama-kubernetes`

**Changes:**
- Change NodePort from 31134 (Ollama) to 31080 (Controller API)
- Update URL format from `/v1/chat/completions` to `/api/chat`
- Update service name checks
- Update connection tests

**Key Changes:**
```bash
# OLD:
OLLAMA_URL="http://$NODE_IP:31134/v1/chat/completions"
NODEPORT_SVC="ollama-service"

# NEW:
OLLAMA_URL="http://$NODE_IP:31080/api/chat"
NODEPORT_SVC="ollama-controller-api-nodeport"
```

#### B. Configuration Files
**Files:**
- `zsh/.gtd_config_ai`
- `zsh/.gtd_config` (if OLLAMA_URL present)
- `zsh/.daily_log_config` (if OLLAMA_URL present)

**Changes:**
- Update `OLLAMA_URL` to point to controller API
- Format: `http://<NODE_IP>:31080/api/chat`

**Note:** These will be updated automatically by `configure-ollama-kubernetes` script

### 3. Python Code Changes

#### A. Create Format Adapter Module (NEW)
**File:** `zsh/functions/ollama_controller_adapter.py` (NEW)

**Purpose:** Convert between OpenAI format (used by GTD) and Ollama format (used by Controller)

**Functions Needed:**
1. `convert_openai_to_ollama_request(openai_request)` - Convert request format
2. `convert_ollama_to_openai_response(ollama_response)` - Convert response format
3. `is_controller_url(url)` - Check if URL points to controller
4. `should_use_controller(config)` - Determine if controller should be used

#### B. Update gtd_persona_helper.py
**File:** `zsh/functions/gtd_persona_helper.py`

**Function:** `call_persona()`

**Changes:**
1. Import adapter module
2. Check if using controller (via URL or config flag)
3. If controller:
   - Convert OpenAI request to Ollama format
   - Use `/api/chat` endpoint
   - Convert Ollama response back to OpenAI format
4. Update error messages to mention controller

**Location:** Around line 1117-1200 (where request is built and sent)

**Key Code Pattern:**
```python
# Check if using controller
from .ollama_controller_adapter import is_controller_url, convert_openai_to_ollama_request, convert_ollama_to_openai_response

if is_controller_url(config.get("url", "")):
    # Use controller format
    ollama_request = convert_openai_to_ollama_request({
        "model": model_name,
        "messages": messages,
        "temperature": temperature,
        "max_tokens": max_tokens
    })
    # Send to /api/chat
    # Convert response back
else:
    # Existing OpenAI format code
```

#### C. Update lmstudio_helper.py
**File:** `zsh/functions/lmstudio_helper.py`

**Function:** `call_lm_studio()`

**Changes:** Similar to `call_persona()` - add controller support with format conversion

**Location:** Around line 113-200

#### D. Update gtd_enhanced_search.py
**File:** `zsh/functions/gtd_enhanced_search.py`

**Class:** `EnhancedSearchSystem`
**Method:** `_call_llm()`

**Changes:** Add controller support with format conversion

**Location:** Around line 40-97

#### E. Update gtd_vectorization.py (if using Ollama for embeddings)
**File:** `zsh/functions/gtd_vectorization.py`

**Function:** `generate_embedding()`

**Changes:** 
- Check if using controller
- May need different endpoint for embeddings (check controller API docs)
- Update format if needed

**Location:** Around line 146+

### 4. Script/Bash Changes

#### A. Update gtd-wizard-tools.sh
**File:** `bin/gtd-wizard-tools.sh`

**Function:** AI connection testing (around line 2310-2400)

**Changes:**
1. Update test to check controller API endpoint
2. Update test payload format (Ollama vs OpenAI)
3. Update response parsing
4. Update error messages

**Key Changes:**
```bash
# OLD:
ollama_url="${OLLAMA_URL:-http://localhost:11434/v1/chat/completions}"
test_payload='{"model":"'$ollama_model'","messages":[{"role":"user","content":"test"}]}'

# NEW (if controller):
if [[ "$ollama_url" == *"/api/chat"* ]]; then
  # Controller format
  test_payload='{"model":"'$ollama_model'","messages":[{"role":"user","content":"test"}],"stream":false}'
else
  # Direct Ollama (OpenAI format)
  test_payload='{"model":"'$ollama_model'","messages":[{"role":"user","content":"test"}]}'
fi
```

#### B. Update gtd-wizard-core.sh
**File:** `bin/gtd-wizard-core.sh`

**Function:** `external_ollama_controller_wizard()`

**Changes:**
- Update connection info to show controller API URL
- Update test functions to use controller format
- Add note about format differences

**Location:** Around line 2869-3000

### 5. Documentation Updates

#### A. Update OLLAMA_KUBERNETES_SETUP.md
**File:** `docs/OLLAMA_KUBERNETES_SETUP.md`

**Changes:**
- Add note about controller API vs direct Ollama
- Update URL examples
- Add format conversion notes

#### B. Create OLLAMA_CONTROLLER_INTEGRATION.md
**File:** `docs/OLLAMA_CONTROLLER_INTEGRATION.md` (DONE)

**Content:** Complete integration guide

#### C. Update COMPLETE_SETUP_GUIDE.md
**File:** `docs/COMPLETE_SETUP_GUIDE.md`

**Changes:**
- Add section on Ollama Controller setup
- Update Ollama configuration section
- Add note about format differences

## Implementation Order

1. **Phase 1: Infrastructure**
   - Create NodePort service YAML
   - Deploy NodePort service
   - Update verify-nodeport script
   - Test connectivity

2. **Phase 2: Configuration**
   - Update configure-ollama-kubernetes script
   - Test configuration script
   - Update connection-info in Makefile

3. **Phase 3: Adapter Layer**
   - Create ollama_controller_adapter.py
   - Test format conversions
   - Add unit tests

4. **Phase 4: Python Functions**
   - Update gtd_persona_helper.py
   - Update lmstudio_helper.py
   - Update gtd_enhanced_search.py
   - Test each function

5. **Phase 5: Scripts**
   - Update gtd-wizard-tools.sh
   - Update gtd-wizard-core.sh
   - Test wizard integration

6. **Phase 6: Documentation**
   - Update all docs
   - Add troubleshooting guide
   - Create migration guide

## Testing Checklist

- [ ] NodePort service accessible
- [ ] Controller API health check works
- [ ] Format conversion works (OpenAI → Ollama → OpenAI)
- [ ] call_persona() works with controller
- [ ] call_lm_studio() works with controller
- [ ] Enhanced search works with controller
- [ ] Wizard tests pass
- [ ] Configuration script works
- [ ] Error messages are helpful
- [ ] Fallback to direct Ollama still works (if configured)

## Backward Compatibility

**Important:** The system should support both:
1. **Direct Ollama** (current): `http://localhost:11434/v1/chat/completions` (OpenAI format)
2. **Ollama Controller** (new): `http://<NODE_IP>:31080/api/chat` (Ollama format)

The adapter should detect which one is being used based on the URL and handle accordingly.

## Configuration Flag (Optional)

Consider adding a config flag to explicitly enable/disable controller:
```bash
OLLAMA_USE_CONTROLLER=true  # Use controller if available
OLLAMA_CONTROLLER_URL="http://<NODE_IP>:31080/api/chat"
```

This allows gradual migration and easy rollback.

## Priority

**High Priority:**
1. Create adapter module (enables all other changes)
2. Update gtd_persona_helper.py (most used function)
3. Create NodePort service (infrastructure)

**Medium Priority:**
4. Update other Python functions
5. Update configuration scripts
6. Update wizard tools

**Low Priority:**
7. Documentation updates
8. Additional features (async processing, callbacks)

