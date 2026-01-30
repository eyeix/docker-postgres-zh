#!/bin/bash
set -e

# ===========================================
# PostgreSQL 中文适配镜像启动脚本
# ===========================================

# 调试信息：显示当前用户和环境
echo "=== 容器启动信息 ==="
echo "当前用户: $(whoami) (UID=$(id -u), GID=$(id -g))"
echo "postgres 用户: UID=$(id -u postgres 2>/dev/null || echo 'N/A') GID=$(id -g postgres 2>/dev/null || echo 'N/A')"
echo "gosu 版本: $(gosu --version 2>/dev/null || echo 'N/A')"

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
# 确保数据目录存在
if [ ! -d "$PGDATA" ]; then
    echo "=== 创建数据目录 $PGDATA ==="
    mkdir -p "$PGDATA"
fi

# 获取数据目录的当前所有者
dir_uid=$(stat -c "%u" "$PGDATA" 2>/dev/null || stat -f "%u" "$PGDATA" 2>/dev/null || echo "0")
dir_gid=$(stat -c "%g" "$PGDATA" 2>/dev/null || stat -f "%g" "$PGDATA" 2>/dev/null || echo "0")

# 获取 postgres 用户的 UID 和 GID
postgres_uid=$(id -u postgres 2>/dev/null || echo "999")
postgres_gid=$(id -g postgres 2>/dev/null || echo "999")

echo "=== 权限检查 ==="
echo "数据目录: $PGDATA"
echo "数据目录所有者: $dir_uid:$dir_gid"
echo "postgres 用户: $postgres_uid:$postgres_gid"

# 如果目录所有者与 postgres 用户不匹配，修改目录所有者
if [ "$dir_uid" != "$postgres_uid" ] || [ "$dir_gid" != "$postgres_gid" ]; then
    echo "=== 修改数据目录所有者为 postgres 用户 ==="

    # 尝试修改所有者（只修改顶层目录，避免递归修改大量文件）
    if chown postgres:postgres "$PGDATA" 2>/dev/null; then
        echo "✓ 顶层目录所有者修改成功"

        # 如果目录为空或只包含少量文件，递归修改
        file_count=$(find "$PGDATA" -maxdepth 1 | wc -l)
        if [ "$file_count" -lt 10 ]; then
            echo "目录为空或文件较少，递归修改所有者..."
            chown -R postgres:postgres "$PGDATA" 2>/dev/null || echo "警告：部分文件所有者修改失败"
        else
            echo "目录包含数据，仅修改顶层目录所有者"
        fi
    else
        echo "错误：无法修改数据目录权限"
        echo ""
        echo "可能的原因："
        echo "1. 容器没有足够的权限修改挂载目录"
        echo "2. SELinux 或 AppArmor 阻止了操作"
        echo "3. 文件系统不支持 chown 操作（如某些网络文件系统）"
        echo ""
        echo "解决方案："
        echo "1. 使用命名卷代替目录挂载："
        echo "   docker volume create postgres_data"
        echo "   docker run -v postgres_data:/var/lib/postgresql/data ..."
        echo ""
        echo "2. 在宿主机上预先设置目录权限："
        echo "   sudo chown -R $postgres_uid:$postgres_gid <宿主机数据目录>"
        echo ""
        echo "3. 如果使用 SELinux，添加正确的上下文："
        echo "   sudo chcon -Rt svirt_sandbox_file_t <宿主机数据目录>"
        exit 1
    fi
else
    echo "✓ 数据目录权限正常"
fi

# 确保其他必要目录的权限正确
echo "=== 检查其他目录权限 ==="
chown -R postgres:postgres /var/lib/postgresql /docker-entrypoint-initdb.d 2>/dev/null || echo "警告：部分目录权限修改失败"

# 测试 gosu 是否能正常工作
echo "=== 测试 gosu 功能 ==="
if gosu postgres id >/dev/null 2>&1; then
    echo "✓ gosu 测试成功"
else
    echo "错误：gosu 无法切换到 postgres 用户"
    echo "当前 postgres 用户信息："
    id postgres || echo "postgres 用户不存在"
    echo ""
    echo "这可能是容器安全限制导致的问题。"
    echo "请尝试使用命名卷代替目录挂载。"
    exit 1
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
