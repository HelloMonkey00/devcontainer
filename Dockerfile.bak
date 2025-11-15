FROM ubuntu:22.04

# Set non-interactive mode
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

# Update system and install basic tools
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    vim \
    nano \
    unzip \
    build-essential \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    apt-transport-https \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js (for development tools)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Install Python and pip
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Create Python symbolic link
RUN ln -s /usr/bin/python3 /usr/bin/python

# Install common Python packages
RUN pip3 install --no-cache-dir \
    requests \
    numpy \
    pandas \
    flask \
    fastapi \
    uvicorn \
    pytest \
    black \
    flake8

# Install Claude Code (correct installation method)
# Note: Claude Code requires manual API key configuration after container startup
RUN curl -fsSL https://claude.ai/install.sh | bash \
    || echo "Claude Code installation may require manual configuration, please run setup after container startup"

# Alternative installation method: via npm (if needed)
RUN npm install -g @anthropic-ai/claude-code

# Install VS Code Server (for Remote Development)
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Set working directory
RUN mkdir -p /workspace
WORKDIR /workspace

# Copy startup script
COPY startup.sh /startup.sh
RUN chmod +x /startup.sh

# Expose VS Code Server port
EXPOSE 36000

# Run as root user (default, no USER command needed)
CMD ["/startup.sh"]