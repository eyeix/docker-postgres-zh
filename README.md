# Docker PostgreSQL 中文全文搜索镜像

这是一个基于 PostgreSQL 16 的 Docker 镜像，预装了中文全文搜索功能和相关扩展，特别适用于中文应用开发。

## 功能特性

### 🚀 核心功能

- **PostgreSQL 16**: 基于官方 PostgreSQL 16 镜像
- **中文分词支持**: 集成 zhparser 中文分词器
- **全文搜索**: 支持中文全文搜索和模糊匹配
- **扩展丰富**: 预装常用 PostgreSQL 扩展

### 📦 预装扩展

#### 中文分词扩展

- **zhparser**: 基于 SCWS 的中文分词器

#### 全文搜索扩展

- **pg_trgm**: 三元组匹配，支持模糊搜索
- **unaccent**: 去除重音符号

#### 其他实用扩展

- **hstore**: 键值对存储
- **btree_gist**: B-tree 索引支持
- **pg_stat_statements**: 查询性能统计

## 快速开始

### 使用 Docker 运行

```bash
# 拉取镜像
docker pull riccoxie/postgres-zh:v16

# 运行容器
docker run -d \
  --name postgres-zh \
  -e POSTGRES_DB=zh-test \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=your_password \
  -p 5432:5432 \
  riccoxie/postgres-zh:v16
```

### 使用 Docker Compose

```yaml
version: '3.8'
services:
  postgres:
    image: riccoxie/postgres-zh:v16
    container_name: postgres-zh
    environment:
      POSTGRES_DB: zh-test
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: your_password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  postgres_data:
```

## 中文全文搜索使用示例

### 1. 连接数据库并创建测试表

```sql
-- 连接到数据库
\c zh-test

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

### 2. 创建全文搜索索引

```sql
-- 使用中文配置创建全文搜索索引
CREATE INDEX idx_articles_fts ON articles 
    USING gin(to_tsvector('chinese_zh', title || ' ' || content));
```

### 3. 执行中文全文搜索

```sql
-- 搜索包含"人工智能"的文章
SELECT title, content, 
       ts_rank(to_tsvector('chinese_zh', title || ' ' || content), 
               to_tsquery('chinese_zh', '人工智能')) as rank
    FROM articles
WHERE to_tsvector('chinese_zh', title || ' ' || content) @@ to_tsquery('chinese_zh', '人工智能')
ORDER BY rank DESC;

-- 使用 pg_trgm 进行模糊搜索
SELECT title, content, similarity(title, '人工智能') as sim
FROM articles 
WHERE title % '人工智能' OR content % '人工智能'
ORDER BY sim DESC;
```

### 4. 高级中文分词功能

```sql
-- zhparser 支持词性标注
SELECT to_tsvector('chinese_zh', '这是一个中文分词的测试');

-- 创建复合索引提升搜索性能
CREATE INDEX idx_articles_combined ON articles 
    USING gin(to_tsvector('chinese_zh', title || ' ' || content));
```

## 配置说明

### 环境变量

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `POSTGRES_DB` | `postgres` | 默认数据库名 |
| `POSTGRES_USER` | `postgres` | 数据库用户名 |
| `POSTGRES_PASSWORD` | - | 数据库密码（必需） |
| `POSTGRES_INITDB_ARGS` | - | 初始化参数 |

## 开发指南

### 构建镜像

```bash
# 克隆仓库
git clone https://github.com/riccox/docker-postgres-zh.git
cd docker-postgres-zh

# 构建镜像
docker build -t riccoxie/postgres-zh .
```

### 本地开发

```bash
# 运行开发环境
docker run -it --rm \
  -e POSTGRES_PASSWORD=dev_password \
  -p 5432:5432 \
  -v $(pwd)/script:/docker-entrypoint-initdb.d \
  riccoxie/postgres-zh:v16
```

## 性能优化建议

### 1. 索引优化

- 为经常搜索的字段创建 GIN 索引
- 使用 `pg_trgm` 扩展进行模糊搜索和相似度匹配

### 2. 查询优化

- 使用 `ts_rank()` 函数进行相关性排序
- 合理使用 `LIMIT` 限制结果集大小
- 避免在 `WHERE` 子句中使用函数

### 3. 配置调优

```sql
-- 调整全文搜索相关参数
SET default_text_search_config = 'chinese_zh';
SET pg_trgm.similarity_threshold = 0.3;
```

## 故障排除

### 常见问题

1. **扩展安装失败**

   ```bash
   # 检查扩展是否正确安装
   docker exec -it postgres-chinese psql -U postgres -c "\dx"
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

## 许可证

本项目基于 [MIT 许可证](LICENSE) 开源。

## 贡献

欢迎提交 Issue 和 Pull Request 来改进这个项目！

## 路线图

✅ 支持 PostgreSQL 16 和中文全文搜索
