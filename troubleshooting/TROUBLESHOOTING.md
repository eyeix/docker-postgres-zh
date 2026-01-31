# PostgreSQL 中文镜像故障排除指南

本文档提供了在使用 PostgreSQL 中文镜像时可能遇到的问题及其解决方案。

## 目录

1. [快速开始](#快速开始)
2. [常见问题](#常见问题)
3. [扩展配置](#扩展配置)
4. [诊断步骤](#诊断步骤)

---

## 快速开始

### 推荐方案：使用命名卷

这是最简单、最可靠的方案：

```bash
# 创建命名卷
docker volume create postgres_data

# 运行容器
docker run -d \
  --name postgres-zh \
  -e POSTGRES_PASSWORD=your_password \
  -v postgres_data:/var/lib/postgresql/data \
  -p 5432:5432 \
  eyeix/postgres-zh:v17
```

**优点**：
- ✅ 无需处理权限问题
- ✅ Docker 自动管理
- ✅ 跨平台兼容性好

### 使用本地目录

本镜像基于官方 postgres:17 镜像，完全支持本地目录挂载：

```bash
docker run -d \
  --name postgres-zh \
  -e POSTGRES_PASSWORD=your_password \
  -v /path/to/data:/var/lib/postgresql/data \
  -p 5432:5432 \
  eyeix/postgres-zh:v17
```

**无需预先设置权限**，官方 entrypoint 会自动处理。

---

## 常见问题

### 问题 1：容器无法启动

**检查日志**：
```bash
docker logs postgres-zh
```

**常见原因**：
1. 端口 5432 已被占用
2. 数据目录权限问题（极少见）
3. 密码未设置

**解决方案**：
```bash
# 检查端口占用
lsof -i :5432

# 更换端口
docker run -d -p 5433:5432 ...

# 确保设置密码
docker run -d -e POSTGRES_PASSWORD=your_password ...
```

### 问题 2：无法连接数据库

**检查容器状态**：
```bash
docker ps | grep postgres-zh
```

**测试连接**：
```bash
docker exec postgres-zh psql -U postgres -c "SELECT 1;"
```

**常见原因**：
1. 容器未完全启动（等待 10-30 秒）
2. 密码错误
3. 网络配置问题

### 问题 3：扩展不可用

**查看已安装扩展**：
```bash
docker exec postgres-zh psql -U postgres -c "\dx"
```

**创建扩展**：
```bash
docker exec postgres-zh psql -U postgres -c "CREATE EXTENSION IF NOT EXISTS vector;"
```

**注意**：某些扩展需要预加载，详见 [扩展配置](#扩展配置)。

---

## 扩展配置

### 预装扩展

以下扩展已预装并自动启用：

- ✅ **中文支持**: zhparser, pgroonga
- ✅ **向量搜索**: pgvector, smlar
- ✅ **地理位置**: postgis
- ✅ **全文搜索**: pg_trgm, fuzzystrmatch
- ✅ **JSON/GraphQL**: pg_jsonschema, pg_graphql
- ✅ **其他**: ltree, pg_stat_statements, pgmq, btree_gist, pg_partman, tablefunc

### 需要预加载的扩展

以下扩展需要在 `shared_preload_libraries` 中配置：

#### TimescaleDB

```bash
# 1. 修改配置
docker exec postgres-zh bash -c "echo \"shared_preload_libraries = 'timescaledb'\" >> /var/lib/postgresql/data/postgresql.conf"

# 2. 重启容器
docker restart postgres-zh

# 3. 创建扩展
docker exec postgres-zh psql -U postgres -c "CREATE EXTENSION timescaledb;"
```

#### VChord

```bash
# 1. 修改配置
docker exec postgres-zh bash -c "echo \"shared_preload_libraries = 'vchord'\" >> /var/lib/postgresql/data/postgresql.conf"

# 2. 重启容器
docker restart postgres-zh

# 3. 创建扩展
docker exec postgres-zh psql -U postgres -c "CREATE EXTENSION vchord;"
```

---

## 诊断步骤

### 1. 检查容器日志

```bash
docker logs postgres-zh
```

查找错误信息或警告。

### 2. 检查容器状态

```bash
docker ps -a | grep postgres-zh
```

确认容器是否在运行。

### 3. 测试数据库连接

```bash
docker exec postgres-zh psql -U postgres -c "SELECT version();"
```

### 4. 检查扩展状态

```bash
docker exec postgres-zh psql -U postgres -c "\dx"
```

### 5. 检查数据目录

```bash
# 在容器内
docker exec postgres-zh ls -la /var/lib/postgresql/data

# 在宿主机上（如果使用本地目录）
ls -la /path/to/data
```

---

## 获取帮助

如果以上方案都无法解决问题，请提供以下信息：

1. 操作系统版本：`uname -a`
2. Docker 版本：`docker version`
3. 容器日志：`docker logs postgres-zh`
4. 运行命令：你使用的完整 docker run 命令

在 GitHub Issues 中提交问题：https://github.com/eyeix/docker-postgres-zh/issues

---

## 相关文档

- [README.md](../README.md) - 项目主文档
- [EXTENSIONS.md](../EXTENSIONS.md) - 扩展详细说明
- [CHANGELOG.md](../CHANGELOG.md) - 更新日志
