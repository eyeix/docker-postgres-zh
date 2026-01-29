#!/bin/bash
set -e

# ===========================================
# PostgreSQL 中文适配镜像启动脚本
# ===========================================

# 设置默认值（如果未提供）
if [ -z "$POSTGRES_USER" ]; then
    export POSTGRES_USER=postgres
fi
if [ -z "$POSTGRES_PASSWORD" ]; then
    export POSTGRES_PASSWORD=postgres
fi
if [ -z "$POSTGRES_DB" ]; then
    export POSTGRES_DB=postgres
fi

# ===========================================
# 智能权限适配（用于挂载场景）
# ===========================================
# 如果数据目录已存在，动态调整 postgres 用户的 UID/GID 以匹配目录所有者
if [ -d "$PGDATA" ]; then
    # 获取数据目录的所有者 UID 和 GID
    dir_uid=$(stat -c "%u" "$PGDATA" 2>/dev/null || echo "999")
    dir_gid=$(stat -c "%g" "$PGDATA" 2>/dev/null || echo "999")

    # 获取当前 postgres 用户的 UID 和 GID
    current_uid=$(id -u postgres 2>/dev/null || echo "999")
    current_gid=$(id -g postgres 2>/dev/null || echo "999")

    # 如果目录所有者与 postgres 用户不匹配，调整 postgres 用户的 UID/GID
    if [ "$dir_uid" != "$current_uid" ] || [ "$dir_gid" != "$current_gid" ]; then
        echo "=== 检测到数据目录所有者: $dir_uid:$dir_gid ==="
        echo "=== 调整 postgres 用户 UID/GID 以匹配数据目录 ==="

        # 修改 postgres 用户的 GID
        if [ "$dir_gid" != "$current_gid" ]; then
            groupmod -g "$dir_gid" postgres 2>/dev/null || echo "警告：无法修改组 GID"
        fi

        # 修改 postgres 用户的 UID
        if [ "$dir_uid" != "$current_uid" ]; then
            usermod -u "$dir_uid" postgres 2>/dev/null || echo "警告：无法修改用户 UID"
        fi

        # 修复容器内其他目录的权限
        chown -R postgres:postgres /var/lib/postgresql /docker-entrypoint-initdb.d 2>/dev/null || true

        echo "=== 权限适配完成：postgres 用户现在是 $(id -u postgres):$(id -g postgres) ==="
    else
        echo "=== 数据目录权限正常: $dir_uid:$dir_gid ==="
    fi
else
    # 如果数据目录不存在，创建它
    echo "=== 创建数据目录 $PGDATA ==="
    mkdir -p "$PGDATA"
    chown -R postgres:postgres "$PGDATA"
fi

# ===========================================
# 数据库初始化（仅在首次启动时执行）
# ===========================================
if [ ! -s "$PGDATA/PG_VERSION" ]; then
    echo "=== 初始化 PostgreSQL 数据库 ==="
    gosu postgres /usr/pgsql/bin/initdb --encoding=UTF8 --locale=en_US.UTF-8

    echo "=== 配置 PostgreSQL 参数 ==="
    # 配置网络访问
    echo "host all all 0.0.0.0/0 md5" >> $PGDATA/pg_hba.conf
    echo "listen_addresses = '*'" >> $PGDATA/postgresql.conf

    # 配置预加载扩展
    echo "shared_preload_libraries = 'timescaledb,pg_duckdb,vchord'" >> $PGDATA/postgresql.conf

    echo "=== 启动 PostgreSQL 进行初始化 ==="
    # 启动 PostgreSQL 进行初始化
    gosu postgres /usr/pgsql/bin/postgres &
    sleep 5

    echo "=== 创建用户和数据库 ==="
    # 如果用户不是默认的 postgres，创建新用户
    if [ "$POSTGRES_USER" != "postgres" ]; then
        gosu postgres /usr/pgsql/bin/psql -c "CREATE USER $POSTGRES_USER WITH SUPERUSER PASSWORD '$POSTGRES_PASSWORD';"
    else
        gosu postgres /usr/pgsql/bin/psql -c "ALTER USER postgres PASSWORD '$POSTGRES_PASSWORD';"
    fi

    # 创建指定的数据库
    if [ "$POSTGRES_DB" != "postgres" ]; then
        gosu postgres /usr/pgsql/bin/createdb -U postgres -O $POSTGRES_USER "$POSTGRES_DB"
    fi

    echo "=== 执行扩展初始化脚本 ==="
    # 执行初始化脚本
    for f in /docker-entrypoint-initdb.d/*; do
        case "$f" in
            *.sh)     echo "$0: running $f"; . "$f" ;;
            *.sql)    echo "$0: running $f"; gosu postgres /usr/pgsql/bin/psql -U postgres -d "$POSTGRES_DB" -f "$f" ;;
            *.sql.gz) echo "$0: running $f"; gunzip -c "$f" | gosu postgres /usr/pgsql/bin/psql -U postgres -d "$POSTGRES_DB" ;;
            *)        echo "$0: ignoring $f" ;;
        esac
    done

    echo "=== 完成初始化，停止临时 PostgreSQL ==="
    kill %1
    wait
fi

echo "=== 启动 PostgreSQL 服务 ==="
# 启动 PostgreSQL（以 postgres 用户身份）
exec gosu postgres /usr/pgsql/bin/postgres
