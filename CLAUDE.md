<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

这是一个基于 PostgreSQL 17 的 Docker 镜像，专为中文应用开发优化，预装了丰富的扩展，包括中文分词、全文搜索、向量搜索、时间序列、地理空间等功能。

## 常用命令

### 构建和运行
```bash
# 构建镜像（多架构）
docker buildx build --platform linux/amd64,linux/arm64 -t eyeix/postgres-zh .

# 运行容器
docker run -d \
  --name postgres-zh \
  -e POSTGRES_DB=zh-app \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=your_password \
  -p 5432:5432 \
  eyeix/postgres-zh:v17

# 使用 Docker Compose
docker-compose up -d
```

### 测试验证
```bash
# 运行基础测试
docker run --name postgres-test \
  -e POSTGRES_PASSWORD=testpass \
  -d -p 5433:5432 \
  eyeix/postgres-zh:v17

# 检查扩展安装状态
docker exec postgres-test /usr/pgsql/bin/psql -U postgres -d postgres -c "\dx"

# 测试中文分词
docker exec postgres-test /usr/pgsql/bin/psql -U postgres -d postgres -c \
  "SELECT to_tsvector('zhparser_zh', '这是一个中文分词的测试');"

# 测试向量搜索
docker exec postgres-test /usr/pgsql/bin/psql -U postgres -d postgres -c \
  "SELECT embedding <-> '[0.1,0.2,0.3]' as distance FROM embeddings;"
```

### 扩展管理（使用 Pig）
```bash
# 列出已安装扩展
docker exec -it postgres-zh pig ext list

# 安装新扩展
docker exec -it postgres-zh pig ext install <extension_name> -y

# 更新扩展
docker exec -it postgres-zh pig ext update <extension_name> -y

# 搜索扩展
docker exec -it postgres-zh pig ext search <extension_name>
```

## 项目架构

### 核心文件结构
- `Dockerfile` - Docker 构建配置，定义了所有扩展的安装顺序
- `init-scripts/01-extensions.sql` - 数据库初始化脚本，启用所有扩展并配置中文分词
- `.github/workflows/docker-build.yml` - CI/CD 配置，自动构建并推送到 Docker Hub
- `README.md` - 项目文档，包含详细的使用说明和示例

### Pig 包管理器

项目使用 Pig 包管理器来管理 PostgreSQL 生态，这是核心特点：

1. **统一管理**：PostgreSQL 内核和所有扩展通过 Pig 统一安装
2. **多架构支持**：自动处理 AMD64 和 ARM64 架构
3. **依赖处理**：自动解析扩展间的依赖关系
4. **容错机制**：优雅处理安装失败

### 扩展安装顺序

Dockerfile 中的扩展安装严格按照依赖顺序：

1. **基础扩展**（无依赖）：ltree, pg_stat_statements, pg_jsonschema, pg_graphql, pgmq, btree_gist
2. **全文搜索基础**：pg_trgm, fuzzystrmatch, unaccent
3. **地理位置**：postgis
4. **时间序列**：timescaledb（必须先安装）
5. **AI/向量基础**：pgvector（必须先安装）
6. **AI/向量扩展**：smlar, vchord（依赖 vector）
7. **中文搜索**：pgroonga, zhparser
8. **分析扩展**：pg_analytics, pg_partman, pg_duckdb, tablefunc

### 双层扩展管理

1. **构建时安装**：在 Dockerfile 中使用 `pig ext install` 安装扩展
2. **运行时启用**：在 `init-scripts/01-extensions.sql` 中使用 `CREATE EXTENSION IF NOT EXISTS` 启用

这种设计确保了：
- 镜像构建时包含所有扩展文件
- 运行时容错处理，即使某些扩展不可用也不会导致容器启动失败

### 中文分词配置

项目特别配置了中文全文搜索：

```sql
-- 创建中文全文搜索配置
CREATE TEXT SEARCH CONFIGURATION zhparser_zh (PARSER = zhparser);
ALTER TEXT SEARCH CONFIGURATION zhparser_zh
    ADD MAPPING FOR n,v,a,i,e,l,j,t WITH simple;
```

支持中文词性：名词(n)、动词(v)、形容词(a)、习语(i)、叹词(e)、习用语(l)、简称(j)、时间词(t)

### 自动化 CI/CD

GitHub Actions 实现了：
- 多架构构建（AMD64 和 ARM64）
- 自动推送到 Docker Hub
- 智能触发（跳过文档更改）
- 缓存优化加速构建
- 自动标签管理

## 开发注意事项

### 修改扩展配置
1. 更新 Dockerfile 中的 `RUN pig ext install` 命令
2. 如需修改初始化逻辑，编辑 `init-scripts/01-extensions.sql`
3. 测试时注意扩展间的依赖关系

### 版本管理
- 主分支使用版本号标签（如 v17）
- 分支命名规范：`v{版本号}`
- Docker Hub 镜像标签格式：`eyeix/postgres-zh:v{版本号}`

### 性能优化
- 使用 Pig 的并行安装加速构建
- 合理组织 Docker 层以优化镜像大小
- 利用 GitHub Actions 缓存减少重复构建