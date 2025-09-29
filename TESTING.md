# PostgreSQL 中文适配镜像测试指南

本文档提供了完整的测试指南，帮助验证 PostgreSQL 中文适配镜像的功能和扩展安装。

## 🚀 快速测试

### 基础功能测试

```bash
# 构建镜像
docker build -t postgres-zh-test .

# 启动容器
docker run --name postgres-test \
  -e POSTGRES_PASSWORD=testpass \
  -d -p 5433:5432 \
  postgres-zh-test

# 等待初始化完成
sleep 20

# 检查容器状态
docker ps | grep postgres-test

# 查看初始化日志
docker logs postgres-test
```

### 扩展安装验证

```bash
# 检查已安装的扩展
docker exec postgres-test /usr/pgsql/bin/psql -U postgres -d postgres -c "\dx"

# 检查中文分词配置
docker exec postgres-test /usr/pgsql/bin/psql -U postgres -d postgres -c "\dF+ chinese_zh"

# 测试中文分词功能
docker exec postgres-test /usr/pgsql/bin/psql -U postgres -d postgres -c "SELECT to_tsvector('chinese_zh', '这是一个中文分词的测试');"
```

## 📋 完整测试脚本

### 环境变量测试

```bash
#!/bin/bash
# 测试所有环境变量组合

echo "构建 Docker 镜像..."
docker build -t postgres-zh-test .

# 测试1: 默认配置
echo "=== 测试1: 默认配置 ==="
docker run --name postgres-test1 -e POSTGRES_PASSWORD=testpass -d -p 5433:5432 postgres-zh-test
sleep 10
echo "检查默认用户和数据库..."
docker exec postgres-test1 /usr/pgsql/bin/psql -U postgres -d postgres -c "SELECT current_user, current_database();"
docker stop postgres-test1 && docker rm postgres-test1

# 测试2: 自定义数据库
echo "=== 测试2: 自定义数据库 ==="
docker run --name postgres-test2 -e POSTGRES_DB=zh-app -e POSTGRES_PASSWORD=testpass -d -p 5433:5432 postgres-zh-test
sleep 10
echo "检查自定义数据库..."
docker exec postgres-test2 /usr/pgsql/bin/psql -U postgres -d zh-app -c "SELECT current_database();"
docker stop postgres-test2 && docker rm postgres-test2

# 测试3: 自定义用户
echo "=== 测试3: 自定义用户 ==="
docker run --name postgres-test3 -e POSTGRES_USER=myuser -e POSTGRES_PASSWORD=testpass -d -p 5433:5432 postgres-zh-test
sleep 10
echo "检查自定义用户..."
docker exec postgres-test3 /usr/pgsql/bin/psql -U myuser -d postgres -c "SELECT current_user;"
docker stop postgres-test3 && docker rm postgres-test3

# 测试4: 自定义用户和数据库
echo "=== 测试4: 自定义用户和数据库 ==="
docker run --name postgres-test4 -e POSTGRES_USER=admin -e POSTGRES_DB=zh_search -e POSTGRES_PASSWORD=testpass -d -p 5433:5432 postgres-zh-test
sleep 10
echo "检查自定义用户和数据库..."
docker exec postgres-test4 /usr/pgsql/bin/psql -U admin -d zh_search -c "SELECT current_user, current_database();"
docker stop postgres-test4 && docker rm postgres-test4

# 测试5: 列出所有数据库和用户
echo "=== 测试5: 数据库和用户列表 ==="
docker run --name postgres-test5 -e POSTGRES_USER=testuser -e POSTGRES_DB=testdb -e POSTGRES_PASSWORD=testpass -d -p 5433:5432 postgres-zh-test
sleep 10
echo "数据库列表:"
docker exec postgres-test5 /usr/pgsql/bin/psql -U testuser -d testdb -c "\l"
echo "用户列表:"
docker exec postgres-test5 /usr/pgsql/bin/psql -U testuser -d testdb -c "\du"
docker stop postgres-test5 && docker rm postgres-test5

echo "所有测试完成！"
```

### 扩展功能测试

