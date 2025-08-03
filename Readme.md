# Docker Development Environment

A comprehensive Docker-based development environment for Java, Go, and Python development on macOS with Apple Silicon, featuring VS Code integration, Claude Code support, and Docker Hub backup capabilities.

## 🚀 Features

- **Multi-Language Support**: Java 17, Go 1.23, Python 3 with complete toolchains
- **Shared Dependencies**: Host machine dependency caching to save disk space
- **VS Code Integration**: Web-based VS Code Server accessible via browser
- **Claude Code Integration**: AI-powered coding assistant built-in
- **Docker Hub Backup**: Complete environment backup and restore via Docker Hub
- **Persistent Development**: Long-term environment with plugin and configuration persistence
- **SSH & Git Integration**: Seamless integration with host machine credentials

## 📋 Prerequisites

### System Requirements
- macOS with Apple Silicon (M1/M2/M3)
- Docker Desktop for Mac
- At least 4GB RAM allocated to Docker
- 10GB+ available disk space

### Installation
```bash
# Install Docker Desktop
brew install --cask docker

# Create required directories
mkdir -p ~/.m2 ~/.gradle ~/go/pkg/mod ~/Library/Caches/go-build ~/.ivy2 ~/.cache/pip

# Ensure Git and SSH are configured
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Set up Docker Hub account (for backup functionality)
docker login
```

## 🛠️ Quick Start

### 1. Clone and Setup
```bash
git clone <your-repo-url>
cd <repo-name>
chmod +x *.sh
```

### 2. Fix Configuration (if needed)
```bash
./quick-fix.sh
```

### 3. Validate Environment
```bash
./validate-config.sh
```

### 4. Start Development Environment
```bash
./manage-dev-env.sh start
```

### 5. Access Your Environment
- **VS Code Web Interface**: http://localhost:8080
- **Shell Access**: `./manage-dev-env.sh shell`

## 📁 Project Structure

```
docker-dev-environment/
├── docker-compose.yml      # Docker orchestration configuration
├── Dockerfile             # Container image definition
├── startup.sh             # Container startup script
├── manage-dev-env.sh      # Environment management tool
├── validate-config.sh     # Configuration validation script
├── quick-fix.sh           # Quick configuration fixes
└── workspace/             # Your development workspace
    ├── java-projects/
    ├── go-projects/
    └── python-projects/
```

## 🔧 Environment Management

### Basic Commands
```bash
# Start the environment
./manage-dev-env.sh start

# Stop the environment
./manage-dev-env.sh stop

# Restart the environment
./manage-dev-env.sh restart

# Enter the container shell
./manage-dev-env.sh shell

# View environment status
./manage-dev-env.sh status

# View container logs
./manage-dev-env.sh logs

# Check host dependencies
./manage-dev-env.sh check-deps
```

### Docker Hub Backup Setup
```bash
# Configure Docker Hub repository
./manage-dev-env.sh setup-hub

# Create backup
./manage-dev-env.sh backup

# List available backups
./manage-dev-env.sh list-backups

# Restore from backup
./manage-dev-env.sh restore
```

## 💾 Backup Strategy

### What Gets Backed Up
- **Docker Hub**: Complete environment image with all tools and configurations
- **Local Files**: Workspace code and VS Code settings
- **Shared Dependencies**: Automatically preserved via host machine directories

### Backup Process
1. Container state is committed to a timestamped Docker image
2. Image is pushed to your Docker Hub repository
3. Workspace files are archived locally
4. Old backups are automatically cleaned up (keeps last 3 locally)

### Restore Process
1. Pull the desired backup image from Docker Hub
2. Create temporary container configuration
3. Start environment from backup image
4. Restore workspace files if available

## 🔄 Persistent Data

### Container Volumes (Persistent)
- VS Code Server configuration and extensions
- Development tools settings and cache
- Container-specific configurations

### Host Machine Shared (Disk Space Saving)
- `~/.m2` - Maven dependency cache
- `~/.gradle` - Gradle dependency cache
- `~/go/pkg/mod` - Go module cache
- `~/Library/Caches/go-build` - Go build cache
- `~/.cache/pip` - Python package cache
- `~/.ssh` - SSH configuration (read-only)
- `~/.gitconfig` - Git configuration (read-only)

## 🛡️ Development Workflow

### Daily Development
1. Start environment: `./manage-dev-env.sh start`
2. Open VS Code: Navigate to http://localhost:8080
3. Work in `/workspace` directory
4. Use integrated terminal for build/run commands
5. Commit code to Git repositories
6. Regular backups: `./manage-dev-env.sh backup`

### Long-term Maintenance
- **Weekly**: Create backup snapshots
- **Monthly**: Clean up old Docker images
- **As needed**: Update base image with new tools

## 🔌 Tool Integration

### Claude Code Setup
After first startup, configure Claude Code:
```bash
./manage-dev-env.sh shell
claude auth  # Follow authentication prompts
```

### Available Development Tools
- **Java**: OpenJDK 17, Maven 3.9.6, Gradle 8.5
- **Go**: Go 1.23.5 with module support
- **Python**: Python 3.x with pip, common packages
- **Node.js**: Node.js 20.x for tooling
- **Claude Code**: AI coding assistant
- **VS Code Server**: Web-based IDE

### Port Mappings
- `8080` - VS Code Server
- `3000` - Node.js/React development
- `5000` - Python Flask applications
- `8000` - General web services

## 🚨 Troubleshooting

### Common Issues

#### Port Conflicts
```bash
# Check what's using the port
lsof -i :8080

# Change ports in docker-compose.yml if needed
```

#### Permission Issues
```bash
# Fix script permissions
chmod +x *.sh

# Check Docker permissions
docker ps
```

#### Configuration Problems
```bash
# Run validation
./validate-config.sh

# Auto-fix common issues
./quick-fix.sh
```

#### Claude Code Issues
```bash
# Reconfigure Claude Code
./manage-dev-env.sh shell
claude auth
```

### Performance Optimization
1. Increase Docker Desktop memory allocation (4GB+)
2. Enable Docker Desktop file sharing optimization
3. Use SSD storage for better I/O performance
4. Regular cleanup: `./manage-dev-env.sh clean`

## 📈 Customization

### Adding New Languages/Tools
Modify the `Dockerfile` to include additional tools:
```dockerfile
# Add Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Add database clients
RUN apt-get update && apt-get install -y postgresql-client
```

### Adding Database Services
Extend `docker-compose.yml`:
```yaml
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: devdb
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: devpass
    volumes:
      - postgres-data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
```

### Custom Environment Variables
Add to `docker-compose.yml`:
```yaml
environment:
  - YOUR_CUSTOM_VAR=value
  - API_KEY=${API_KEY}  # From host environment
```

## 🔐 Security Considerations

- SSH keys are mounted read-only
- Git configuration is mounted read-only
- Container runs as non-root user
- Docker Hub credentials should use access tokens
- Regular backup rotation prevents data loss

## 📝 Best Practices

1. **Regular Backups**: Create weekly snapshots
2. **Git Integration**: Commit important work to repositories
3. **Environment Updates**: Rebuild image monthly for security updates
4. **Resource Monitoring**: Monitor Docker resource usage
5. **Cleanup**: Regular cleanup of unused images and containers

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Test changes thoroughly
4. Submit a pull request with clear description

## 📄 License

[Add your license here]

## 🙋‍♂️ Support

- Create an issue for bugs or feature requests
- Check troubleshooting section for common problems
- Validate configuration with included scripts

---

**Happy Coding! 🎉**