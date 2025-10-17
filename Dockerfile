FROM mcr.microsoft.com/playwright:v1.48.0-jammy

WORKDIR /app

# 复制依赖文件
COPY package*.json ./

# 安装依赖
RUN npm install

# 复制应用代码
COPY . .

# 暴露端口
EXPOSE 30011

# 启动应用
CMD ["npm", "start"]