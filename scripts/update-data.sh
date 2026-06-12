#!/bin/sh
# 定时更新数据脚本
# 用于在容器内每天凌晨 1:00 拉取最新数据并重建静态网站

set -e

echo "[$(date)] 开始更新数据..."

# 进入网站源码目录（构建阶段的工作目录为 /src，运行时我们将其打包到 /usr/share/nginx/html）
# 但我们需要 Hugo 源码来重新构建，所以在运行时容器中重建源码目录
# 使用之前构建时保留的源码副本
if [ -d "/src" ]; then
    cd /src

    # 拉取网站仓库最新代码
    echo "拉取网站仓库更新..."
    git pull origin main || true

    # 更新子模块（Blowfish 主题）
    git submodule update --init --recursive || true

    # 拉取数据仓库最新数据
    echo "拉取数据更新..."
    if [ -d "temp_data" ]; then
        cd temp_data
        git pull origin main || true
        cd ..
    else
        git clone --depth 1 https://github.com/ivon852/ecchi-fanservice-anime-list-data.git temp_data
    fi

    # 复制数据到 data 目录
    mkdir -p data
    cp -r temp_data/data/* data/ || true

    # 重建静态网站
    echo "重建静态网站..."
    hugo --gc --minify

    # 将构建产物复制到 Nginx 目录
    cp -r public/* /usr/share/nginx/html/ || true

    echo "[$(date)] 数据更新完成"
else
    echo "[$(date)] 错误: 找不到 /src 目录，无法更新数据"
    exit 1
fi