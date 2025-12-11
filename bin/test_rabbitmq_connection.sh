#!/bin/bash
# Test RabbitMQ Connection
# Tests connection with optional username/password

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}Testing RabbitMQ Connection${NC}"
echo ""

# Find Python executable (check virtualenv first)
MCP_VENV="$HOME/code/dotfiles/mcp/venv/bin/python3"
if [[ ! -f "$MCP_VENV" ]]; then
    MCP_VENV="$HOME/code/personal/dotfiles/mcp/venv/bin/python3"
fi

if [[ -f "$MCP_VENV" ]]; then
    PYTHON_CMD="$MCP_VENV"
    echo "Using virtualenv Python: $PYTHON_CMD"
else
    PYTHON_CMD="python3"
    echo "Using system Python: $PYTHON_CMD"
fi

# Check if pika is installed
if ! "$PYTHON_CMD" -c "import pika" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  pika not installed. Installing...${NC}"
    if [[ -f "$MCP_VENV" ]]; then
        "$MCP_VENV/bin/pip" install pika
    else
        echo -e "${RED}Error: Cannot install pika. Please install in virtualenv:${NC}"
        echo "  cd ~/code/dotfiles/mcp && ./setup.sh"
        exit 1
    fi
fi

# Read config
GTD_CONFIG_DIR="${HOME}/code/dotfiles/zsh"
if [[ -f "${GTD_CONFIG_DIR}/.gtd_config_database" ]]; then
    source "${GTD_CONFIG_DIR}/.gtd_config_database"
fi

# Get RabbitMQ URL from env or config
RABBITMQ_URL="${RABBITMQ_URL:-amqp://localhost:5672}"
RABBITMQ_USER="${RABBITMQ_USER:-guest}"
RABBITMQ_PASS="${RABBITMQ_PASS:-}"

# Check if URL has credentials
if [[ "$RABBITMQ_URL" == *"@"* ]]; then
    echo -e "${GREEN}✓ URL contains credentials${NC}"
else
    # Build URL with credentials if provided
    if [[ -n "$RABBITMQ_USER" ]]; then
        if [[ -n "$RABBITMQ_PASS" ]]; then
            RABBITMQ_URL="amqp://${RABBITMQ_USER}:${RABBITMQ_PASS}@${RABBITMQ_URL#amqp://}"
        else
            RABBITMQ_URL="amqp://${RABBITMQ_USER}@${RABBITMQ_URL#amqp://}"
        fi
    fi
fi

echo "Connecting to: ${RABBITMQ_URL/\/\/.*@/\/\/***@}"  # Hide password
echo ""

# Test connection
"$PYTHON_CMD" << EOF
import pika
import sys

url = "${RABBITMQ_URL}"
queue = "gtd_deep_analysis"

try:
    print("Connecting to RabbitMQ...")
    connection = pika.BlockingConnection(
        pika.URLParameters(url)
    )
    channel = connection.channel()
    
    print("✓ Connected successfully")
    
    # Declare queue (creates if doesn't exist)
    print(f"Creating/checking queue: {queue}")
    result = channel.queue_declare(queue=queue, durable=True)
    print(f"✓ Queue '{queue}' ready (messages: {result.method.message_count})")
    
    # Also check/create the vectorization queue
    vector_queue = "gtd_vectorization"
    result2 = channel.queue_declare(queue=vector_queue, durable=True)
    print(f"✓ Queue '{vector_queue}' ready (messages: {result2.method.message_count})")
    
    # Test publish
    test_message = "test_connection"
    channel.basic_publish(
        exchange='',
        routing_key=queue,
        body=test_message,
        properties=pika.BasicProperties(delivery_mode=2)
    )
    print(f"✓ Test message published to {queue}")
    
    # Get message count
    result = channel.queue_declare(queue=queue, durable=True, passive=True)
    print(f"✓ Queue '{queue}' now has {result.method.message_count} message(s)")
    
    connection.close()
    print("\n✅ All tests passed!")
    
except pika.exceptions.ProbableAuthenticationError as e:
    print(f"\n❌ Authentication failed: {e}")
    print("   You may need to set RABBITMQ_USER and RABBITMQ_PASS")
    sys.exit(1)
except pika.exceptions.AMQPConnectionError as e:
    print(f"\n❌ Connection failed: {e}")
    print("   Is RabbitMQ accessible? Try:")
    print("   kubectl port-forward -n rabbitmq-system svc/rabbitmq 5672:5672")
    sys.exit(1)
except Exception as e:
    print(f"\n❌ Error: {e}")
    sys.exit(1)
EOF
