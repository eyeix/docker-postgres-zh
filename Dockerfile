# 基于官方PostgreSQL 16镜像
FROM postgres:16

# 切换为root用户执行安装操作
USER root

# 安装依赖包
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    bzip2 \
    ca-certificates \
    curl \
    gcc \
    libc6-dev \
    make \
    wget \
    unzip \
    cmake \
    openssl \
    clang \
    && rm -rf /var/lib/apt/lists/* \
    && update-ca-certificates

# 安装 PostgreSQL 开发包（容错安装）
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev \
    && (apt-get install -y postgresql-server-dev-16 || \
        apt-get install -y postgresql-server-dev-all || \
        apt-get install -y postgresql-server-dev || \
        echo "PostgreSQL server dev packages not available for this architecture") \
    && rm -rf /var/lib/apt/lists/*

# 验证 PostgreSQL 开发包是否安装成功
RUN if [ ! -f "/usr/include/postgresql/16/server/postgres.h" ]; then \
        echo "PostgreSQL headers not found, trying alternative installation..."; \
        apt-get update && apt-get install -y --no-install-recommends \
        postgresql-server-dev-16 || \
        echo "Failed to install PostgreSQL development headers"; \
    fi

# 安装SCWS库和zhparser扩展（使用官方发布版本）
RUN wget -q -O - "http://www.xunsearch.com/scws/down/scws-1.2.3.tar.bz2" | tar xjf - && \
    ZHPARSER_URL="https://github.com/amutu/zhparser/archive/master.tar.gz" && \
    curl -sSkLf "${ZHPARSER_URL}" | tar xzf - && \
    cd scws-1.2.3 && \
    ./configure && \
    make -j$(nproc) install V=0 && \
    ldconfig && \
    cd /zhparser-master && \
    # 检查 PostgreSQL 头文件是否存在
    if [ -f "/usr/include/postgresql/16/server/postgres.h" ]; then \
        echo "PostgreSQL headers found, proceeding with zhparser compilation..."; \
        make -j$(nproc) install; \
    else \
        echo "PostgreSQL headers not found, skipping zhparser compilation..."; \
        echo "zhparser will not be available in this build"; \
    fi && \
    rm -rf /scws-1.2.3 /zhparser-master

# 注意：pg_jieba 已移除，因为 zhparser 已经提供了完整的中文分词功能
# 如果需要结巴分词功能，可以单独安装 pg_jieba 扩展

# 安装其他常用扩展包
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-contrib \
    && rm -rf /var/lib/apt/lists/*

# 复制初始化脚本到容器中
COPY init-scripts/ /docker-entrypoint-initdb.d/

# 确保初始化脚本权限正确
RUN chmod -R 755 /docker-entrypoint-initdb.d/ && \
    chown -R postgres:postgres /docker-entrypoint-initdb.d/

# 切换回postgres用户
USER postgres
