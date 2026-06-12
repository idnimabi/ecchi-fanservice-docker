# 第一阶段：使用 Hugo 构建静态网站
FROM klakegg/hugo:ext-alpine AS builder

# 设置工作目录
WORKDIR /src

# 克隆网站仓库（包含子模块）
RUN apk add --no-cache git && \
    git clone --recurse-submodules https://github.com/ivon852/ecchi-fanservice-anime-list-website.git .

# 克隆数据仓库到 data 目录
RUN git clone https://github.com/ivon852/ecchi-fanservice-anime-list-data.git temp_data && \
    mkdir -p data && \
    cp -r temp_data/data/* data/ && \
    rm -rf temp_data

# 构建静态网站
RUN hugo --gc --minify

# 第二阶段：使用 Nginx 提供静态文件服务，支持定时更新
FROM nginx:alpine

# 安装 git、Hugo、dcron（定时任务）
RUN apk add --no-cache git hugo dcron

# 复制 Hugo 源码（包含 .git 信息，用于后续更新）
COPY --from=builder /src /src

# 复制构建好的静态文件到 Nginx 目录
COPY --from=builder /src/public /usr/share/nginx/html

# 复制自定义 Nginx 配置
COPY nginx.conf /etc/nginx/conf.d/default.conf

# 复制定时更新脚本
COPY scripts/update-data.sh /usr/local/bin/update-data.sh
RUN chmod +x /usr/local/bin/update-data.sh

# 设置定时任务：每天凌晨 1:00 (Asia/Shanghai) 更新数据
# 持续更新 Git 仓库的远程引用
RUN mkdir -p /var/spool/cron/crontabs && \
    echo "0 1 * * * /usr/local/bin/update-data.sh" > /etc/crontabs/root

# 启动脚本：先运行一次更新，然后启动 crond 和 nginx
RUN printf '#!/bin/sh\n\
echo "[$(date)] 容器启动，执行首次数据更新..."\n\
/usr/local/bin/update-data.sh || true\n\
echo "[$(date)] 启动 crond 和 nginx..."\n\
crond -b -l 2\n\
nginx -g "daemon off;"' > /entrypoint.sh && \
    chmod +x /entrypoint.sh

# 暴露端口
EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]