# 开发约定与验证要求

## 代码风格

- **Dockerfile**：按功能分组，每组一条 `RUN`；注释说明分组用途与依赖前提
- **SQL**：关键字大写，注释中文，遵循 PostgreSQL 标准格式
- **Shell**：bash，变量引用加引号，错误处理明确
- **YAML**：结构简洁，保留缓存与并行构建配置
- **文档**：Markdown，中文撰写，附可直接运行的示例

## Git 工作流

- 提交信息遵循 Conventional Commits（`feat:`、`fix:`、`docs:`、`ci:` 等），使用中文描述
- 主分支 `main`
- 镜像标签格式 `eyeix/postgres-zh:v{版本号}`
- 纯文档变更可在 commit message 加 `[docs only]` 跳过镜像构建

## 验证要求

本项目无编程语言层面的 lint/test 框架，验证以镜像行为为准。变更 `Dockerfile` 或 `init-scripts/` 后必须完成：

1. **构建通过**（至少本机架构）
   ```bash
   docker buildx build --platform linux/amd64 -t postgres-zh:test .
   ```

2. **容器启动并完成初始化**
   ```bash
   docker run -d --name pg-test -e POSTGRES_PASSWORD=testpass -p 5433:5432 postgres-zh:test
   docker logs pg-test   # 确认初始化脚本无报错
   ```

3. **扩展加载检查**
   ```bash
   docker exec pg-test psql -U postgres -d postgres -c "\dx"
   ```

4. **中文分词回归**
   ```bash
   docker exec pg-test psql -U postgres -d postgres -c \
     "SELECT to_tsvector('zhparser_zh', '这是一个中文分词的测试');"
   ```

5. **清理**
   ```bash
   docker rm -f pg-test && docker rmi postgres-zh:test
   ```

新增扩展时，在 `TESTING.md` 中补充对应的验证片段。

注意：`psql` 路径取决于基础镜像布局。官方 `postgres:17` 镜像中 `psql` 在 `PATH` 内可直接调用；部分历史文档写作 `/usr/pgsql/bin/psql`（Pig 安装路径），执行失败时改用 `psql` 重试。

## 纯文档变更

仅改 Markdown 时无需构建验证，但需确认改动未与 `Dockerfile` 实际行为矛盾。
