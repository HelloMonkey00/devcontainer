#!/bin/bash
# validate-config.sh - Configuration validation and fix script

echo "🔍 Validating development environment configuration..."

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check function
check_requirement() {
    local name="$1"
    local command="$2"
    local fix_suggestion="$3"
    
    if eval "$command" &>/dev/null; then
        echo -e "${GREEN}✅ $name${NC}"
        return 0
    else
        echo -e "${RED}❌ $name${NC}"
        if [ -n "$fix_suggestion" ]; then
            echo -e "   ${YELLOW}Fix suggestion: $fix_suggestion${NC}"
        fi
        return 1
    fi
}

echo -e "${BLUE}=== System Requirements Check ===${NC}"

# Check Docker
check_requirement "Docker Desktop" "docker --version" "Please install Docker Desktop for Mac"

# Check Docker Compose
check_requirement "Docker Compose" "docker-compose --version" "Docker Desktop usually includes this tool"

# Check Docker Hub login
check_requirement "Docker Hub Login" "docker info | grep Username" "Please run: docker login"

echo -e "\n${BLUE}=== Host Machine Dependency Directories Check ===${NC}"

# Check directories
REQUIRED_DIRS=(
    "$HOME/.m2:Maven cache directory"
    "$HOME/.gradle:Gradle cache directory" 
    "$HOME/go/pkg/mod:Go module cache directory"
    "$HOME/Library/Caches/go-build:Go build cache directory"
    "$HOME/.ivy2:Ivy cache directory"
    "$HOME/.cache/pip:Python cache directory"
    "$HOME/.ssh:SSH configuration directory"
)

for dir_info in "${REQUIRED_DIRS[@]}"; do
    IFS=':' read -r dir desc <<< "$dir_info"
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✅ $desc: $dir${NC}"
    else
        echo -e "${YELLOW}⚠️ $desc does not exist: $dir${NC}"
        echo -e "   ${BLUE}Creating...${NC}"
        mkdir -p "$dir"
        if [ -d "$dir" ]; then
            echo -e "   ${GREEN}✅ Created successfully${NC}"
        else
            echo -e "   ${RED}❌ Creation failed${NC}"
        fi
    fi
done

echo -e "\n${BLUE}=== Git Configuration Check ===${NC}"

if [ -f "$HOME/.gitconfig" ]; then
    echo -e "${GREEN}✅ Git configuration file exists${NC}"
    # Check basic configuration
    if git config --global user.name &>/dev/null && git config --global user.email &>/dev/null; then
        echo -e "${GREEN}✅ Git user information configured${NC}"
        echo -e "   Username: $(git config --global user.name)"
        echo -e "   Email: $(git config --global user.email)"
    else
        echo -e "${YELLOW}⚠️ Git user information not fully configured${NC}"
        echo -e "   ${BLUE}Please run:${NC}"
        echo -e "   git config --global user.name \"Your Name\""
        echo -e "   git config --global user.email \"your.email@example.com\""
    fi
else
    echo -e "${RED}❌ Git configuration file does not exist${NC}"
    echo -e "   ${BLUE}Please configure Git first${NC}"
fi

echo -e "\n${BLUE}=== Version Validation ===${NC}"

# Validate Go version URL
echo -e "${BLUE}Validating Go 1.23.5 download link...${NC}"
if curl -s --head "https://go.dev/dl/go1.23.5.linux-amd64.tar.gz" | head -n 1 | grep -q "200 OK"; then
    echo -e "${GREEN}✅ Go 1.23.5 download link is valid${NC}"
else
    echo -e "${YELLOW}⚠️ Go 1.23.5 link may be invalid, please check latest version${NC}"
    echo -e "   Visit: https://go.dev/dl/"
fi

# Validate Claude Code installation URL
echo -e "${BLUE}Validating Claude Code installation...${NC}"
if curl -s --head "https://claude.ai/install.sh" | head -n 1 | grep -q "200 OK"; then
    echo -e "${GREEN}✅ Claude Code installation script is accessible${NC}"
else
    echo -e "${YELLOW}⚠️ Claude Code installation URL may be invalid${NC}"
    echo -e "   Alternative: npm install -g @anthropic-ai/claude-code"
fi

echo -e "\n${BLUE}=== Docker Hub Configuration Check ===${NC}"

# Check Docker Hub repository configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANAGE_SCRIPT="$SCRIPT_DIR/manage-dev-env.sh"

if [ -f "$MANAGE_SCRIPT" ]; then
    DOCKER_HUB_REPO=$(grep 'DOCKER_HUB_REPO=' "$MANAGE_SCRIPT" | cut -d'"' -f2)
    if [ -n "$DOCKER_HUB_REPO" ] && [ "$DOCKER_HUB_REPO" != "" ]; then
        echo -e "${GREEN}✅ Docker Hub repository configured: $DOCKER_HUB_REPO${NC}"
    else
        echo -e "${YELLOW}⚠️ Docker Hub repository not configured${NC}"
        echo -e "   ${BLUE}Run: ./manage-dev-env.sh setup-hub${NC}"
    fi
else
    echo -e "${RED}❌ Management script not found${NC}"
fi

echo -e "\n${BLUE}=== Configuration Files Check ===${NC}"