```bash
#!/bin/bash
# 测试所有扩展的安装

echo "构建 Docker 镜像..."
docker build -t postgres-zh-test .

echo "启动容器..."
docker run --name postgres-test -e POSTGRES_PASSWORD=testpass -d -p 5433:5432 postgres-zh-test

echo "等待容器启动和初始化..."
sleep 20

echo "检查容器状态..."
docker ps | grep postgres-test

echo "检查容器日志..."
docker logs postgres-test

echo "=== 检查已安装的扩展 ==="
docker exec postgres-test /usr/pgsql/bin/psql -U postgres -d postgres -c "\dx"

echo "=== 检查中文分词配置 ==="
docker exec postgres-test /usr/pgsql/bin/psql -U postgres -d postgres -c "\dF+ chinese_zh"

echo "=== 测试中文分词功能 ==="
docker exec postgres-test /usr/pgsql/bin/psql -U postgres -d postgres -c "SELECT to_tsvector('chinese_zh', '这是一个中文分词的测试');"

echo "=== 测试向量扩展 ==="
docker exec postgres-test /usr/pgsql/bin/psql -U postgres -d postgres -c "SELECT * FROM pg_extension WHERE extname = 'vector';" 2>/dev/null || echo "向量扩展可能不可用"

echo "=== 测试时间序列扩展 ==="
docker exec postgres-test /usr/pgsql/bin/psql -U postgres -d postgres -c "SELECT * FROM pg_extension WHERE extname = 'timescaledb';" 2>/dev/null || echo "时间序列扩展可能不可用"

echo "=== 测试地理空间扩展 ==="
docker exec postgres-test /usr/pgsql/bin/psql -U postgres -d postgres -c "SELECT * FROM pg_extension WHERE extname = 'postgis';" 2>/dev/null || echo "地理空间扩展可能不可用"

echo "=== 测试 AI/向量扩展 ==="
docker exec postgres-test /usr/pgsql/bin/psql -U postgres -d postgres -c "SELECT * FROM pg_extension WHERE extname IN ('vector', 'pg_similarity', 'smlar');" 2>/dev/null || echo "AI/向量扩展可能不可用"

echo "=== 测试全文搜索扩展 ==="
docker exec postgres-test /usr/pgsql/bin/psql -U postgres -d postgres -c "SELECT * FROM pg_extension WHERE extname IN ('pgroonga', 'pg_search', 'pg_tokenizer');" 2>/dev/null || echo "高级全文搜索扩展可能不可用"

echo "=== 测试分析扩展 ==="
docker exec postgres-test /usr/pgsql/bin/psql -U postgres -d postgres -c "SELECT * FROM pg_extension WHERE extname IN ('pg_analytics', 'pg_partman', 'tablefunc');" 2>/dev/null || echo "分析扩展可能不可用"

echo "=== 测试功能扩展 ==="
docker exec postgres-test /usr/pgsql/bin/psql -U postgres -d postgres -c "SELECT * FROM pg_extension WHERE extname IN ('pg_auditor', 'pg_stat_statements');" 2>/dev/null || echo "功能扩展可能不可用"

echo "=== 测试 JSON/GraphQL 扩展 ==="
docker exec postgres-test /usr/pgsql/bin/psql -U postgres -d postgres -c "SELECT * FROM pg_extension WHERE extname IN ('pg_jsonschema', 'pg_graphql');" 2>/dev/null || echo "JSON/GraphQL 扩展可能不可用"

echo "=== 测试分布式扩展 ==="
docker exec postgres-test /usr/pgsql/bin/psql -U postgres -d postgres -c "SELECT * FROM pg_extension WHERE extname = 'citus';" 2>/dev/null || echo "分布式扩展可能不可用"

echo "=== 测试 DuckDB 集成 ==="
docker exec postgres-test /usr/pgsql/bin/psql -U postgres -d postgres -c "SELECT * FROM pg_extension WHERE extname = 'pg_duckdb';" 2>/dev/null || echo "DuckDB 集成可能不可用"

echo "清理测试容器..."
docker stop postgres-test
docker rm postgres-test

echo "测试完成！"
```

## 🧪 功能测试示例

### 中文数据处理测试

