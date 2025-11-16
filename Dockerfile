# 使用包含Node.js和Python的基础镜像
FROM nikolaik/python-nodejs:python3.11-nodejs20

# 设置工作目录
WORKDIR /app

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    ca-certificates \
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libatspi2.0-0 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libgbm1 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libwayland-client0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxkbcommon0 \
    libxrandr2 \
    xdg-utils \
    libu2f-udev \
    libvulkan1 \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# 复制cursorlearn2api项目文件
COPY package*.json ./
COPY server.js ./
COPY src/ ./src/
COPY .env.example ./.env.example

# 安装Node.js依赖
RUN npm install && \
    npx playwright install chromium && \
    npx playwright install-deps chromium

# 复制Toolify项目文件
COPY Toolify-main/requirements.txt ./toolify/requirements.txt
COPY Toolify-main/main.py ./toolify/main.py
COPY Toolify-main/config_loader.py ./toolify/config_loader.py
COPY Toolify-main/config.example.yaml ./toolify/config.yaml

# 安装Python依赖
RUN pip install --no-cache-dir -r ./toolify/requirements.txt

# 创建supervisord配置文件
RUN mkdir -p /var/log/supervisor

# 创建启动脚本（使用简单 printf，兼容性更好）
RUN printf '%s\n' \
  '#!/bin/bash' \
  'set -e' \
  '' \
  '# 启动cursorlearn2api (Node.js服务)' \
  'cd /app' \
  'export PORT=30011' \
  'node server.js > /var/log/supervisor/cursorlearn2api.log 2>&1 &' \
  '' \
  '# 等待cursorlearn2api启动' \
  'sleep 5' \
  '' \
  '# 启动Toolify (Python服务)' \
  'cd /app/toolify' \
  'python main.py > /var/log/supervisor/toolify.log 2>&1 &' \
  '' \
  '# 保持容器运行' \
  'tail -f /var/log/supervisor/*.log' \
  > /app/start.sh \
  && chmod +x /app/start.sh

# 暴露端口
# 30011: cursorlearn2api服务端口
# 8000: Toolify服务端口
EXPOSE 30011 8000

# 设置环境变量
ENV PORT=30011
ENV NODE_ENV=production

# 启动服务
# 通过 bash 显式执行脚本，可以规避 Windows CRLF 行尾导致的 shebang 解析问题
CMD ["bash", "/app/start.sh"]