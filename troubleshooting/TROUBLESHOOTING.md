# PostgreSQL 中文镜像故障排除指南

本文档提供了在使用 PostgreSQL 中文镜像时可能遇到的问题及其解决方案。

## 目录

1. [快速开始](#快速开始)
2. [常见问题和解决方案](#常见问题和解决方案)
3. [Ubuntu 环境权限问题](#ubuntu-环境权限问题)
4. [详细修复说明](#详细修复说明)
5. [诊断步骤](#诊断步骤)
6. [完整测试方法](#完整测试方法)

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
- ✅ Docker 自动管理权限
- ✅ 跨平台兼容性好

### 快速测试

使用自动测试脚本（Ubuntu 环境）：

```bash
# 1. 构建镜像
docker build -t eyeix/postgres-zh:v17 .

# 2. 运行测试脚本
chmod +x troubleshooting/test-ubuntu.sh
./troubleshooting/test-ubuntu.sh
```

---

## 常见问题和解决方案

### 问题 1：权限错误

**错误信息**：
```
error: failed switching to "postgres": operation not permitted
```

**解决方案**：

1. **使用命名卷**（推荐）：
   ```bash
   docker volume create postgres_data
   docker run -d \
     --name postgres-zh \
     -e POSTGRES_PASSWORD=your_password \
     -v postgres_data:/var/lib/postgresql/data \
     -p 5432:5432 \
     eyeix/postgres-zh:v17
   ```

2. **预先设置目录权限**：
   ```bash
   sudo mkdir -p /path/to/data
   sudo chown -R 999:999 /path/to/data
   docker run -d \
     --name postgres-zh \
     -e POSTGRES_PASSWORD=your_password \
     -v /path/to/data:/var/lib/postgresql/data \
     -p 5432:5432 \
     eyeix/postgres-zh:v17
   ```

### 问题 2：无法修改数据目录权限

**错误信息**：
```
错误：无法修改数据目录权限
```

**解决方法**：
1. 使用命名卷代替目录挂载
2. 在宿主机上预先设置权限
3. 检查 SELinux/AppArmor 限制

### 问题 3：gosu 无法切换用户

**错误信息**：
```
错误：gosu 无法切换到 postgres 用户
```

**解决方法**：
1. 确认容器以 root 用户运行（不要使用 `--user` 参数）
2. 检查 postgres 用户是否正确创建
3. 尝试使用 `--security-opt apparmor=unconfined`

### 问题 4：postgres 用户 UID/GID 不正确

**错误信息**：
```
postgres 用户: UID=100 GID=102
```

**解决方法**：
1. 重新构建镜像，确保 Dockerfile 中的用户创建逻辑正确
2. 检查 Pig 安装是否创建了不同 UID/GID 的用户

---

## Ubuntu 环境权限问题

### 根本原因

在 Ubuntu 环境下运行时，可能会遇到权限问题，通常由以下原因引起：

1. **容器安全限制**：Ubuntu 的 Docker 可能启用了更严格的安全策略（AppArmor、SELinux）
2. **用户配置问题**：postgres 用户的 UID/GID 配置不正确
3. **权限问题**：容器无法修改挂载目录的权限

### 解决方案

#### 方案 1：使用命名卷（推荐）

```bash
docker volume create postgres_data
docker run -d \
  --name postgres-zh \
  -e POSTGRES_PASSWORD=your_password \
  -v postgres_data:/var/lib/postgresql/data \
  -p 5432:5432 \
  eyeix/postgres-zh:v17
```

#### 方案 2：预先设置目录权限

```bash
sudo mkdir -p /path/to/data
sudo chown -R 999:999 /path/to/data
docker run -d \
  --name postgres-zh \
  -e POSTGRES_PASSWORD=your_password \
  -v /path/to/data:/var/lib/postgresql/data \
  -p 5432:5432 \
  eyeix/postgres-zh:v17
```

#### 方案 3：处理 SELinux 限制

如果使用 SELinux（如 CentOS、RHEL、Fedora）：

```bash
# 检查 SELinux 状态
getenforce

# 为数据目录添加正确的 SELinux 上下文
sudo chcon -Rt svirt_sandbox_file_t /path/to/data

# 或者临时禁用 SELinux（仅用于测试）
sudo setenforce 0
```

#### 方案 4：处理 AppArmor 限制

如果使用 AppArmor（如 Ubuntu、Debian）：

```bash
# 检查 AppArmor 状态
sudo aa-status

# 临时禁用 Docker 的 AppArmor 配置（仅用于测试）
docker run -d \
  --name postgres-zh \
  --security-opt apparmor=unconfined \
  -e POSTGRES_PASSWORD=your_password \
  -v /path/to/data:/var/lib/postgresql/data \
  -p 5432:5432 \
  eyeix/postgres-zh:v17
```

---

## 详细修复说明

### 修复概述

本次修复解决了在 Ubuntu 环境下运行 PostgreSQL 中文镜像时遇到的 `operation not permitted` 错误。

### 问题分析

#### 原始问题

在 Ubuntu 环境下，容器启动时出现以下错误：

```
error: failed switching to "postgres": operation not permitted
```

#### 根本原因

1. **用户 UID/GID 不一致**：Pig 安装 PostgreSQL 时可能创建了 UID/GID 不是 999:999 的 postgres 用户
2. **运行时修改用户失败**：在 docker-entrypoint.sh 中尝试使用 `usermod` 和 `groupmod` 修改用户，但在某些容器环境中会失败
3. **gosu 切换用户失败**：由于用户配置问题，`gosu postgres` 命令无法正常工作

### 修复方案

#### 1. Dockerfile 改进

**改进内容**：
- 在构建时（而不是运行时）确保 postgres 用户的 UID/GID 正确
- 处理 UID/GID 冲突，确保 postgres 用户使用 999:999
- 添加验证步骤，确保最终配置正确
- 创建必要的运行时目录（/var/run/postgresql）

**关键改进**：
```dockerfile
# 确保 postgres 用户存在且 UID/GID 正确
RUN set -ex; \
    # 检查是否存在 UID 999 或 GID 999 的冲突
    existing_uid_user=$(getent passwd 999 | cut -d: -f1 || echo ""); \
    existing_gid_group=$(getent group 999 | cut -d: -f1 || echo ""); \
    # ... 处理冲突并创建用户
```

#### 2. docker-entrypoint.sh 改进

**改进内容**：

a. **添加调试信息**：
```bash
echo "=== 容器启动信息 ==="
echo "当前用户: $(whoami) (UID=$(id -u), GID=$(id -g))"
echo "postgres 用户: UID=$(id -u postgres) GID=$(id -g postgres)"
echo "gosu 版本: $(gosu --version)"
```

b. **优化权限处理**：
- 不再尝试修改用户 UID/GID（改为在构建时处理）
- 使用 `chown` 修改数据目录所有者
- 只修改顶层目录，避免递归修改大量文件
- 添加详细的错误信息和解决方案

c. **添加 gosu 测试**：
```bash
echo "=== 测试 gosu 功能 ==="
if gosu postgres id >/dev/null 2>&1; then
    echo "✓ gosu 测试成功"
else
    echo "错误：gosu 无法切换到 postgres 用户"
    exit 1
fi
```

#### 3. 文档改进

- 更新 README.md 权限处理说明
- 添加详细的故障排除步骤
- 创建专门的故障排除文档

### 预期结果

#### 成功的日志输出

```
=== 容器启动信息 ===
当前用户: root (UID=0, GID=0)
postgres 用户: UID=999 GID=999
gosu 版本: 1.x.x

=== 权限检查 ===
数据目录: /var/lib/postgresql/data
数据目录所有者: 999:999
postgres 用户: 999:999
✓ 数据目录权限正常

=== 测试 gosu 功能 ===
✓ gosu 测试成功

=== 初始化 PostgreSQL 数据库 ===
...
=== 启动 PostgreSQL 服务 ===
```

### 兼容性

#### 测试环境

- ✅ macOS（Docker Desktop）
- ✅ Ubuntu 20.04/22.04/24.04
- ✅ Debian 11/12
- ✅ CentOS/RHEL 8/9
- ✅ Fedora 38+

#### 架构支持

- ✅ linux/amd64
- ✅ linux/arm64

---

## 诊断步骤

### 1. 检查容器日志

```bash
docker logs postgres-zh
```

查找以下信息：
- postgres 用户的 UID/GID
- 权限检查结果
- gosu 测试结果

### 2. 检查 postgres 用户配置

```bash
# 进入容器
docker exec -it postgres-zh bash

# 检查用户信息
id postgres

# 应该显示：uid=999(postgres) gid=999(postgres) groups=999(postgres)
```

### 3. 检查数据目录权限

```bash
# 在容器内
ls -la /var/lib/postgresql/data

# 在宿主机上
ls -la /path/to/data
```

### 4. 测试 gosu

```bash
# 在容器内
gosu postgres id

# 应该显示 postgres 用户的信息
```

### 5. 检查安全限制

```bash
# 检查 SELinux 状态
getenforce

# 检查 AppArmor 状态
sudo aa-status
```

---

## 完整测试方法

### 方法 1：使用自动测试脚本（推荐）

```bash
# 1. 构建镜像
docker build -t eyeix/postgres-zh:v17 .

# 2. 运行测试脚本
chmod +x troubleshooting/test-ubuntu.sh
./troubleshooting/test-ubuntu.sh
```

测试脚本会自动测试：
- ✅ 命名卷挂载
- ✅ 目录挂载
- ✅ 数据库连接

### 方法 2：手动测试命名卷

```bash
# 1. 构建镜像
docker build -t eyeix/postgres-zh:v17 .

# 2. 创建命名卷
docker volume create postgres_data

# 3. 启动容器
docker run -d \
  --name postgres-zh \
  -e POSTGRES_PASSWORD=testpass \
  -v postgres_data:/var/lib/postgresql/data \
  -p 5432:5432 \
  eyeix/postgres-zh:v17

# 4. 等待启动（约 10 秒）
sleep 10

# 5. 检查日志（应该看到成功的启动信息）
docker logs postgres-zh

# 6. 测试连接
docker exec postgres-zh /usr/pgsql/bin/psql -U postgres -c "SELECT version();"

# 7. 清理
docker rm -f postgres-zh
docker volume rm postgres_data
```

### 方法 3：手动测试目录挂载

```bash
# 1. 构建镜像
docker build -t eyeix/postgres-zh:v17 .

# 2. 创建测试目录
sudo mkdir -p /tmp/postgres-data
sudo chmod 777 /tmp/postgres-data

# 3. 启动容器
docker run -d \
  --name postgres-zh \
  -e POSTGRES_PASSWORD=testpass \
  -v /tmp/postgres-data:/var/lib/postgresql/data \
  -p 5432:5432 \
  eyeix/postgres-zh:v17

# 4. 等待启动（约 10 秒）
sleep 10

# 5. 检查日志（应该看到权限修改和成功启动的信息）
docker logs postgres-zh

# 6. 测试连接
docker exec postgres-zh /usr/pgsql/bin/psql -U postgres -c "SELECT version();"

# 7. 清理
docker rm -f postgres-zh
sudo rm -rf /tmp/postgres-data
```

---

## 获取帮助

如果以上方案都无法解决问题，请提供以下信息：

1. 操作系统版本：`lsb_release -a`
2. Docker 版本：`docker version`
3. 容器日志：`docker logs postgres-zh`
4. SELinux 状态：`getenforce`（如果适用）
5. AppArmor 状态：`sudo aa-status`（如果适用）

在 GitHub Issues 中提交问题：https://github.com/eyeix/docker-postgres-zh/issues

---

## 相关文件

- `Dockerfile`：镜像构建配置
- `docker-entrypoint.sh`：容器启动脚本
- `README.md`：项目文档
- `test-ubuntu.sh`：Ubuntu 测试脚本
