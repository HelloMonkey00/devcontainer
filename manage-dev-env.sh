# Environment management script
# File: manage-dev-env.sh

#!/bin/bash

DEV_ENV_NAME="my-dev-env"
DOCKER_HUB_REPO=""  # Docker Hub repository for backup, e.g., "username/my-dev-env"
LOCAL_BACKUP_DIR="$HOME/dev-env-backups"

function show_help() {
    echo "Development Environment Management Tool"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  start         Start development environment"
    echo "  stop          Stop development environment"
    echo "  restart       Restart development environment"
    echo "  backup        Backup environment to Docker Hub"
    echo "  restore       Restore environment from Docker Hub"
    echo "  list-backups  List all available backups"
    echo "  setup-hub     Configure Docker Hub repository"
    echo "  shell         Enter development environment shell"
    echo "  logs          View container logs"
    echo "  status        View environment status"
    echo "  clean         Clean unused Docker resources"
    echo "  check-deps    Check host machine dependency directories"
    echo "  help          Show this help information"
}

function start_env() {
    echo "🚀 Starting development environment..."
    docker-compose up -d
    echo "✅ Development environment started!"
    echo "🌐 VS Code access URL: http://localhost:8080"
}

function stop_env() {
    echo "⏹️ Stopping development environment..."
    docker-compose down
    echo "✅ Development environment stopped!"
}

function restart_env() {
    echo "🔄 Restarting development environment..."
    docker-compose restart
    echo "✅ Development environment restarted!"
}

function setup_docker_hub() {
    echo "🔧 Configuring Docker Hub backup..."
    echo "Please provide your Docker Hub information:"
    
    read -p "Docker Hub username: " hub_username
    read -p "Repository name (e.g., my-dev-env): " repo_name
    
    DOCKER_HUB_REPO="$hub_username/$repo_name"
    
    # Update script configuration
    sed -i "s/DOCKER_HUB_REPO=\"\"/DOCKER_HUB_REPO=\"$DOCKER_HUB_REPO\"/" "$0"
    
    echo "✅ Docker Hub configuration completed"
    echo "📂 Repository: $DOCKER_HUB_REPO"
    
    # Test Docker Hub login
    echo "🔐 Please login to Docker Hub..."
    docker login
}

function backup_env() {
    echo "💾 Starting environment backup to Docker Hub..."
    
    # Check Docker Hub configuration
    if [ -z "$DOCKER_HUB_REPO" ]; then
        echo "⚠️ Docker Hub repository not configured"
        echo "Please run: $0 setup-hub"
        return 1
    fi
    
    # Create backup timestamp
    BACKUP_DATE=$(date +"%Y%m%d_%H%M%S")
    BACKUP_TAG="backup-$BACKUP_DATE"
    
    echo "📦 Creating backup image..."
    
    # Stop container to ensure data consistency
    echo "⏸️ Stopping container for consistent backup..."
    docker-compose stop
    
    # Commit current container state to new image
    echo "📸 Creating image snapshot..."
    docker commit "$DEV_ENV_NAME" "$DOCKER_HUB_REPO:$BACKUP_TAG"
    
    # Also tag as latest backup
    docker tag "$DOCKER_HUB_REPO:$BACKUP_TAG" "$DOCKER_HUB_REPO:latest-backup"
    
    # Push to Docker Hub
    echo "☁️ Pushing to Docker Hub..."
    docker push "$DOCKER_HUB_REPO:$BACKUP_TAG"
    docker push "$DOCKER_HUB_REPO:latest-backup"
    
    # Create local workspace backup
    echo "📁 Backing up workspace locally..."
    mkdir -p "$LOCAL_BACKUP_DIR"
    tar -czf "$LOCAL_BACKUP_DIR/workspace-$BACKUP_DATE.tar.gz" \
        -C . workspace/ \
        --exclude="workspace/node_modules" \
        --exclude="workspace/target" \
        --exclude="workspace/build"
    
    # Restart container
    docker-compose start
    
    echo "✅ Backup completed!"
    echo "🐳 Docker Hub image: $DOCKER_HUB_REPO:$BACKUP_TAG"
    echo "📂 Local workspace: $LOCAL_BACKUP_DIR/workspace-$BACKUP_DATE.tar.gz"
    
    # Clean up old local images (keep last 3)
    cleanup_old_images
}

