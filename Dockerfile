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
RUN pig ext install hstore ltree -y

# 2. 基础功能扩展（无依赖）
RUN pig ext install pg_stat_statements pg_auditor -y

# 3. JSON 和 GraphQL 扩展（无依赖）
RUN pig ext install pg_jsonschema pg_graphql -y

# 4. 消息队列扩展（无依赖）
RUN pig ext install pgmq -y

# 5. 索引扩展（无依赖）
RUN pig ext install btree_gist -y

# 6. 全文搜索基础扩展（无依赖）
RUN pig ext install pg_trgm pg_bigm fuzzystrmatch unaccent -y

# 7. 地理位置基础扩展（ip4r 必须先安装）
RUN pig ext install ip4r -y

# 8. 地理位置扩展（依赖 ip4r）
RUN pig ext install postgis geoip -y

# 9. 时间序列扩展（timescaledb 必须先安装）
RUN pig ext install timescaledb -y

# 10. AI/向量基础扩展（vector 必须先安装）
RUN pig ext install pgvector -y

# 11. AI/向量相似度扩展（依赖 vector）
RUN pig ext install pg_similarity smlar -y

# 12. AI/向量高级扩展（依赖 vector）
RUN pig ext install vchord -y

# 13. 高级全文搜索扩展（无依赖）
RUN pig ext install pgroonga pg_search pg_tokenizer zhparser -y

# 14. 分析能力扩展（无依赖）
RUN pig ext install pg_analytics pg_partman pg_duckdb citus tablefunc -y


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
# 创建 PostgreSQL 入口脚本
# ===========================================
# 创建启动脚本
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# ===========================================\n\
# PostgreSQL 中文适配镜像启动脚本\n\
# ===========================================\n\
\n\
# 设置默认值（如果未提供）\n\
if [ -z "$POSTGRES_USER" ]; then\n\
    export POSTGRES_USER=postgres\n\
fi\n\
if [ -z "$POSTGRES_PASSWORD" ]; then\n\
    export POSTGRES_PASSWORD=postgres\n\
fi\n\
if [ -z "$POSTGRES_DB" ]; then\n\
    export POSTGRES_DB=postgres\n\
fi\n\
\n\
# ===========================================\n\
# 数据库初始化（仅在首次启动时执行）\n\
# ===========================================\n\
if [ ! -s "$PGDATA/PG_VERSION" ]; then\n\
    echo "=== 初始化 PostgreSQL 数据库 ==="\n\
    /usr/pgsql/bin/initdb\n\
    \n\
    echo "=== 配置 PostgreSQL 参数 ==="\n\
    # 配置网络访问\n\
    echo "host all all 0.0.0.0/0 md5" >> $PGDATA/pg_hba.conf\n\
    echo "listen_addresses = '\''*'\''" >> $PGDATA/postgresql.conf\n\
    \n\
    # 配置预加载扩展\n\
    echo "shared_preload_libraries = '\''timescaledb,citus,pg_search,pg_tokenizer,pg_duckdb,vchord'\''" >> $PGDATA/postgresql.conf\n\
    \n\
    echo "=== 启动 PostgreSQL 进行初始化 ==="\n\
    # 启动 PostgreSQL 进行初始化\n\
    /usr/pgsql/bin/postgres &\n\
    sleep 5\n\
    \n\
    echo "=== 创建用户和数据库 ==="\n\
    # 如果用户不是默认的 postgres，创建新用户\n\
    if [ "$POSTGRES_USER" != "postgres" ]; then\n\
        /usr/pgsql/bin/psql -c "CREATE USER $POSTGRES_USER WITH SUPERUSER PASSWORD '\''$POSTGRES_PASSWORD'\'';"\n\
    else\n\
        /usr/pgsql/bin/psql -c "ALTER USER postgres PASSWORD '\''$POSTGRES_PASSWORD'\'';"\n\
    fi\n\
    \n\
    # 创建指定的数据库\n\
    if [ "$POSTGRES_DB" != "postgres" ]; then\n\
        /usr/pgsql/bin/createdb -U postgres -O $POSTGRES_USER "$POSTGRES_DB"\n\
    fi\n\
    \n\
    echo "=== 执行扩展初始化脚本 ==="\n\
    # 执行初始化脚本\n\
    for f in /docker-entrypoint-initdb.d/*; do\n\
        case "$f" in\n\
            *.sh)     echo "$0: running $f"; . "$f" ;;\n\
            *.sql)    echo "$0: running $f"; /usr/pgsql/bin/psql -U postgres -d "$POSTGRES_DB" -f "$f" ;;\n\
            *.sql.gz) echo "$0: running $f"; gunzip -c "$f" | /usr/pgsql/bin/psql -U postgres -d "$POSTGRES_DB" ;;\n\
            *)        echo "$0: ignoring $f" ;;\n\
        esac\n\
    done\n\
    \n\
    echo "=== 完成初始化，停止临时 PostgreSQL ==="\n\
    kill %1\n\
    wait\n\
fi\n\
\n\
echo "=== 启动 PostgreSQL 服务 ==="\n\
# 启动 PostgreSQL\n\
exec /usr/pgsql/bin/postgres\n\
' > /usr/local/bin/docker-entrypoint.sh && chmod +x /usr/local/bin/docker-entrypoint.sh

# 不需要安装额外的包，直接使用系统自带的 su 命令

# 切换回postgres用户
USER postgres

# 设置启动命令
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
