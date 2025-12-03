#!/bin/bash
# Deployment script for GTD Deep Analysis Worker on Kubernetes

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="$SCRIPT_DIR/kubernetes"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ACTION="${1:-help}"

show_help() {
    echo ""
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}☸️  GTD Deep Analysis Worker Deployment${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Usage: $0 [action]"
    echo ""
    echo "Actions:"
    echo "  build         - Build Docker image"
    echo "  deploy        - Deploy to Kubernetes"
    echo "  undeploy      - Remove from Kubernetes"
    echo "  status        - Check deployment status"
    echo "  logs          - View worker logs"
    echo "  update        - Update deployment (rebuild & redeploy)"
    echo "  help          - Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 build              # Build Docker image"
    echo "  $0 deploy             # Deploy to Kubernetes"
    echo "  $0 status             # Check status"
    echo "  $0 logs               # View logs"
    echo ""
}

check_prerequisites() {
    local missing=0
    
    echo -e "${CYAN}Checking prerequisites...${NC}"
    
    if ! command -v kubectl &>/dev/null; then
        echo -e "${RED}❌ kubectl not found${NC}"
        missing=1
    else
        echo -e "${GREEN}✓ kubectl found${NC}"
    fi
    
    if ! command -v docker &>/dev/null && ! command -v podman &>/dev/null; then
        echo -e "${YELLOW}⚠️  docker/podman not found (needed for build)${NC}"
    else
        if command -v docker &>/dev/null; then
            echo -e "${GREEN}✓ docker found${NC}"
        else
            echo -e "${GREEN}✓ podman found${NC}"
        fi
    fi
    
    # Check Kubernetes connection
    if kubectl cluster-info &>/dev/null 2>&1; then
        echo -e "${GREEN}✓ Kubernetes cluster accessible${NC}"
    else
        echo -e "${RED}❌ Cannot connect to Kubernetes cluster${NC}"
        missing=1
    fi
    
    echo ""
    
    if [[ $missing -eq 1 ]]; then
        echo -e "${RED}Prerequisites not met. Please install missing tools.${NC}"
        exit 1
    fi
}

build_image() {
    echo ""
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}🐳 Building Docker Image${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Get registry from environment or prompt
    if [[ -z "$DOCKER_REGISTRY" ]]; then
        echo -n "Docker registry (e.g., registry.example.com or leave empty for local): "
        read DOCKER_REGISTRY
    fi
    
    IMAGE_NAME="${DOCKER_REGISTRY:+$DOCKER_REGISTRY/}gtd-worker"
    IMAGE_TAG="${2:-latest}"
    FULL_IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"
    
    echo "Building image: $FULL_IMAGE"
    echo ""
    
    # Use docker or podman
    DOCKER_CMD="docker"
    if ! command -v docker &>/dev/null && command -v podman &>/dev/null; then
        DOCKER_CMD="podman"
    fi
    
    cd "$DOTFILES_DIR"
    
    $DOCKER_CMD build -f "$SCRIPT_DIR/Dockerfile" -t "$FULL_IMAGE" .
    
    echo ""
    echo -e "${GREEN}✓ Image built successfully${NC}"
    echo ""
    
    # Ask to push if registry is set
    if [[ -n "$DOCKER_REGISTRY" ]]; then
        echo -n "Push image to registry? (y/n): "
        read push_choice
        if [[ "$push_choice" == "y" || "$push_choice" == "Y" ]]; then
            echo "Pushing image..."
            $DOCKER_CMD push "$FULL_IMAGE"
            echo -e "${GREEN}✓ Image pushed${NC}"
        fi
    fi
    
    # Save image name for deployment
    echo "$FULL_IMAGE" > "$SCRIPT_DIR/.last_image"
}

