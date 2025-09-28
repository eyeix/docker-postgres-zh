-- 测试示例脚本
-- 此脚本包含测试数据和示例，仅用于开发和测试环境
-- 使用方法：连接到数据库后执行 \i test-examples.sql

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
('数据库优化', 'PostgreSQL 是一个功能强大的开源数据库，支持全文搜索和复杂查询。'),
('中文分词技术', '中文分词是自然语言处理的重要技术，zhparser 提供了优秀的中文分词功能。')
ON CONFLICT DO NOTHING;

-- 测试查询示例
-- 以下查询仅用于验证功能，实际使用时请根据需求修改

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
SELECT extname, extversion FROM pg_extension WHERE extname IN ('zhparser', 'pg_trgm', 'hstore');