function restore_env() {
    echo "📥 Restoring environment from Docker Hub backup..."
    
    if [ -z "$DOCKER_HUB_REPO" ]; then
        echo "❌ Docker Hub repository not configured"
        echo "Please run: $0 setup-hub"
        return 1
    fi
    
    # List available backups
    echo "Available backups on Docker Hub:"
    docker search "$DOCKER_HUB_REPO" --limit 10 2>/dev/null || {
        echo "Fetching available tags..."
        # Alternative method to list tags
        curl -s "https://registry.hub.docker.com/v2/repositories/$DOCKER_HUB_REPO/tags/" | \
        grep -o '"name":"[^"]*"' | cut -d'"' -f4 | head -10
    }
    
    echo ""
    read -p "Enter backup tag to restore (or 'latest-backup' for latest): " backup_tag
    
    if [ -z "$backup_tag" ]; then
        backup_tag="latest-backup"
    fi
    
    # Stop current environment
    docker-compose down
    
    # Pull backup image
    echo "📥 Pulling backup image..."
    docker pull "$DOCKER_HUB_REPO:$backup_tag"
    
    # Create temporary docker-compose file with backup image
    echo "🔄 Creating temporary configuration..."
    cat > docker-compose.backup.yml << EOF
services:
  dev-environment:
    image: $DOCKER_HUB_REPO:$backup_tag
    container_name: my-dev-env
    hostname: dev-container
    volumes:
      # Persistent code directory
      - ./workspace:/workspace
      # Persistent VS Code configuration and extensions
      - vscode-server:/root/.vscode-server
      - vscode-extensions:/root/.vscode-server/extensions
      # Persistent development tools configuration
      - dev-config:/root/.config
      - dev-cache:/root/.cache
      # Shared host machine configurations (read-only)
      - ~/.gitconfig:/root/.gitconfig:ro
      - ~/.ssh:/root/.ssh:ro
      # Shared host machine dependency directories (read-write, saves disk space)
      - ~/.m2:/root/.m2
      - ~/.gradle:/root/.gradle
      - ~/go/pkg/mod:/go/pkg/mod
      - ~/Library/Caches/go-build:/root/.cache/go-build
      # Share existing Java dependencies if available
      - ~/.ivy2:/root/.ivy2
      # Python package cache sharing
      - ~/.cache/pip:/root/.cache/pip
    ports:
      - "8080:8080"   # Common web development port
      - "3000:3000"   # Node.js/React development port
      - "5000:5000"   # Python Flask development port
      - "8000:8000"   # Other web service port
    environment:
      - WORKSPACE=/workspace
      - GOPROXY=https://goproxy.cn,direct
      - GO111MODULE=on
    stdin_open: true
    tty: true
    restart: unless-stopped
    working_dir: /workspace

volumes:
  vscode-server:
    driver: local
  vscode-extensions:
    driver: local
  dev-config:
    driver: local
  dev-cache:
    driver: local
EOF
    
    # Start from backup
    docker-compose -f docker-compose.backup.yml up -d
    
    # Restore workspace if available
    BACKUP_DATE=$(echo "$backup_tag" | grep -o '[0-9]\{8\}_[0-9]\{6\}')
    if [ -n "$BACKUP_DATE" ] && [ -f "$LOCAL_BACKUP_DIR/workspace-$BACKUP_DATE.tar.gz" ]; then
        echo "📁 Restoring workspace..."
        tar -xzf "$LOCAL_BACKUP_DIR/workspace-$BACKUP_DATE.tar.gz"
    fi
    
    echo "✅ Restore completed!"
    echo "🗑️ Clean up temporary files..."
    rm -f docker-compose.backup.yml
}

