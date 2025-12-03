#!/bin/bash
# Check background worker status (Kubernetes or local)

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo "Checking Background Worker Status..."
echo ""

# Check Kubernetes deployment
if command -v kubectl &>/dev/null; then
    echo -e "${CYAN}Kubernetes Deployment:${NC}"
    
    if kubectl get deployment gtd-deep-analysis-worker &>/dev/null; then
        echo -e "  ${GREEN}✅ Deployment exists${NC}"
        
        # Get status
        status=$(kubectl get deployment gtd-deep-analysis-worker -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null)
        replicas=$(kubectl get deployment gtd-deep-analysis-worker -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        desired=$(kubectl get deployment gtd-deep-analysis-worker -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
        
        echo -e "  Replicas: $replicas/$desired"
        
        if [[ "$status" == "True" && "$replicas" == "$desired" && "$replicas" -gt 0 ]]; then
            echo -e "  ${GREEN}✅ Worker is running${NC}"
            
            # Show recent logs
            echo ""
            echo -e "${CYAN}Recent logs (last 5 lines):${NC}"
            kubectl logs -l app=gtd-deep-analysis-worker --tail=5 2>/dev/null || echo "  (no logs available)"
        else
            echo -e "  ${YELLOW}⚠️  Deployment not fully ready${NC}"
            echo ""
            echo -e "${CYAN}Debugging:${NC}"
            kubectl describe deployment gtd-deep-analysis-worker | grep -A 5 "Conditions:" 2>/dev/null || true
        fi
    else
        echo -e "  ${YELLOW}⚠️  Deployment not found${NC}"
        echo "  To deploy: kubectl apply -f mcp/kubernetes/deployment.yaml"
    fi
else
    echo -e "${CYAN}Kubernetes:${NC} kubectl not available"
fi

echo ""
echo -e "${CYAN}Local Process:${NC}"

# Check if worker is running locally
if pgrep -f "gtd_deep_analysis_worker.py" >/dev/null; then
    pid=$(pgrep -f "gtd_deep_analysis_worker.py")
    echo -e "  ${GREEN}✅ Worker process running (PID: $pid)${NC}"
    
    # Show process info
    ps -p "$pid" -o pid,etime,command 2>/dev/null || true
else
    echo -e "  ${CYAN}ℹ️  Worker not running locally${NC}"
    echo "  To start: python3 mcp/gtd_deep_analysis_worker.py file"
fi

echo ""
echo -e "${CYAN}Queue Status:${NC}"

# Check file queue
QUEUE_FILE="${HOME}/Documents/gtd/deep_analysis_queue.jsonl"
if [[ -f "$QUEUE_FILE" ]]; then
    queue_count=$(wc -l < "$QUEUE_FILE" 2>/dev/null || echo "0")
    if [[ "$queue_count" -gt 0 ]]; then
        echo -e "  ${YELLOW}⚠️  File queue has $queue_count item(s)${NC}"
        echo "  Recent items:"
        tail -3 "$QUEUE_FILE" | head -c 200
        echo ""
    else
        echo -e "  ${GREEN}✅ File queue is empty${NC}"
    fi
else
    echo -e "  ${CYAN}ℹ️  No queue file (worker hasn't processed anything)${NC}"
fi

# Check RabbitMQ queue
if command -v rabbitmqctl &>/dev/null && rabbitmqctl status >/dev/null 2>&1; then
    echo ""
    echo -e "${CYAN}RabbitMQ Queue:${NC}"
    queue_info=$(rabbitmqctl list_queues name messages 2>/dev/null | grep "gtd_deep_analysis" || echo "")
    if [[ -n "$queue_info" ]]; then
        echo "  $queue_info"
    else
        echo -e "  ${CYAN}ℹ️  Queue 'gtd_deep_analysis' not found${NC}"
    fi
fi

echo ""
echo -e "${CYAN}Results:${NC}"
RESULTS_DIR="${HOME}/Documents/gtd/deep_analysis_results"
if [[ -d "$RESULTS_DIR" ]]; then
    result_count=$(find "$RESULTS_DIR" -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$result_count" -gt 0 ]]; then
        echo -e "  ${GREEN}✅ $result_count result(s)${NC}"
        echo "  Latest results:"
        ls -t "$RESULTS_DIR"/*.json 2>/dev/null | head -3 | while read f; do
            echo "    - $(basename "$f")"
        done
    else
        echo -e "  ${CYAN}ℹ️  No results yet${NC}"
    fi
else
    echo -e "  ${CYAN}ℹ️  Results directory doesn't exist${NC}"
fi

echo ""

