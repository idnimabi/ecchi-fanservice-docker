# Ecchi Fanservice Anime List - Docker

将 [ecchi-fanservice-anime-list](https://github.com/ivon852/ecchi-fanservice-anime-list-website) 项目容器化部署的方案。

## 目录结构

```
ecchi-fanservice/
├── Dockerfile          # 多阶段构建：Hugo 构建 + Nginx 运行
├── docker-compose.yml  # 编排文件
├── nginx.conf          # Nginx 配置
├── scripts/
│   └── update-data.sh  # 定时更新数据脚本
└── .dockerignore
```

## 快速启动

```bash
docker compose up -d --build
```

访问 `http://localhost:8080`

## 自动更新数据

容器内部每天凌晨 **1:00 (Asia/Shanghai)** 自动从数据仓库拉取最新数据，重建静态网站。

## 架构说明

- **构建阶段**: 基于 `klakegg/hugo:ext-alpine`，克隆 website 仓库（含 Blowfish 主题子模块）和 data 仓库的 JSON 数据，执行 `hugo --gc --minify` 生成静态文件
- **运行阶段**: 基于 `nginx:alpine`，提供静态文件服务，内置 cron 定时刷新数据

## 端口映射

默认映射 `8080:80`，可在 `docker-compose.yml` 中修改。