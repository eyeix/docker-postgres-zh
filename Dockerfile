# 基于官方PostgreSQL 16镜像
FROM postgres:16

# 切换为root用户执行安装操作
USER root

# 安装依赖包
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    libpq-dev \
    postgresql-server-dev-16 \
    wget \
    unzip \
    cmake \
    ca-certificates \
    openssl \
    && rm -rf /var/lib/apt/lists/* \
    && update-ca-certificates

# 安装SCWS库和zhparser扩展（使用官方发布版本）
RUN wget -q -O - "http://www.xunsearch.com/scws/down/scws-1.2.3.tar.bz2" | tar xjf - && \
    wget -O zhparser.zip "https://github.com/amutu/zhparser/archive/master.zip" && \
    unzip zhparser.zip && \
    cd scws-1.2.3 && \
    ./configure && \
    make install && \
    ldconfig && \
    cd /zhparser-master && \
    SCWS_HOME=/usr/local make && make install && \
    rm -rf /scws-1.2.3 /zhparser-master /zhparser.zip

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
