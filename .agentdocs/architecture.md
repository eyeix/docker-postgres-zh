# 架构与技术约束

修改 `Dockerfile`、`init-scripts/`、CI 配置前必读。

## 项目定位

基于官方 `postgres:17` 镜像的中文适配发行版，通过 Pig 包管理器预装中文分词、全文搜索、向量搜索、时间序列、地理空间扩展。发布为 `eyeix/postgres-zh`。

## 技术栈

- 基础镜像：`postgres:17`（官方）
- 扩展管理：Pig（Pigsty 生态包管理器）
- 架构：`linux/amd64` + `linux/arm64` 双架构
- CI/CD：GitHub Actions → Docker Hub

## 双层扩展管理

这是项目的核心模式，两层缺一不可：

1. **构建时安装**：`Dockerfile` 中 `pig ext install <ext> -y`，把扩展的 so/sql 文件装进镜像
2. **运行时启用**：`init-scripts/01-extensions.sql` 中 `CREATE EXTENSION IF NOT EXISTS`，在数据库里创建扩展

`IF NOT EXISTS` 是容错设计：某个扩展不可用时容器仍能正常启动，不会因单个扩展失败而中断初始化。

新增扩展必须同时改这两处。

## 扩展安装顺序约束

`Dockerfile` 中的 `RUN pig ext install` 顺序表达真实依赖，不可随意重排：

1. 无依赖基础层：`ltree`、`pg_stat_statements`、`pg_jsonschema`、`pg_graphql`、`pgmq`、`btree_gist`
2. 全文搜索基础：`pg_trgm`、`fuzzystrmatch`、`unaccent`
3. 地理空间：`postgis`
4. 时间序列：`timescaledb`
5. 向量基础：`pgvector` —— 必须先于依赖它的扩展
6. 依赖 `vector` 的扩展：`smlar`、`vchord`
7. 中文搜索：`pgroonga`、`zhparser`
8. 分析与工具：`pg_partman`、`tablefunc`

已知不可用：`pg_analytics`、`pg_duckdb` 在 Pigsty 仓库中缺失，已从 `Dockerfile` 移除。若文档中仍有提及，视为待清理的历史残留。

## 构建期注意事项

- 安装 Pig 后需 `rm -f /etc/apt/sources.list.d/pgdg.list`，否则官方 PGDG 源与 Pig 源冲突
- 每个功能分组单独一条 `RUN`，便于层缓存复用与定位失败扩展
- `zh_CN.UTF-8` locale 在构建期通过 `locale-gen` 生成

## 中文全文搜索配置

`init-scripts/01-extensions.sql` 创建 `zhparser_zh` 搜索配置：

```sql
CREATE TEXT SEARCH CONFIGURATION zhparser_zh (PARSER = zhparser);
ALTER TEXT SEARCH CONFIGURATION zhparser_zh
    ADD MAPPING FOR n,v,a,i,e,l,j,t WITH simple;
```

映射词性：名词 n、动词 v、形容词 a、习语 i、叹词 e、习用语 l、简称 j、时间词 t。

## CI/CD

`.github/workflows/docker-build.yml`：

- 触发：push 到 `main`、`v*` tag、PR
- 跳过：`paths-ignore` 排除 `*.md` 与 `docs/**`；commit message 含 `[skip ci]`、`[no build]`、`[docs only]` 也跳过
- 标签策略：`type=ref,event=tag` + `type=sha,format=short`
- 缓存：`type=gha`，`mode=max`

## 硬约束

- 锁定 PostgreSQL 17，所有扩展必须与 17 兼容
- 双架构必须同时可构建，不接受单架构方案
- 仅使用官方与可信扩展源
- 保持与现有部署的向后兼容（镜像名、数据目录、环境变量语义不变）
- `CHANGELOG.md` 由 GitHub Actions 自动生成，禁止手工或由代理写入
