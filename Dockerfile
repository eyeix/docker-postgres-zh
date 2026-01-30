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
    locales \
    && rm -rf /var/lib/apt/lists/*

# 配置 locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    sed -i '/zh_CN.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen en_US.UTF-8 zh_CN.UTF-8 && \
    update-locale LANG=en_US.UTF-8

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

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

# 确保 postgres 用户存在且 UID/GID 正确
# 策略：删除现有的 postgres 用户/组，然后重新创建为 999:999
RUN set -ex; \
    # 检查是否存在 UID 999 或 GID 999 的冲突
    existing_uid_user=$(getent passwd 999 | cut -d: -f1 || echo ""); \
    existing_gid_group=$(getent group 999 | cut -d: -f1 || echo ""); \
    \
    # 如果 postgres 用户存在，删除它
    if id postgres >/dev/null 2>&1; then \
        echo "删除现有的 postgres 用户"; \
        userdel postgres 2>/dev/null || true; \
    fi; \
    \
    # 如果 postgres 组存在，删除它
    if getent group postgres >/dev/null 2>&1; then \
        echo "删除现有的 postgres 组"; \
        groupdel postgres 2>/dev/null || true; \
    fi; \
    \
    # 如果 GID 999 被其他组占用，删除或修改它
    if [ -n "$existing_gid_group" ] && [ "$existing_gid_group" != "postgres" ]; then \
        echo "GID 999 被组 $existing_gid_group 占用，修改为 1999"; \
        groupmod -g 1999 "$existing_gid_group" 2>/dev/null || groupdel "$existing_gid_group" 2>/dev/null || true; \
    fi; \
    \
    # 如果 UID 999 被其他用户占用，删除或修改它
    if [ -n "$existing_uid_user" ] && [ "$existing_uid_user" != "postgres" ]; then \
        echo "UID 999 被用户 $existing_uid_user 占用，修改为 1999"; \
        usermod -u 1999 "$existing_uid_user" 2>/dev/null || userdel "$existing_uid_user" 2>/dev/null || true; \
    fi; \
    \
    # 创建 postgres 组和用户
    groupadd -r postgres --gid=999; \
    useradd -r -g postgres --uid=999 --home-dir=/var/lib/postgresql --shell=/bin/bash postgres; \
    \
    # 验证最终结果
    echo "postgres 用户配置: UID=$(id -u postgres) GID=$(id -g postgres)"

# 创建 PostgreSQL 数据目录和运行时目录
RUN mkdir -p /var/lib/postgresql/data /var/run/postgresql && \
    chown -R postgres:postgres /var/lib/postgresql /var/run/postgresql && \
    chmod 2775 /var/run/postgresql

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