function list_backups() {
    echo "📋 Available backups:"
    
    if [ -z "$DOCKER_HUB_REPO" ]; then
        echo "❌ Docker Hub repository not configured"
        return 1
    fi
    
    echo "🐳 Docker Hub backups:"
    # Try to list Docker Hub tags
    curl -s "https://registry.hub.docker.com/v2/repositories/$DOCKER_HUB_REPO/tags/" 2>/dev/null | \
    python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for tag in data.get('results', []):
        name = tag.get('name', '')
        if 'backup' in name:
            print(f\"  - {name}\")
except:
    print('  Unable to fetch Docker Hub tags')
" || echo "  Unable to fetch Docker Hub tags"
    
    echo ""
    echo "📁 Local workspace backups:"
    if [ -d "$LOCAL_BACKUP_DIR" ]; then
        ls -lah "$LOCAL_BACKUP_DIR"/*.tar.gz 2>/dev/null | awk '{print "  - " $9 " (" $5 ", " $6 " " $7 " " $8 ")"}' || echo "  No local backups found"
    else
        echo "  No local backup directory found"
    fi
}

function cleanup_old_images() {
    echo "🧹 Cleaning up old backup images..."
    # Keep only the last 3 backup images locally
    docker images "$DOCKER_HUB_REPO" --format "table {{.Tag}}\t{{.CreatedAt}}" | \
    grep backup | tail -n +4 | awk '{print $1}' | \
    xargs -I {} docker rmi "$DOCKER_HUB_REPO:{}" 2>/dev/null || true
}

function check_host_deps() {
    echo "🔍 Checking host machine dependency directories..."
    
    # Check and create required directories
    REQUIRED_DIRS=(
        "$HOME/.m2"
        "$HOME/.gradle" 
        "$HOME/go/pkg/mod"
        "$HOME/Library/Caches/go-build"
        "$HOME/.ivy2"
        "$HOME/.cache/pip"
    )
    
    for dir in "${REQUIRED_DIRS[@]}"; do
        if [ ! -d "$dir" ]; then
            echo "📁 Creating directory: $dir"
            mkdir -p "$dir"
        else
            echo "✅ Directory exists: $dir"
        fi
    done
    
    # Check SSH configuration
    if [ ! -d "$HOME/.ssh" ]; then
        echo "⚠️ Warning: SSH directory does not exist, please configure SSH first"
    else
        echo "✅ SSH directory exists"
    fi
    
    # Check Git configuration
    if [ ! -f "$HOME/.gitconfig" ]; then
        echo "⚠️ Warning: Git configuration file does not exist, please configure Git first"
    else
        echo "✅ Git configuration exists"
    fi
    
    echo "✅ Dependency check completed!"
}

function enter_shell() {
    echo "🐚 Entering development environment shell..."
    docker exec -it "$DEV_ENV_NAME" /bin/bash
}

function show_logs() {
    echo "📝 Development environment logs:"
    docker-compose logs -f
}

function show_status() {
    echo "📊 Development environment status:"
    docker-compose ps
    echo ""
    echo "🔧 Docker resource usage:"
    docker system df
}

function clean_docker() {
    echo "🧹 Cleaning unused Docker resources..."
    docker system prune -f
    docker volume prune -f
    echo "✅ Cleanup completed!"
}

# Main program
case "${1:-help}" in
    start)
        check_host_deps
        start_env
        ;;
    stop)
        stop_env
        ;;
    restart)
        restart_env
        ;;
    backup)
        backup_env
        ;;
    restore)
        restore_env
        ;;
    list-backups)
        list_backups
        ;;
    setup-hub)
        setup_docker_hub
        ;;
    check-deps)
        check_host_deps
        ;;
    shell)
        enter_shell
        ;;
    logs)
        show_logs
        ;;
    status)
        show_status
        ;;
    clean)
        clean_docker
        ;;
    help|*)
        show_help
        ;;
esac