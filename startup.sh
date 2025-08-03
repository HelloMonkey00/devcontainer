#!/bin/bash
# startup.sh - Container startup script

echo "🚀 Starting development environment..."

# Initialize Go module directories
mkdir -p /go/src /go/bin /go/pkg

# Set Git safe directory
git config --global --add safe.directory /workspace

# Start code-server (VS Code Web version)
echo "📝 Starting VS Code Server..."
code-server --bind-addr 0.0.0.0:8080 --auth none /workspace &

# Check Claude Code installation and configuration
echo "🤖 Checking Claude Code configuration..."
if command -v claude &> /dev/null; then
    echo "✅ Claude Code is installed"
    if [ ! -f ~/.config/claude/config.json ] && [ ! -f ~/.claude-code/config.json ]; then
        echo "⚠️ Claude Code requires API key configuration"
        echo "Please run the following command for configuration:"
        echo "  claude auth"
        echo "Or set environment variable:"
        echo "  export ANTHROPIC_API_KEY='your-api-key'"
    else
        echo "✅ Claude Code is configured"
    fi
else
    echo "⚠️ Claude Code is not properly installed"
    echo "Please install manually: curl -fsSL https://claude.ai/install.sh | bash"
fi

echo "✅ Development environment started!"
echo "🌐 VS Code Web interface: http://localhost:8080"
echo "📁 Working directory: /workspace"
echo "👤 Current user: $(whoami)"
echo ""
echo "Available development tools:"
echo "  - Java $(java -version 2>&1 | head -n 1)"
echo "  - Go $(go version)"
echo "  - Python $(python --version)"
echo "  - Maven $(mvn -version | head -n 1)"
echo "  - Gradle $(gradle --version | head -n 1)"
echo "  - Node.js $(node --version)"
echo "  - Claude Code $(claude --version 2>/dev/null || echo 'needs configuration')"

# Keep container running
tail -f /dev/null