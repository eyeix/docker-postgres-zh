# 基于 Ubuntu 基础镜像
FROM ubuntu:24.04

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV POSTGRES_VERSION=17

# 安装基础依赖包
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    wget \
    sudo \
    systemd \
    gosu \
    && rm -rf /var/lib/apt/lists/*

# 安装 Pig 包管理器
RUN curl -fsSL https://repo.pigsty.io/pig | bash

# 配置 Pig 仓库（分别添加仓库以避免冲突）
RUN yes | pig repo add pgsql -u

# 使用 Pig 安装 PostgreSQL 17 内核
RUN pig ext install pg17 -y

# 创建 /usr/pgsql 软链接，并写入 /etc/profile.d/pgsql.sh
RUN pig ext link 17
# 立即生效
RUN . /etc/profile.d/pgsql.sh

# 检查 postgres 用户是否存在，如果不存在则创建
RUN if ! id postgres >/dev/null 2>&1; then \
        groupadd -r postgres --gid=999 && useradd -r -g postgres --uid=999 postgres; \
    fi

# 创建 PostgreSQL 数据目录
RUN mkdir -p /var/lib/postgresql/data && chown -R postgres:postgres /var/lib/postgresql

# ===========================================
# 安装 PostgreSQL 内置扩展包
# ===========================================
# 安装 postgresql-contrib 包（包含内置扩展）
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-contrib \
    postgresql-17-contrib \
    && rm -rf /var/lib/apt/lists/* || echo "postgresql-contrib not available for this architecture"

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
RUN pig ext install pg_analytics pg_partman pg_duckdb tablefunc -y


# 复制初始化脚本到容器中
COPY init-scripts/ /docker-entrypoint-initdb.d/

# 确保初始化脚本权限正确
RUN chmod -R 755 /docker-entrypoint-initdb.d/ && \
    chown -R postgres:postgres /docker-entrypoint-initdb.d/

# 设置环境变量
ENV PGDATA=/var/lib/postgresql/data
ENV POSTGRES_USER=postgres
ENV POSTGRES_DB=postgres

# 暴露端口
EXPOSE 5432


# ===========================================
# 复制并设置 PostgreSQL 入口脚本
# ===========================================
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# ===========================================
# 设置启动命令
# ===========================================
# 注意：容器以 root 用户运行，启动脚本使用 gosu 切换到 postgres 用户
# 这样可以修复挂载目录的权限问题
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
