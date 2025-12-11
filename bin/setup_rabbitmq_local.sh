#!/bin/bash
# Setup RabbitMQ port-forward for local access
# Enhanced version with connection retry and keepalive

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}Setting up RabbitMQ port-forward...${NC}"
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${YELLOW}⚠️  kubectl not found. Cannot set up port-forward.${NC}"
    exit 1
fi

# Check if RabbitMQ service exists
if ! kubectl get svc -n rabbitmq-system rabbitmq &> /dev/null; then
    echo -e "${YELLOW}⚠️  RabbitMQ service not found in rabbitmq-system namespace${NC}"
    exit 1
fi

# Function to check if port-forward is already running
check_existing_portforward() {
    local existing_pf=$(ps aux | grep "kubectl port-forward.*5672" | grep -v grep | awk '{print $2}')
    if [[ -n "$existing_pf" ]]; then
        echo -e "${YELLOW}⚠️  Port-forward already running (PID: $existing_pf)${NC}"
        echo "   Kill existing process? (y/n): "
        read -r kill_choice
        if [[ "$kill_choice" == "y" || "$kill_choice" == "Y" ]]; then
            kill "$existing_pf" 2>/dev/null || true
            sleep 1
            echo -e "${GREEN}✓ Killed existing port-forward${NC}"
        else
            echo "Using existing port-forward..."
            exit 0
        fi
    fi
}

check_existing_portforward

echo "Starting port-forward to RabbitMQ..."
echo ""
echo "Ports being forwarded:"
echo "  📨 AMQP: localhost:5672 → rabbitmq:5672 (for queue connections)"
echo "  🌐 Management UI: localhost:15672 → rabbitmq:15672 (web interface)"
echo "  📊 Prometheus: localhost:15692 → rabbitmq:15692 (metrics)"
echo ""
echo -e "${YELLOW}Note:${NC} Connection resets are normal when connections close."
echo -e "${YELLOW}      ${NC} If you see frequent resets, RabbitMQ pod may be restarting."
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
echo ""

# Function to handle cleanup on exit
cleanup() {
    echo ""
    echo -e "${CYAN}Port-forward stopped.${NC}"
    exit 0
}

trap cleanup INT TERM

# Start port-forward with retry logic
RETRY_COUNT=0
MAX_RETRIES=10
RETRY_DELAY=3

# Function to verify port-forward is working
verify_portforward() {
    # Wait a moment for port to be ready
    sleep 1
    # Check if port is accessible
    if nc -zv localhost 5672 &>/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

while true; do
    echo -e "${GREEN}Starting port-forward (attempt $((RETRY_COUNT + 1)))...${NC}"
    
    # Start port-forward in background and capture PID
    kubectl port-forward -n rabbitmq-system svc/rabbitmq 5672:5672 15672:15672 15692:15692 > /tmp/rabbitmq-pf.log 2>&1 &
    PF_PID=$!
    
    # Wait a moment and verify connection
    sleep 2
    
    if verify_portforward; then
        echo -e "${GREEN}✓ Port-forward established and verified${NC}"
        echo "   PID: $PF_PID"
        echo "   Logs: tail -f /tmp/rabbitmq-pf.log"
        echo ""
        
        # Wait for port-forward to exit (or be interrupted)
        wait $PF_PID
        PF_EXIT_CODE=$?
        
        if [[ $PF_EXIT_CODE -eq 0 ]]; then
            # Normal exit (probably Ctrl+C)
            break
        else
            # Unexpected exit
            RETRY_COUNT=$((RETRY_COUNT + 1))
            if [[ $RETRY_COUNT -ge $MAX_RETRIES ]]; then
                echo ""
                echo -e "${RED}❌ Port-forward failed after ${MAX_RETRIES} attempts.${NC}"
                echo "   Check RabbitMQ pod status: kubectl get pods -n rabbitmq-system"
                echo "   Check logs: cat /tmp/rabbitmq-pf.log"
                exit 1
            fi
            
            echo ""
            echo -e "${YELLOW}⚠️  Port-forward disconnected (exit code: $PF_EXIT_CODE)${NC}"
            echo "   Retrying in ${RETRY_DELAY} seconds... (${RETRY_COUNT}/${MAX_RETRIES})"
            sleep $RETRY_DELAY
        fi
    else
        # Port-forward started but port not accessible
        kill $PF_PID 2>/dev/null || true
        RETRY_COUNT=$((RETRY_COUNT + 1))
        
        if [[ $RETRY_COUNT -ge $MAX_RETRIES ]]; then
            echo ""
            echo -e "${RED}❌ Port-forward failed to establish connection after ${MAX_RETRIES} attempts.${NC}"
            echo "   Check RabbitMQ pod status: kubectl get pods -n rabbitmq-system"
            echo "   Check logs: cat /tmp/rabbitmq-pf.log"
            exit 1
        fi
        
        echo -e "${YELLOW}⚠️  Port not accessible. Retrying in ${RETRY_DELAY} seconds... (${RETRY_COUNT}/${MAX_RETRIES})${NC}"
        sleep $RETRY_DELAY
    fi
done
