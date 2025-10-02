# PostgreSQL 中文适配镜像扩展说明

本文档详细说明了 PostgreSQL 中文适配镜像中安装的所有扩展，包括功能分类、依赖关系和安装顺序。

## 📋 扩展分类

### 1. 基础数据类型扩展（无依赖）

- **ltree** - 层次结构数据存储

### 2. 基础功能扩展（无依赖）

- **pg_stat_statements** - 查询性能统计

### 3. JSON 和 GraphQL 扩展（无依赖）

- **pg_jsonschema** - JSON Schema 验证
- **pg_graphql** - GraphQL 支持

### 4. 消息队列扩展（无依赖）

- **pgmq** - 消息队列

### 5. 索引扩展（无依赖）

- **btree_gist** - B-tree GiST 索引

### 6. 全文搜索基础扩展（无依赖）

- **pg_trgm** - 三元组相似度搜索（⚠️ 对中文文本支持有限，建议使用 zhparser 进行中文搜索）
- **fuzzystrmatch** - 模糊字符串匹配
- **unaccent** - 去除重音符号

### 7. 需要预加载的扩展（无依赖）

- **pg_duckdb** - DuckDB 集成

### 8. 地理位置扩展（无依赖）

- **postgis** - 地理空间数据处理

### 9. 时间序列扩展

- **timescaledb** - 时间序列数据库（基础）

### 10. AI/向量基础扩展

- **vector** - 向量数据类型（基础）

### 11. AI/向量相似度扩展（依赖 vector）

- **smlar** - 相似度匹配

### 12. AI/向量高级扩展（依赖 vector）

- **vchord** - 向量和弦搜索（依赖 vector）

### 13. 高级全文搜索扩展（无依赖）

- **pgroonga** - 基于 Groonga 的高性能全文搜索引擎
  - 原生支持中文、日文等多字节字符
  - 提供比传统 PostgreSQL 全文搜索更快的性能
  - 支持前缀搜索、模糊搜索、正则表达式等高级功能
  - 内置搜索结果高亮功能
  - 实时索引更新，无需重建

### 14. 中文分词扩展（无依赖）

- **zhparser** - 中文分词器

### 15. 分析能力扩展（无依赖）

- **pg_analytics** - 分析功能
- **pg_partman** - 分区管理
- **pg_duckdb** - DuckDB 集成
- **tablefunc** - 表函数

## 🔗 依赖关系图

```text
基础扩展
├── 数据类型: ltree
├── 功能: pg_stat_statements
├── JSON/GraphQL: pg_jsonschema, pg_graphql
├── 消息队列: pgmq
├── 索引: btree_gist
└── 全文搜索: pg_trgm, fuzzystrmatch, unaccent

地理位置扩展
└── postgis (独立)

时间序列扩展
└── timescaledb (基础)

AI/向量扩展
├── vector (基础)
│   ├── smlar (依赖 vector)
│   └── vchord (依赖 vector)

高级扩展
├── pgroonga (独立)
├── zhparser (独立)
└── 分析: pg_analytics, pg_partman, tablefunc
```

## 📦 安装顺序

### Dockerfile 中的安装顺序

1. **基础数据类型扩展** → 无依赖
2. **基础功能扩展** → 无依赖
3. **JSON/GraphQL 扩展** → 无依赖
4. **消息队列扩展** → 无依赖
5. **索引扩展** → 无依赖
6. **全文搜索基础扩展** → 无依赖
7. **地理位置扩展** → 无依赖
8. **时间序列扩展** → timescaledb 必须先安装
9. **AI/向量基础扩展** → vector 必须先安装
10. **AI/向量相似度扩展** → 依赖 vector
11. **AI/向量高级扩展** → 依赖 vector
12. **高级全文搜索扩展** → 无依赖
13. **分析能力扩展** → 无依赖

### 初始化脚本中的启用顺序

1. **基础扩展** → 直接 CREATE EXTENSION
2. **依赖扩展** → 按依赖顺序 CREATE EXTENSION
3. **容错扩展** → 使用 DO $$ BEGIN ... EXCEPTION ... END $$ 处理

## 🚀 使用说明

### 环境变量

- `POSTGRES_USER` - 数据库用户（默认：postgres）
- `POSTGRES_PASSWORD` - 数据库密码（默认：postgres）
- `POSTGRES_DB` - 数据库名称（默认：postgres）

### 预加载扩展

以下扩展需要在 `shared_preload_libraries` 中预加载：

- timescaledb
- pg_duckdb
- vchord

### 中文全文搜索配置

#### zhparser 配置

如果 zhparser 扩展可用，会自动创建 `zhparser_zh` 全文搜索配置，支持以下中文词性：

- n (名词)
- v (动词)
- a (形容词)
- i (习语)
- e (叹词)
- l (习用语)
- j (简称)
- t (时间词)

#### PGroonga 配置

PGroonga 扩展无需额外配置即可使用，主要特性：

- **自动分词**：自动处理中文、日文等多字节字符
- **多种操作符**：
  - `&@~`：全文搜索（支持布尔查询）
  - `&^~`：前缀搜索
  - `&@*`：相似度搜索
  - `&@~|`：OR 搜索
- **内置函数**：
  - `pgroonga_score(tableoid, ctid)`：计算相关性得分
    - `tableoid`：表对象 ID（PostgreSQL 系统列）
    - `ctid`：行物理位置（PostgreSQL 系统列，格式如 `(0,1)`）
    - 返回值：分数越高表示匹配度越好，用于结果排序
    - 注意：只能在包含 PGroonga 搜索条件的查询中使用
  - `pgroonga_highlight_html(text, keywords[])`：HTML 高亮显示搜索关键词
  - `pgroonga_query_extract_keywords(query)`：从查询中提取搜索关键词
- **索引类型**：支持 GIN 和 GiST 索引

**使用示例：**

```sql
-- 创建索引
CREATE INDEX idx_search ON articles USING pgroonga ((ARRAY[title, content]));

-- 基本搜索（带评分）
SELECT title, pgroonga_score(tableoid, ctid) as score
FROM articles
WHERE ARRAY[title, content] &@~ '搜索词'
ORDER BY score DESC;

-- 搜索结果高亮
SELECT title, 
       pgroonga_highlight_html(content, pgroonga_query_extract_keywords('搜索词'))
FROM articles
WHERE ARRAY[title, content] &@~ '搜索词';
```

## 🔧 故障排除

### 常见问题

1. **扩展安装失败** - 检查依赖关系是否正确
2. **预加载扩展失败** - 确保扩展在 shared_preload_libraries 中
3. **中文分词失败** - 检查 zhparser 是否支持当前架构

### 调试方法

```sql
-- 查看已安装的扩展
SELECT extname, extversion FROM pg_extension ORDER BY extname;

-- 查看预加载的扩展
SHOW shared_preload_libraries;

-- 查看扩展状态
SELECT * FROM pg_available_extensions WHERE name LIKE '%vector%';
```
