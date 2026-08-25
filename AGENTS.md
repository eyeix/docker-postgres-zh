# AGENTS.md

本文件是 AI 代理在本项目的主入口。

## 项目概述

基于官方 `postgres:17` 镜像的中文适配 Docker 镜像，通过 Pig 包管理器预装中文分词、全文搜索、向量搜索、时间序列、地理空间扩展。发布为 `eyeix/postgres-zh`。

## 文档与记忆

技术治理信息集中在 `.agentdocs/`，先读索引再按需定位：

- `.agentdocs/index.md` - 文档索引与全局重要记忆，开始任务前必读
- `.agentdocs/architecture.md` - 架构与技术约束，改 `Dockerfile`、`init-scripts/`、CI 前必读
- `.agentdocs/permission-and-mounting.md` - 挂载权限方案与历史背景
- `.agentdocs/conventions.md` - 代码风格、Git 工作流、验证要求

用户向文档在仓库根目录：`README.md`、`EXTENSIONS.md`、`TESTING.md`、`troubleshooting/TROUBLESHOOTING.md`。

## 核心文件

- `Dockerfile` - 镜像构建，扩展安装顺序表达真实依赖
- `init-scripts/01-extensions.sql` - 启用扩展并配置中文分词
- `docker-compose.yml` - 部署示例
- `.github/workflows/docker-build.yml` - 多架构构建并推送 Docker Hub
- `CHANGELOG.md` - 由 GitHub Actions 自动生成，禁止手工或由代理写入

## 常用命令

构建与运行：

```bash
# 多架构构建
docker buildx build --platform linux/amd64,linux/arm64 -t eyeix/postgres-zh .

# 运行容器
docker run -d --name postgres-zh \
  -e POSTGRES_DB=zh-app \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=your_password \
  -p 5432:5432 \
  eyeix/postgres-zh:v17

# Docker Compose
docker-compose up -d
```

扩展管理（Pig）：

```bash
docker exec -it postgres-zh pig ext list
docker exec -it postgres-zh pig ext install <extension_name> -y
docker exec -it postgres-zh pig ext update <extension_name> -y
docker exec -it postgres-zh pig ext search <extension_name>
```

验证步骤见 `.agentdocs/conventions.md`。

## 关键约束

- 新增扩展必须同时改 `Dockerfile` 与 `init-scripts/01-extensions.sql`
- 不要新增自定义 entrypoint，权限由官方镜像 entrypoint 处理
- 锁定 PostgreSQL 17，双架构必须同时可构建
- 提交信息遵循 Conventional Commits，使用中文描述
