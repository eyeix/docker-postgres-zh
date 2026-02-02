# Docker PostgreSQL 中文适配镜像

这是一个基于 PostgreSQL 17 的 Docker 镜像，专门为中文应用开发优化，预装了中文分词、全文搜索、向量搜索、时间序列、地理空间等丰富扩展，提供完整的中文数据处理能力。

## 📋 目录

- [🏗️ 多架构支持](#️-多架构支持)
- [功能特性](#功能特性)
- [📦 预装扩展](#-预装扩展)
- [🚀 快速开始](#-快速开始)
- [📖 使用示例](#-使用示例)
- [⚙️ 配置说明](#️-配置说明)
- [🛠️ 开发指南](#️-开发指南)
- [🚀 性能优化](#-性能优化)
- [🏗️ 架构兼容性](#️-架构兼容性)
- [🔧 故障排除](#-故障排除)
- [📄 许可证](#-许可证)
- [🤝 贡献](#-贡献)
- [🗺️ 路线图](#️-路线图)

## 🏗️ 多架构支持

本镜像支持以下架构（基于 Pig 包管理器的支持）：

- **linux/amd64** - Intel/AMD 64位处理器
- **linux/arm64** - ARM 64位处理器（Apple Silicon、AWS Graviton 等）

## 功能特性

### 🚀 核心功能

- **PostgreSQL 17**: 基于官方 postgres:17 镜像和 Pig 包管理器
- **多架构支持**: 支持 2 种主要的 CPU 架构（基于 Pig 包管理器支持）
- **中文数据处理**: 专门优化的中文分词、全文搜索和文本处理能力
- **AI/向量支持**: 集成 pgvector、smlar 等向量搜索扩展，支持中文语义搜索
- **时间序列**: 集成 TimescaleDB 时间序列数据库，支持中文标签和注释
- **地理空间**: 集成 PostGIS 地理空间数据处理，支持中文地名和地址
- **分析能力**: 集成 pg_partman、tablefunc 等分析工具，支持中文数据分析
- **扩展丰富**: 预装 20+ 个专业 PostgreSQL 扩展，全面支持中文应用场景
- **容错构建**: 智能处理不同架构的包兼容性问题
- **Pig 环境管理**: 使用 Pig 包管理器统一管理 PostgreSQL 内核和扩展

### 📦 预装扩展

本镜像预装了 **20+ 个专业 PostgreSQL 扩展**，涵盖中文分词、全文搜索、向量搜索、时间序列、地理空间、数据分析等各个领域。

#### 主要扩展类别

- **中文分词**: zhparser（基于 SCWS 的中文分词器）
- **全文搜索**: zhparser（中文）、pgroonga、pg_trgm（英文）等
- **AI/向量**: pgvector、smlar、vchord 等
- **时间序列**: timescaledb
- **地理空间**: postgis
- **数据分析**: pg_partman、tablefunc
- **功能增强**: pg_jsonschema、pg_graphql 等

> 📖 **详细扩展说明**: 查看 [EXTENSIONS.md](EXTENSIONS.md) 了解所有扩展的详细功能、依赖关系和安装顺序。

## 🚀 快速开始

> ⚠️ **存储注意事项**：
> - ✅ **推荐**：命名卷或本地文件系统（ext4/xfs/btrfs）
> - ✅ **支持**：NFS（需要服务端配置 `no_root_squash`）
> - ❌ **不支持**：CIFS/SMB（无法执行权限管理命令）
> - 📖 详见 [网络文件系统说明](troubleshooting/TROUBLESHOOTING.md#问题-1网络文件系统权限错误)

### 使用 Docker 运行

```bash
# 拉取镜像（Docker 会自动选择适合你平台的架构）
docker pull eyeix/postgres-zh:v17

# 运行容器
docker run -d \
  --name postgres-zh \
  -e POSTGRES_DB=zh-app \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=your_password \
  -p 5432:5432 \
  eyeix/postgres-zh:v17
```

### 使用 Docker Compose

```yaml
version: '3.8'
services:
  postgres:
    image: eyeix/postgres-zh:v17
    container_name: postgres-zh
services:
  postgres:
    image: eyeix/postgres-zh:v17
    container_name: postgres-zh
    environment:
      POSTGRES_DB: zh-app
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: your_password
    ports:
      - "5432:5432"
    volumes:
      # 推荐：使用命名卷
      - postgres_data:/var/lib/postgresql/data
      # 或使用本地目录（现已完全支持，无需预设权限）
      # - /path/to/data:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  postgres_data:
```

> 💡 **存储卷选择建议**：
> - ✅ **命名卷**（推荐）：适用于所有环境，Docker 自动管理
> - ✅ **本地目录**：现已完全支持，无需预先设置权限

### 多架构支持

本镜像支持多种架构，Docker 会自动选择适合你平台的版本：

- **Intel/AMD 服务器**: 自动使用 `linux/amd64` 版本
- **Apple Silicon Mac**: 自动使用 `linux/arm64` 版本
- **ARM 64位服务器**: 自动使用 `linux/arm64` 版本（AWS Graviton、树莓派 4 等）

### 测试和示例

如需测试数据和示例，请使用项目根目录的测试脚本：

- **[TESTING.md](TESTING.md)**: 完整的测试指南、脚本和示例数据

#### 使用测试脚本

```bash
# 1. 启动容器
docker run -d \
  --name postgres-zh \
  -e POSTGRES_DB=zh-app \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=your_password \
  -p 5432:5432 \
  eyeix/postgres-zh:v17

# 2. 连接到数据库
docker exec -it postgres-zh psql -U postgres -d zh-app

# 3. 执行测试脚本
\i test-examples.sql
```

#### 测试脚本内容

测试脚本包含：

- 示例表结构
- 测试数据插入
- 中文全文搜索示例
- 分词功能验证
- 扩展状态检查

## 📖 使用示例

### 中文全文搜索

#### 1. 创建测试表和数据

```sql
-- 连接到数据库
\c zh-app

-- 创建文章表
CREATE TABLE articles (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 插入测试数据
INSERT INTO articles (title, content) VALUES
('人工智能的发展', '人工智能技术正在快速发展，深度学习、机器学习等技术不断突破'),
('数据库优化技巧', 'PostgreSQL 数据库性能优化需要从多个方面考虑，包括索引、查询优化等'),
('中文分词技术', '中文分词是自然语言处理的基础技术，对搜索引擎和文本分析至关重要');
```

#### 2. 使用 zhparser 进行中文全文搜索

```sql
-- 使用中文配置创建全文搜索索引
CREATE INDEX idx_articles_fts ON articles
    USING gin(to_tsvector('zhparser_zh', title || ' ' || content));

-- 搜索包含"人工智能"的文章
SELECT title, content,
       ts_rank(to_tsvector('zhparser_zh', title || ' ' || content),
               to_tsquery('zhparser_zh', '人工智能')) as rank
    FROM articles
WHERE to_tsvector('zhparser_zh', title || ' ' || content) @@ to_tsquery('zhparser_zh', '人工智能')
ORDER BY rank DESC;

-- 使用 pg_trgm 进行模糊搜索
SELECT title, content, similarity(title, '人工智能') as sim
FROM articles
WHERE title % '人工智能' OR content % '人工智能'
ORDER BY sim DESC;
```

#### 3. 使用 PGroonga 进行高性能中文搜索

PGroonga 是基于 Groonga 的高性能全文搜索扩展，特别适合处理大量中文文本。

```sql
-- 启用 PGroonga 扩展
CREATE EXTENSION IF NOT EXISTS pgroonga;

-- 创建 PGroonga 索引（GIN 索引）
CREATE INDEX idx_articles_pgroonga ON articles
    USING pgroonga ((ARRAY[title, content]));

-- 基本全文搜索
-- 说明：pgroonga_score(tableoid, ctid) 计算搜索结果的相关性评分
--   - tableoid: 表对象ID（PostgreSQL 系统列）
--   - ctid: 行物理位置（PostgreSQL 系统列，格式如 (0,1)）
--   - score: 分数越高表示匹配度越好，用于结果排序
SELECT title, content,
       pgroonga_score(tableoid, ctid) as score
FROM articles
WHERE ARRAY[title, content] &@~ '人工智能'
ORDER BY score DESC;

-- 多关键词搜索（AND 逻辑）
SELECT title, content,
       pgroonga_score(tableoid, ctid) as score
FROM articles
WHERE ARRAY[title, content] &@~ '人工智能 数据库'
ORDER BY score DESC;

-- 多关键词搜索（OR 逻辑）
SELECT title, content,
       pgroonga_score(tableoid, ctid) as score
FROM articles
WHERE ARRAY[title, content] &@~ '人工智能 OR 机器学习'
ORDER BY score DESC;

-- 前缀搜索
SELECT title, content
FROM articles
WHERE ARRAY[title, content] &^~ '人工';

-- 模糊搜索（相似度匹配）
SELECT title, content,
       pgroonga_score(tableoid, ctid) as score
FROM articles
WHERE ARRAY[title, content] &@* '人工智能'
ORDER BY score DESC;

-- 高亮搜索结果
SELECT title,
       pgroonga_highlight_html(content, pgroonga_query_extract_keywords('人工智能')) as highlighted_content
FROM articles
WHERE ARRAY[title, content] &@~ '人工智能';
```

**PGroonga 特点：**

- ✅ 高性能：专门为全文搜索优化
- ✅ 中文友好：原生支持中文、日文等多字节字符
- ✅ 丰富的搜索操作：支持前缀搜索、模糊搜索、正则表达式等
- ✅ 高亮功能：内置搜索结果高亮
- ✅ 实时更新：索引自动更新，无需重建

### AI/向量搜索

```sql
-- 启用向量扩展
CREATE EXTENSION IF NOT EXISTS vector;

-- 创建向量表
CREATE TABLE embeddings (
    id SERIAL PRIMARY KEY,
    content TEXT,
    embedding vector(5)
);

-- 插入向量数据
INSERT INTO embeddings (content, embedding) VALUES
('机器学习', '[0.1, 0.2, 0.3, 0.4, 0.5]'),
('深度学习', '[0.2, 0.3, 0.4, 0.5, 0.6]'),
('自然语言处理', '[0.3, 0.4, 0.5, 0.6, 0.7]');

-- 向量相似度搜索
SELECT content, embedding <-> '[0.15, 0.25, 0.35, 0.45, 0.55]' as distance
FROM embeddings
ORDER BY embedding <-> '[0.15, 0.25, 0.35, 0.45, 0.55]'
LIMIT 5;
```

### 时间序列数据处理

```sql
-- 启用 TimescaleDB
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- 创建时间序列表
CREATE TABLE metrics (
    time TIMESTAMPTZ NOT NULL,
    device_id INTEGER,
    temperature DOUBLE PRECISION,
    humidity DOUBLE PRECISION
);

-- 转换为超表
SELECT create_hypertable('metrics', 'time');

-- 插入时间序列数据
INSERT INTO metrics (time, device_id, temperature, humidity) VALUES
(NOW(), 1, 25.5, 60.2),
(NOW() + INTERVAL '1 minute', 1, 26.1, 58.9),
(NOW() + INTERVAL '2 minutes', 1, 25.8, 59.5);

-- 时间序列查询
SELECT time_bucket('1 hour', time) as hour,
       AVG(temperature) as avg_temp,
       AVG(humidity) as avg_humidity
FROM metrics
GROUP BY hour
ORDER BY hour;
```

### 地理空间数据处理

```sql
-- 启用 PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;

-- 创建地理空间表
CREATE TABLE locations (
    id SERIAL PRIMARY KEY,
    name TEXT,
    geom GEOMETRY(POINT, 4326)
);

-- 插入地理数据
INSERT INTO locations (name, geom) VALUES
('北京', ST_GeomFromText('POINT(116.4074 39.9042)', 4326)),
('上海', ST_GeomFromText('POINT(121.4737 31.2304)', 4326)),
('广州', ST_GeomFromText('POINT(113.2644 23.1291)', 4326));

-- 计算距离
SELECT name,
       ST_Distance(geom, ST_GeomFromText('POINT(116.4074 39.9042)', 4326)) as distance_km
FROM locations
ORDER BY distance_km;
```

### 数据分析功能

```sql
-- 启用分析扩展
CREATE EXTENSION IF NOT EXISTS tablefunc;

-- 创建销售数据表
CREATE TABLE sales (
    id SERIAL PRIMARY KEY,
    product TEXT,
    region TEXT,
    quarter TEXT,
    sales_amount DECIMAL
);

-- 插入测试数据
INSERT INTO sales (product, region, quarter, sales_amount) VALUES
('产品A', '华北', 'Q1', 10000),
('产品A', '华北', 'Q2', 12000),
('产品B', '华南', 'Q1', 8000),
('产品B', '华南', 'Q2', 9000);

-- 使用交叉表分析
SELECT * FROM crosstab(
    'SELECT product, quarter, sales_amount FROM sales ORDER BY 1,2',
    'SELECT DISTINCT quarter FROM sales ORDER BY 1'
) AS ct(product TEXT, q1 DECIMAL, q2 DECIMAL);
```

## ⚙️ 配置说明

### 环境变量

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `POSTGRES_DB` | `postgres` | 默认数据库名，如果指定则自动创建该数据库 |
| `POSTGRES_USER` | `postgres` | 数据库用户名，如果指定则创建该用户并授予超级用户权限 |
| `POSTGRES_PASSWORD` | `postgres` | 数据库密码，如果未指定则使用默认密码 |
| `PGDATA` | `/var/lib/postgresql/data` | PostgreSQL 数据目录 |

#### 环境变量使用示例

```bash
# 使用默认配置
docker run -d \
  --name postgres-zh \
  -e POSTGRES_PASSWORD=your_password \
  -p 5432:5432 \
  eyeix/postgres-zh:v17

# 自定义用户和数据库
docker run -d \
  --name postgres-zh \
  -e POSTGRES_USER=myuser \
  -e POSTGRES_DB=mydb \
  -e POSTGRES_PASSWORD=my_password \
  -p 5432:5432 \
  eyeix/postgres-zh:v17

# 完全自定义配置
docker run -d \
  --name postgres-zh \
  -e POSTGRES_USER=admin \
  -e POSTGRES_DB=zh_search \
  -e POSTGRES_PASSWORD=secure_password \
  -p 5432:5432 \
  eyeix/postgres-zh:v17
```

#### 环境变量行为说明

- **POSTGRES_USER**:
  - 如果设置为 `postgres`（默认），则修改默认用户的密码
  - 如果设置为其他值，则创建新用户并授予超级用户权限
- **POSTGRES_DB**:
  - 如果设置为 `postgres`（默认），使用默认数据库
  - 如果设置为其他值，则创建新数据库并设置指定用户为所有者
- **POSTGRES_PASSWORD**: 必需设置，用于数据库认证

## 🛠️ 开发指南

### 构建镜像

```bash
# 克隆仓库
git clone https://github.com/riccox/docker-postgres-zh.git
cd docker-postgres-zh

# 构建镜像
docker buildx build --platform linux/amd64,linux/arm64 -t eyeix/postgres-zh .
```

### Pig 包管理器

本镜像使用 [Pig](https://pig.pgsty.com/zh/start/) 作为 PostgreSQL 环境和扩展的包管理器，提供以下优势：

- **统一管理**: 通过 Pig 统一管理 PostgreSQL 内核和所有扩展
- **多架构支持**: 自动处理不同架构的兼容性
- **容错安装**: 智能处理安装失败的情况
- **环境配置**: 自动配置 PostgreSQL 运行环境

#### 扩展管理

```bash
# 查看已安装的扩展
docker exec -it postgres-zh pig ext list

# 安装新扩展（自动确认）
docker exec -it postgres-zh pig ext install <extension_name> -y

# 更新扩展（自动确认）
docker exec -it postgres-zh pig ext update <extension_name> -y

# 查看可用扩展
docker exec -it postgres-zh pig ext search <extension_name>
```

### 本地开发

```bash
# 运行开发环境
docker run -it --rm \
  -e POSTGRES_PASSWORD=dev_password \
  -p 5432:5432 \
  -v $(pwd)/init-scripts:/docker-entrypoint-initdb.d \
  eyeix/postgres-zh:v17
```

## 🚀 性能优化

### 索引优化

- 为经常搜索的字段创建 GIN 索引
- 使用 `pg_trgm` 扩展进行模糊搜索和相似度匹配

### 查询优化

- 使用 `ts_rank()` 函数进行相关性排序
- 合理使用 `LIMIT` 限制结果集大小
- 避免在 `WHERE` 子句中使用函数

### 配置调优

```sql
-- 调整全文搜索相关参数
SET default_text_search_config = 'zhparser_zh';
SET pg_trgm.similarity_threshold = 0.3;
```

## 🏗️ 架构兼容性

### 功能可用性

不同架构的功能可用性可能有所不同（基于 Pig 包管理器）：

| 架构 | PostgreSQL | zhparser | 其他扩展 | 状态 |
|------|------------|----------|----------|------|
| linux/amd64 | ✅ 完整支持 | ✅ 完整支持 | ✅ 完整支持 | 🟢 推荐 |
| linux/arm64 | ✅ 完整支持 | ✅ 完整支持 | ✅ 完整支持 | 🟢 推荐 |

### 说明

- **🟢 推荐**: 完整功能支持，最佳性能（Pig 包管理器完全支持）
- **📝 注意**: 由于 Pig 包管理器的限制，目前只支持 x86_64 和 aarch64 架构

## 🔧 故障排除

### 常见问题

#### 1. 数据持久化和权限

**✅ 自动权限修复**: 本镜像会在启动时自动将数据目录的所有者修改为容器内的 `postgres` 用户（UID:999, GID:999），**无需手动修复权限**。

**推荐方式**：

```bash
# 方式 1：使用命名卷（推荐，最简单）
docker volume create postgres_data
docker run -d \
  --name postgres-zh \
  -v postgres_data:/var/lib/postgresql/data \
  -e POSTGRES_PASSWORD=your_password \
  -p 5432:5432 \
  eyeix/postgres-zh:v17

# 方式 2：使用目录挂载（自动修复权限）
docker run -d \
  --name postgres-zh \
  -v /path/to/data:/var/lib/postgresql/data \
  -e POSTGRES_PASSWORD=your_password \
  -p 5432:5432 \
  eyeix/postgres-zh:v17
```

**特性**：
- ✅ 自动修复数据目录权限
- ✅ 支持命名卷和目录挂载
- ✅ 无需 `--privileged` 参数
- ✅ 无需手动 `chown` 修复权限

**注意事项**：
- 容器内 postgres 用户的 UID/GID 固定为 999:999
- 如果使用目录挂载，容器会自动将目录所有者改为 999:999
- **网络文件系统支持**：
  - ✅ **NFS**：支持，但需要服务端配置 `no_root_squash`
  - ❌ **CIFS/SMB**：不支持，因为无法执行 chmod/chown 操作
  - 📖 详见 [网络文件系统权限说明](troubleshooting/TROUBLESHOOTING.md#问题-1网络文件系统权限错误)
- 如果需要在宿主机上访问数据目录，可以：
  ```bash
  # 方法 1：将宿主机用户添加到 GID 999 的组
  sudo groupadd -g 999 postgres
  sudo usermod -aG postgres $USER

  # 方法 2：在宿主机上预先设置目录权限
  sudo mkdir -p /path/to/data
  sudo chown -R 999:999 /path/to/data
  ```

**故障排除**：

如果遇到权限错误（如 `operation not permitted`）或其他问题，请查看：

- 📖 [完整故障排除指南](troubleshooting/TROUBLESHOOTING.md) - 包含快速测试、常见问题、详细修复说明和诊断步骤
- 💡 继续阅读下面的快速诊断步骤

诊断步骤：

1. **确认容器以 root 用户运行**（默认行为）：
   ```bash
   docker inspect postgres-zh | grep -i user
   # 应该没有输出或显示 "User": ""
   ```

2. **检查容器日志**：
   ```bash
   docker logs postgres-zh
   # 查看权限检查和 gosu 测试结果
   ```

3. **检查 SELinux 或 AppArmor 限制**（某些 Linux 发行版）：
   ```bash
   # SELinux（CentOS/RHEL/Fedora）
   getenforce
   sudo chcon -Rt svirt_sandbox_file_t /path/to/data

   # AppArmor（Ubuntu/Debian）
   sudo aa-status
   ```

4. **使用命名卷代替目录挂载**（最简单的解决方案）：
   ```bash
   docker volume create postgres_data
   docker run -d --name postgres-zh \
     -v postgres_data:/var/lib/postgresql/data \
     -e POSTGRES_PASSWORD=your_password \
     -p 5432:5432 \
     eyeix/postgres-zh:v17
   ```

**使用 Docker Compose**：

```yaml
# docker-compose.yml
services:
  postgres:
    image: eyeix/postgres-zh:v17
    volumes:
      - postgres_data:/var/lib/postgresql/data  # 使用命名卷
    environment:
      POSTGRES_PASSWORD: your_password
    ports:
      - "5432:5432"

volumes:
  postgres_data:
```

#### 2. 扩展安装失败

   ```bash
   # 检查扩展是否正确安装
   docker exec -it postgres-chinese psql -U postgres -c "\dx"
   ```

2. **中文分词不工作**

   ```sql
   -- 检查中文配置
   \dF+ zhparser_zh

   -- 测试分词
   SELECT to_tsvector('zhparser_zh', '这是一个测试');
   ```

3. **性能问题**

   ```sql
   -- 检查索引使用情况
   EXPLAIN ANALYZE SELECT * FROM articles WHERE to_tsvector('zhparser_zh', title) @@ to_tsquery('zhparser_zh', '测试');
   ```

## 📄 许可证

本项目基于 [MIT 许可证](LICENSE) 开源。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request 来改进这个项目！

## 🗺️ 路线图

✅ 支持 PostgreSQL 17 和中文数据处理
