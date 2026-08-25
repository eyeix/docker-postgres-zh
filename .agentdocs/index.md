# 文档索引

本目录仅面向 AI 代理，不含人类向说明。用户向文档在仓库根目录（`README.md`、`EXTENSIONS.md`、`TESTING.md`、`troubleshooting/TROUBLESHOOTING.md`）。

## 技术文档

`architecture.md` - 架构、技术栈、双层扩展管理、扩展安装顺序、CI/CD 与硬约束。修改 `Dockerfile`、`init-scripts/`、CI 配置前必读。
`permission-and-mounting.md` - 挂载权限方案与历史背景、编码约束。涉及数据目录挂载、entrypoint、权限排查时必读。
`conventions.md` - 代码风格、Git 工作流、镜像变更的验证要求。提交代码前必读。

## 当前任务文档

无。

## 全局重要记忆

- **不要新增自定义 entrypoint**：镜像完全依赖官方 `postgres:17` entrypoint 处理权限，早期自定义 `docker-entrypoint.sh` 方案已废弃。详见 `permission-and-mounting.md`。
- **新增扩展必须改两处**：`Dockerfile` 的 `pig ext install` 与 `init-scripts/01-extensions.sql` 的 `CREATE EXTENSION IF NOT EXISTS`，缺一不可。
- **扩展安装顺序表达真实依赖**：`pgvector` 必须先于 `smlar`、`vchord`，不可随意重排 `Dockerfile` 中的 `RUN` 顺序。
- **`CHANGELOG.md` 由 GitHub Actions 生成**，禁止手工或由代理写入。
- **`pg_analytics` 与 `pg_duckdb` 在 Pigsty 仓库不可用**，已从 `Dockerfile` 移除；文档中若仍提及属历史残留。
- **代理入口是 `AGENTS.md`**，`CLAUDE.md` 仅作为 Claude 侧指针，内容不重复。
