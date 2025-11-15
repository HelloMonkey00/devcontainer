#!/bin/bash
# startup.sh - Container startup script

echo "🚀 Starting development environment..."

# Set Git safe directory
git config --global --add safe.directory /workspace 2>/dev/null || true

# Display environment information
echo "✅ Development environment started!"
echo "📁 Working directory: /workspace"
echo "👤 Current user: $(whoami)"
echo ""
echo "Available development tools:"
echo "  - Python $(python --version 2>&1)"
echo "  - Node.js $(node --version)"
echo "  - Claude Code $(claude --version 2>/dev/null || echo 'not configured')"
echo ""

# Check Claude Code configuration
if command -v claude &> /dev/null; then
    if [ ! -f ~/.config/claude/config.json ] && [ ! -f ~/.claude-code/config.json ]; then
        echo "⚠️ Claude Code requires API key configuration"
        echo "Please run: claude auth"
        echo "Or set: export ANTHROPIC_API_KEY='your-api-key'"
    else
        echo "✅ Claude Code is configured"
    fi
fi

# Keep container running
tail -f /dev/null
