# 基于官方 PostgreSQL 17 镜像
FROM postgres:17

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive

# 安装基础依赖包
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# 配置中文 locale
RUN sed -i '/zh_CN.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen zh_CN.UTF-8

# 安装 Pig 包管理器
RUN curl -fsSL https://repo.pigsty.io/pig | bash

# 移除官方的 PGDG 配置以避免冲突
RUN rm -f /etc/apt/sources.list.d/pgdg.list

# 配置 Pig 仓库并更新
RUN pig repo add pgsql && apt-get update

# ===========================================
# PostgreSQL 扩展安装（按功能分类和依赖顺序）
# ===========================================

# 1. 基础数据类型扩展（无依赖）
RUN pig ext install ltree -y

# 2. 基础功能扩展（无依赖）
RUN pig ext install pg_stat_statements -y

# 3. JSON 和 GraphQL 扩展（无依赖）
RUN pig ext install pg_jsonschema pg_graphql -y

# 4. 消息队列扩展（无依赖）
RUN pig ext install pgmq -y

# 5. 索引扩展（无依赖）
RUN pig ext install btree_gist -y

# 6. 全文搜索基础扩展（无依赖）
RUN pig ext install pg_trgm fuzzystrmatch unaccent -y

# 7. 地理位置扩展（无依赖）
RUN pig ext install postgis -y

# 8. 时间序列扩展（timescaledb 必须先安装）
RUN pig ext install timescaledb -y

# 9. AI/向量基础扩展（vector 必须先安装）
RUN pig ext install pgvector -y

# 10. AI/向量相似度扩展（依赖 vector）
RUN pig ext install smlar -y

# 11. AI/向量高级扩展（依赖 vector）
RUN pig ext install vchord -y

# 12. 高级全文搜索扩展（无依赖）
RUN pig ext install pgroonga zhparser -y

# 13. 分析能力扩展（无依赖）
# 注意：pg_analytics 在 Pigsty 仓库中不可用，已移除
RUN pig ext install pg_partman tablefunc -y

# 复制初始化脚本到容器中
COPY init-scripts/ /docker-entrypoint-initdb.d/

# 确保初始化脚本权限正确
RUN chmod -R 755 /docker-entrypoint-initdb.d/

# 注意：使用官方镜像的 entrypoint，已经正确处理了所有权限问题
# 不需要自定义 entrypoint 脚本