# Check required files
CONFIG_FILES=(
    "docker-compose.yml:Docker orchestration configuration"
    "Dockerfile:Container image definition"
    "startup.sh:Container startup script"
    "manage-dev-env.sh:Environment management script"
)

for file_info in "${CONFIG_FILES[@]}"; do
    IFS=':' read -r file desc <<< "$file_info"
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ $desc: $file${NC}"
        # Check executable permissions for shell scripts
        if [[ "$file" == *.sh ]]; then
            if [ -x "$file" ]; then
                echo -e "   ${GREEN}✅ Executable permissions correct${NC}"
            else
                echo -e "   ${YELLOW}⚠️ Missing executable permissions, fixing...${NC}"
                chmod +x "$file"
                echo -e "   ${GREEN}✅ Permissions fixed${NC}"
            fi
        fi
    else
        echo -e "${RED}❌ $desc missing: $file${NC}"
    fi
done

echo -e "\n${BLUE}=== Disk Space Check ===${NC}"

# Check available disk space
REQUIRED_SPACE_GB=10
AVAILABLE_SPACE=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')

if [ "$AVAILABLE_SPACE" -ge "$REQUIRED_SPACE_GB" ]; then
    echo -e "${GREEN}✅ Sufficient disk space: ${AVAILABLE_SPACE}GB available${NC}"
else
    echo -e "${YELLOW}⚠️ Disk space may be insufficient: only ${AVAILABLE_SPACE}GB available, recommend at least ${REQUIRED_SPACE_GB}GB${NC}"
fi

echo -e "\n${BLUE}=== Permissions Check ===${NC}"

# Check Docker permissions
if docker ps &>/dev/null; then
    echo -e "${GREEN}✅ Docker permissions normal${NC}"
else
    echo -e "${RED}❌ Docker permission issues${NC}"
    echo -e "   ${BLUE}Please ensure Docker Desktop is running${NC}"
fi

echo -e "\n${BLUE}=== Network Connectivity Check ===${NC}"

# Check network connectivity
check_requirement "Network connectivity (Docker Hub)" "curl -s https://hub.docker.com > /dev/null" "Check network connection"
check_requirement "Network connectivity (Go official site)" "curl -s https://go.dev > /dev/null" "Check network connection"
check_requirement "Network connectivity (Claude)" "curl -s https://claude.ai > /dev/null" "Check network connection"

echo -e "\n${BLUE}=== Performance Recommendations ===${NC}"

echo -e "${YELLOW}💡 Optimization suggestions:${NC}"
echo -e "1. Allocate at least 4GB memory in Docker Desktop settings"
echo -e "2. Enable file sharing optimization in Docker Desktop"
echo -e "3. Configure Docker Hub backup for data security"
echo -e "4. Set up scheduled backup tasks"
echo -e "5. Use SSD storage for better performance"

echo -e "\n${GREEN}🎉 Configuration validation completed!${NC}"
echo -e "${BLUE}If all checks pass, you can run:${NC}"
echo -e "  ${GREEN}./manage-dev-env.sh start${NC}"

---

# fix-config.sh - Automatic configuration fix script

#!/bin/bash

echo "🔧 Automatically fixing configuration issues..."

# Color definitions
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Fix script permissions
echo -e "${BLUE}📝 Fixing script permissions...${NC}"
chmod +x *.sh 2>/dev/null || true
echo -e "${GREEN}✅ Script permissions fixed${NC}"

# Create missing directories
echo -e "${BLUE}📁 Creating required directories...${NC}"
mkdir -p ~/.m2 ~/.gradle ~/go/pkg/mod ~/Library/Caches/go-build ~/.ivy2 ~/.cache/pip workspace
echo -e "${GREEN}✅ Directories created${NC}"

# Fix Git configuration (if missing)
if ! git config --global user.name &>/dev/null; then
    echo -e "${BLUE}⚙️ Setting default Git configuration...${NC}"
    git config --global user.name "Developer"
    git config --global user.email "dev@example.com"
    echo -e "${YELLOW}⚠️ Please update with real Git user information later${NC}"
    echo -e "   git config --global user.name \"Your Real Name\""
    echo -e "   git config --global user.email \"your.real.email@example.com\""
fi

# Check and start Docker Desktop
if ! docker ps &>/dev/null; then
    echo -e "${BLUE}🐳 Attempting to start Docker Desktop...${NC}"
    open -a Docker
    echo -e "${YELLOW}⏳ Please wait for Docker Desktop to start completely...${NC}"
    echo -e "   You can check status with: docker ps"
fi

# Create workspace directory if it doesn't exist
if [ ! -d "workspace" ]; then
    echo -e "${BLUE}📁 Creating workspace directory...${NC}"
    mkdir -p workspace
    echo -e "${GREEN}✅ Workspace directory created${NC}"
fi

# Check if Docker Hub login is needed
if ! docker info | grep -q Username; then
    echo -e "${YELLOW}🔐 Docker Hub login recommended for backup functionality${NC}"
    echo -e "   Run: docker login"
fi

echo -e "${GREEN}✅ Automatic fix completed!${NC}"
echo -e "${BLUE}Next steps:${NC}"
echo -e "1. Wait for Docker Desktop to fully start"
echo -e "2. Run: ./manage-dev-env.sh check-deps"
echo -e "3. Run: ./manage-dev-env.sh setup-hub (for backup)"
echo -e "4. Run: ./manage-dev-env.sh start"