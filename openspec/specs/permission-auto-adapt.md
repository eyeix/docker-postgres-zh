# 权限自动适配功能规范

## 概述

**状态**: 已实现 ✅
**版本**: v17
**日期**: 2026-01-29

本规范描述了 Docker PostgreSQL 中文镜像的权限自动适配功能，解决了容器挂载卷时的权限问题。

## 问题背景

### 原有问题

在之前的版本中，使用 volume 或目录挂载时会遇到权限问题：

1. **固定 UID/GID**: 容器内的 postgres 用户固定为 UID 999:GID 999
2. **权限不匹配**: 挂载的目录可能属于不同的 UID/GID（如 100:162）
3. **修复失败**: 容器内的 root 用户无法修改挂载卷的所有者
4. **启动失败**: PostgreSQL 因权限问题无法启动

### 用户影响

- 需要手动在宿主机上执行 `sudo chown -R 999:999 <数据目录>`
- 使用 Docker volume 也可能遇到同样的问题
- 需要使用 `--privileged` 参数（安全风险）
- 特殊文件系统（NFS、云存储）更难处理

## 解决方案

### 核心思路

采用**智能权限适配机制**：容器启动时动态调整容器内 postgres 用户的 UID/GID 以匹配挂载目录的所有者。

### 技术实现

#### 1. 独立的 entrypoint 脚本

将启动脚本从 Dockerfile 中提取为独立的 `docker-entrypoint.sh` 文件：

```dockerfile
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
```

**优势**:
- 易于维护和调试
- 减少 Dockerfile 复杂度
- 支持版本控制

#### 2. 权限适配逻辑

在 `docker-entrypoint.sh` 中实现：

```bash
# 获取数据目录的所有者 UID 和 GID
dir_uid=$(stat -c "%u" "$PGDATA")
dir_gid=$(stat -c "%g" "$PGDATA")

# 获取当前 postgres 用户的 UID 和 GID
current_uid=$(id -u postgres)
current_gid=$(id -g postgres)

# 如果不匹配，调整 postgres 用户的 UID/GID
if [ "$dir_uid" != "$current_uid" ] || [ "$dir_gid" != "$current_gid" ]; then
    echo "=== 检测到数据目录所有者: $dir_uid:$dir_gid ==="
    echo "=== 调整 postgres 用户 UID/GID 以匹配数据目录 ==="

    groupmod -g "$dir_gid" postgres
    usermod -u "$dir_uid" postgres

    # 修复容器内其他目录的权限
    chown -R postgres:postgres /var/lib/postgresql /docker-entrypoint-initdb.d

    echo "=== 权限适配完成：postgres 用户现在是 $(id -u postgres):$(id -g postgres) ==="
fi
```

**工作流程**:
1. 检测数据目录的所有者
2. 比较与容器内 postgres 用户的 UID/GID
3. 如果不匹配，动态修改 postgres 用户的 UID/GID
4. 修复容器内相关目录的权限
5. 以调整后的 postgres 用户身份启动 PostgreSQL

#### 3. UTF-8 编码支持

同时修复了数据库编码问题，确保所有扩展（包括 pg_duckdb）都能正常工作：

```bash
gosu postgres /usr/pgsql/bin/initdb --encoding=UTF8 --locale=en_US.UTF-8
```

## 功能特性

### 自动适配

- ✅ 无需手动修复权限
- ✅ 支持任意 UID/GID
- ✅ 适应不同的宿主机环境
- ✅ 支持目录挂载和命名卷

### 兼容性

- ✅ 支持 NFS、云存储等特殊文件系统
- ✅ 无需 `--privileged` 参数
- ✅ 兼容 Docker 和 Docker Compose
- ✅ 支持多架构（AMD64、ARM64）

### 安全性

- ✅ 容器以 root 启动，但 PostgreSQL 以 postgres 用户运行
- ✅ 使用 gosu 安全切换用户
- ✅ 最小权限原则
- ✅ 无需特权模式

## 使用方式

### 目录挂载

```bash
docker run -d \
  --name postgres-zh \
  -v /path/to/data:/var/lib/postgresql/data \
  -e POSTGRES_PASSWORD=your_password \
  -p 5432:5432 \
  eyeix/postgres-zh:v17
```

### 命名卷

```bash
docker volume create postgres_data
docker run -d \
  --name postgres-zh \
  -v postgres_data:/var/lib/postgresql/data \
  -e POSTGRES_PASSWORD=your_password \
  -p 5432:5432 \
  eyeix/postgres-zh:v17
```

### Docker Compose

```yaml
services:
  postgres:
    image: eyeix/postgres-zh:v17
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      POSTGRES_PASSWORD: your_password
    ports:
      - "5432:5432"

volumes:
  postgres_data:
```

## 验证测试

### 测试场景

1. **目录挂载**: 使用宿主机目录挂载
2. **命名卷**: 使用 Docker 命名卷
3. **不同 UID/GID**: 测试各种权限组合
4. **特殊文件系统**: NFS、云存储等

### 测试结果

- ✅ 权限自动适配成功
- ✅ PostgreSQL 正常启动
- ✅ 所有扩展正常工作
- ✅ 数据持久化正常
- ✅ 中文分词功能正常

## 注意事项

### 必要条件

1. 容器必须以 root 用户运行（默认行为）
2. 数据目录的所有者必须有读写权限
3. 首次启动时会自动初始化数据库

### 限制

1. 权限适配只在容器启动时执行一次
2. 如果数据目录已初始化，不会重新调整权限
3. 容器内的 postgres 用户 UID/GID 会随数据目录变化

### 最佳实践

1. **推荐使用命名卷**: 获得更好的性能和可移植性
2. **避免频繁更改权限**: 数据目录初始化后保持权限稳定
3. **备份数据**: 在生产环境中定期备份数据

## 相关文件

- `docker-entrypoint.sh`: 启动脚本，包含权限适配逻辑
- `Dockerfile`: 镜像构建文件
- `docker-compose.yml`: Docker Compose 配置示例
- `README.md`: 用户文档

## 未来改进

### 可能的优化

1. **动态权限检查**: 每次启动时检查权限变化
2. **权限修复工具**: 提供独立的权限修复脚本
3. **更详细的日志**: 记录权限适配的详细过程
4. **健康检查**: 添加权限状态的健康检查

### 已知问题

无已知问题。

## 参考资料

- [PostgreSQL 官方文档 - initdb](https://www.postgresql.org/docs/17/app-initdb.html)
- [Docker 卷管理](https://docs.docker.com/storage/volumes/)
- [gosu 工具](https://github.com/tianon/gosu)