```sql
-- 连接到数据库
\c postgres

-- 创建测试表
CREATE TABLE IF NOT EXISTS articles (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建全文搜索索引
CREATE INDEX IF NOT EXISTS idx_articles_fts ON articles
    USING gin(to_tsvector('chinese_zh', title || ' ' || content));

-- 插入测试数据
INSERT INTO articles (title, content) VALUES
('人工智能的发展', '人工智能技术正在快速发展，深度学习、机器学习等技术不断突破。'),
('大模型应用', '大语言模型（LLM）在文本生成、对话系统等领域展现出强大能力。'),
('开源社区', '开源社区推动了数据库和人工智能技术的快速发展。'),
('全文检索实践', '通过 PostgreSQL 的全文检索功能，可以高效地搜索中文内容。'),
('机器学习案例', '机器学习在图像识别、语音处理等场景有广泛应用。'),
('PostgreSQL 扩展', 'pg_trgm 和 zhparser 等扩展增强了数据库的搜索能力。'),
('自然语言处理', 'NLP 技术在文本分析、情感识别等方面有重要作用。'),
('数据分析', '数据分析帮助企业做出更科学的决策。'),
('云计算平台', '云计算为大数据和人工智能提供了强大算力支持。'),
('信息检索', '高效的信息检索系统能够提升用户体验。'),
('智能推荐系统', '推荐系统广泛应用于电商、内容分发等领域。'),
('数据库事务', '事务机制保证了数据库操作的原子性和一致性。'),
('索引优化', '合理的索引设计可以显著提升查询性能。'),
('分布式系统', '分布式架构提升了系统的可扩展性和容错能力。'),
('数据安全', '数据加密和访问控制是保障信息安全的关键措施。'),
('自动化运维', '自动化工具简化了数据库的部署与管理流程。'),
('数据库优化', 'PostgreSQL 是一个功能强大的开源数据库，支持全文搜索和复杂查询。'),
('中文分词技术', '中文分词是自然语言处理的重要技术，zhparser 提供了优秀的中文分词功能。')
ON CONFLICT DO NOTHING;

-- 测试中文全文搜索
SELECT title, content,
       ts_rank(to_tsvector('chinese_zh', title || ' ' || content),
               to_tsquery('chinese_zh', '人工智能')) as rank
FROM articles
WHERE to_tsvector('chinese_zh', title || ' ' || content) @@ to_tsquery('chinese_zh', '人工智能')
ORDER BY rank DESC;

-- 测试分词功能
SELECT to_tsvector('chinese_zh', '这是一个中文分词的测试') as segmented_text;

-- 显示所有可用的全文搜索配置
SELECT cfgname, cfgparser FROM pg_ts_config WHERE cfgname LIKE '%zh%';

-- 显示已安装的扩展
SELECT extname, extversion FROM pg_extension;

-- 使用 pg_trgm 进行模糊搜索
SELECT title, content, similarity(title, '人工智能') as sim
FROM articles
WHERE title % '人工智能' OR content % '人工智能'
ORDER BY sim DESC;
```

### 向量相似度搜索测试

```sql
-- 启用向量扩展
CREATE EXTENSION IF NOT EXISTS vector;

-- 创建向量表
CREATE TABLE embeddings (
    id SERIAL PRIMARY KEY,
    content TEXT,
    embedding vector(1536)
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

### 时间序列数据处理测试

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

### 地理空间数据处理测试

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

## 🔍 故障排除

### 常见问题

1. **扩展安装失败**

   ```bash
   # 检查扩展是否正确安装
   docker exec -it postgres-test /usr/pgsql/bin/psql -U postgres -c "\dx"
   ```

2. **中文分词不工作**

   ```sql
   -- 检查中文配置
   \dF+ chinese_zh

   -- 测试分词
   SELECT to_tsvector('chinese_zh', '这是一个测试');
   ```

3. **性能问题**

   ```sql
   -- 检查索引使用情况
   EXPLAIN ANALYZE SELECT * FROM articles WHERE to_tsvector('chinese_zh', title) @@ to_tsquery('chinese_zh', '测试');
   ```

### 日志检查

```bash
# 查看容器启动日志
docker logs postgres-test

# 查看 PostgreSQL 日志
docker exec postgres-test tail -f /var/lib/postgresql/data/log/postgresql-*.log
```

## 📊 性能基准测试

### 连接性能测试

```bash
# 测试连接性能
time docker exec postgres-test /usr/pgsql/bin/psql -U postgres -d postgres -c "SELECT 1;"
```

### 扩展加载时间测试

```bash
# 测试扩展加载时间
time docker exec postgres-test /usr/pgsql/bin/psql -U postgres -d postgres -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
```

## 🧹 清理测试环境

```bash
# 停止并删除测试容器
docker stop postgres-test
docker rm postgres-test

# 删除测试镜像
docker rmi postgres-zh-test

# 清理所有相关资源
docker system prune -f
```

## 📝 测试报告模板

测试完成后，可以记录以下信息：

- **测试时间**:
- **测试环境**:
- **成功安装的扩展**:
- **失败的扩展**:
- **性能指标**:
- **问题记录**:
- **建议**:

---

**注意**: 某些扩展可能在不同架构上不可用，这是正常现象。测试脚本会显示哪些扩展可用，哪些不可用。
