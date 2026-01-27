# Project Context

## Purpose
这是一个基于 PostgreSQL 17 的 Docker 镜像项目，专为中文应用开发优化。项目旨在提供开箱即用的中文 PostgreSQL 环境，预装丰富的扩展，支持中文分词、全文搜索、向量搜索、时间序列、地理空间等高级功能。目标是让开发者能够快速搭建和部署中文应用，无需手动配置复杂的环境和扩展。

## Tech Stack
- **核心技术**: PostgreSQL 17
- **包管理器**: Pig (PostgreSQL Package Manager)
- **Docker**: 多架构容器支持 (linux/amd64, linux/arm64)
- **CI/CD**: GitHub Actions
- **Docker Hub**: 镜像托管和分发
- **扩展生态**:
  - 中文处理: zhparser, pgroonga
  - 向量搜索: pgvector, smlar, vchord
  - 全文搜索: pg_trgm, unaccent
  - 地理空间: PostGIS
  - 时间序列: TimescaleDB
  - AI/分析: pg_graphql, pg_duckdb, pg_analytics
  - 其他: ltree, pg_stat_statements, pgmq, pg_partman

## Project Conventions

### Code Style
- **Dockerfile**: 使用多阶段构建，按依赖顺序安装扩展，每步创建清晰层
- **SQL 脚本**: 使用大写关键字，注释使用中文，遵循 PostgreSQL 标准格式
- **Shell 脚本**: 使用 bash，错误处理严谨，变量引用加引号
- **YAML 配置**: GitHub Actions 使用简洁结构，包含缓存和并行构建优化
- **文档**: Markdown 格式，中文编写，包含详细的使用说明和示例

### Architecture Patterns
- **双层扩展管理**:
  - 构建时安装: Dockerfile 中使用 Pig 安装扩展到镜像
  - 运行时启用: init-scripts 中使用 `CREATE EXTENSION IF NOT EXISTS` 启用
- **模块化设计**: 每个功能模块（中文分词、向量搜索等）独立配置，互不干扰
- **容错机制**: 即使某些扩展安装失败，容器也能正常启动
- **多架构支持**: 同时支持 AMD64 和 ARM64 架构

### Testing Strategy
- **基础测试**: 验证 PostgreSQL 启动和基本功能
- **扩展测试**: 使用 `docker exec` 检查每个扩展的可用性
- **功能测试**: 针对核心功能（中文分词、向量搜索等）进行验证
- **集成测试**: 使用 Docker Compose 验证完整部署流程
- **CI/CD 自动测试**: GitHub Actions 自动触发构建和基础测试

### Git Workflow
- **分支命名**: `v{版本号}`（如 v17, v16）
- **主分支**: 使用版本号标签（如 v17）
- **提交规范**: 遵循 Conventional Commits（如 `feat:`, `fix:`, `docs:`）
- **CI/CD 触发**: 自动构建多架构镜像，推送至 Docker Hub
- **文档同步**: 文档变更自动触发文档更新，跳过镜像构建

## Domain Context

### 中文全文搜索
- **zhparser 配置**: 支持中文词性分词（名词、动词、形容词、习语、叹词、习用语、简称、时间词）
- **pgroonga**: 使用日语全文搜索引擎，但对中文有良好支持
- **搜索配置**: 创建了 `zhparser_zh` 配置，支持多种中文词性的搜索映射

### 向量搜索生态
- **pgvector**: 核心向量扩展，支持 L2 距离、内积、余弦相似度
- **smlar**: 基于相似度的搜索，支持多种距离算法
- **vchord**: 高性能向量索引，适合大规模向量数据

### PostgreSQL 扩展依赖关系
- **TimescaleDB**: 必须在 pgvector 之前安装
- **pgvector**: 作为多个 AI 扩展的基础依赖
- **安装顺序**: 严格按照依赖关系排列，避免安装失败

### 中文应用开发考虑
- **字符编码**: 默认支持 UTF-8，完全兼容中文
- **时区配置**: 使用 UTC 时区，便于国际化应用
- **数据库设计**: 考虑中文文本的存储和索引优化

## Important Constraints
- **版本锁定**: 必须使用 PostgreSQL 17 作为基础版本
- **扩展兼容性**: 所有扩展必须与 PostgreSQL 17 兼容
- **多架构要求**: 同时支持 AMD64 和 ARM64 架构
- **镜像大小**: 优化镜像大小，避免不必要的依赖
- **安全性**: 仅使用官方和可信的扩展源
- **向后兼容**: 保持与现有部署的兼容性
- **构建时间**: 优化构建速度，使用 Pig 包管理器的并行安装能力

## External Dependencies
- **Docker**: 容器运行时环境
- **Pig**: PostgreSQL 包管理器，用于扩展管理
- **GitHub Actions**: CI/CD 自动化
- **Docker Hub**: 镜像托管服务
- **PostgreSQL 官方镜像**: 作为基础镜像
- **扩展社区**: 各个扩展的官方仓库和文档
- **GitHub Packages**: 备选的包管理（如果需要）
