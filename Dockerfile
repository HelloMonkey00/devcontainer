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

# Install Java (OpenJDK 17)
RUN apt-get update && apt-get install -y openjdk-17-jdk \
    && rm -rf /var/lib/apt/lists/*

# Set Java environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH=$PATH:$JAVA_HOME/bin

# Install Maven
RUN wget https://archive.apache.org/dist/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz \
    && tar xzf apache-maven-3.9.6-bin.tar.gz -C /opt \
    && ln -s /opt/apache-maven-3.9.6 /opt/maven \
    && rm apache-maven-3.9.6-bin.tar.gz

ENV MAVEN_HOME=/opt/maven
ENV PATH=$PATH:$MAVEN_HOME/bin

# Install Gradle
RUN wget https://services.gradle.org/distributions/gradle-8.5-bin.zip \
    && unzip gradle-8.5-bin.zip -d /opt \
    && ln -s /opt/gradle-8.5 /opt/gradle \
    && rm gradle-8.5-bin.zip

ENV GRADLE_HOME=/opt/gradle
ENV PATH=$PATH:$GRADLE_HOME/bin

# Install Go 1.23.5 (latest stable version)
RUN wget https://go.dev/dl/go1.23.5.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go1.23.5.linux-amd64.tar.gz \
    && rm go1.23.5.linux-amd64.tar.gz

ENV PATH=$PATH:/usr/local/go/bin
ENV GOPATH=/go
ENV GOPROXY=https://goproxy.cn,direct

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
# RUN npm install -g @anthropic-ai/claude-code

# Install VS Code Server (for Remote Development)
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Set user permissions and working directory
RUN useradd -m -s /bin/bash developer \
    && usermod -aG sudo developer \
    && echo "developer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && mkdir -p /workspace \
    && chown -R developer:developer /workspace

# Copy startup script
COPY startup.sh /startup.sh
RUN chmod +x /startup.sh

# Switch to developer user
USER developer
WORKDIR /workspace

# Expose VS Code Server port
EXPOSE 8080

CMD ["/startup.sh"]