deploy() {
    echo ""
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}☸️  Deploying to Kubernetes${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    check_prerequisites
    
    # Check if image is specified
    IMAGE_FILE="$SCRIPT_DIR/.last_image"
    if [[ -f "$IMAGE_FILE" ]]; then
        LAST_IMAGE=$(cat "$IMAGE_FILE")
        echo "Last built image: $LAST_IMAGE"
        echo ""
        echo -n "Use this image? (y/n): "
        read use_image
        if [[ "$use_image" == "y" || "$use_image" == "Y" ]]; then
            IMAGE_NAME="$LAST_IMAGE"
        else
            echo -n "Enter image name: "
            read IMAGE_NAME
        fi
    else
        echo -n "Docker image name (e.g., gtd-worker:latest): "
        read IMAGE_NAME
    fi
    
    echo ""
    
    # Update deployment.yaml with image
    DEPLOYMENT_FILE="$K8S_DIR/deployment.yaml"
    if [[ -f "$DEPLOYMENT_FILE" ]]; then
        # Create temporary deployment with updated image
        TEMP_DEPLOY=$(mktemp)
        
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed "s|your-registry/gtd-worker:latest|$IMAGE_NAME|g" "$DEPLOYMENT_FILE" > "$TEMP_DEPLOY"
        else
            sed "s|your-registry/gtd-worker:latest|$IMAGE_NAME|g" "$DEPLOYMENT_FILE" > "$TEMP_DEPLOY"
        fi
        
        echo "Creating/updating secrets..."
        # Create secrets if needed
        if ! kubectl get secret gtd-secrets &>/dev/null 2>&1; then
            echo -n "RabbitMQ URL (e.g., amqp://rabbitmq:5672): "
            read RABBITMQ_URL
            RABBITMQ_URL="${RABBITMQ_URL:-amqp://rabbitmq:5672}"
            
            kubectl create secret generic gtd-secrets \
                --from-literal=rabbitmq-url="$RABBITMQ_URL"
        else
            echo -e "${GREEN}✓ Secrets already exist${NC}"
        fi
        
        echo ""
        echo "Applying deployment..."
        kubectl apply -f "$TEMP_DEPLOY"
        kubectl apply -f "$K8S_DIR/service.yaml"
        
        rm "$TEMP_DEPLOY"
        
        echo ""
        echo -e "${GREEN}✓ Deployment applied${NC}"
        echo ""
        echo "Waiting for pods to be ready..."
        kubectl wait --for=condition=ready pod -l app=gtd-deep-analysis-worker --timeout=120s || true
        
        echo ""
        echo "Deployment status:"
        kubectl get pods -l app=gtd-deep-analysis-worker
    else
        echo -e "${RED}❌ Deployment file not found: $DEPLOYMENT_FILE${NC}"
        exit 1
    fi
}

undeploy() {
    echo ""
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}🗑️  Removing Deployment${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    check_prerequisites
    
    echo "Removing deployment..."
    kubectl delete -f "$K8S_DIR/deployment.yaml" 2>/dev/null || true
    kubectl delete -f "$K8S_DIR/service.yaml" 2>/dev/null || true
    
    echo ""
    echo -e "${GREEN}✓ Deployment removed${NC}"
}

status() {
    echo ""
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}📊 Deployment Status${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    if ! kubectl cluster-info &>/dev/null 2>&1; then
        echo -e "${RED}❌ Cannot connect to Kubernetes cluster${NC}"
        exit 1
    fi
    
    # Check deployment
    if kubectl get deployment gtd-deep-analysis-worker &>/dev/null 2>&1; then
        echo -e "${GREEN}✓ Deployment exists${NC}"
        echo ""
        kubectl get deployment gtd-deep-analysis-worker
        echo ""
        kubectl get pods -l app=gtd-deep-analysis-worker
    else
        echo -e "${YELLOW}⚠️  Deployment not found${NC}"
    fi
}

logs() {
    echo ""
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}📋 Worker Logs${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    if kubectl get pods -l app=gtd-deep-analysis-worker &>/dev/null 2>&1; then
        kubectl logs -l app=gtd-deep-analysis-worker -f
    else
        echo -e "${RED}❌ No worker pods found${NC}"
        exit 1
    fi
}

update() {
    echo ""
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}🔄 Updating Deployment${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    build_image "$@"
    deploy
}

case "$ACTION" in
    build)
        build_image "$@"
        ;;
    deploy)
        deploy
        ;;
    undeploy)
        undeploy
        ;;
    status)
        status
        ;;
    logs)
        logs
        ;;
    update)
        update "$@"
        ;;
    help|--help|-h|"")
        show_help
        ;;
    *)
        echo -e "${RED}Unknown action: $ACTION${NC}"
        show_help
        exit 1
        ;;
esac

