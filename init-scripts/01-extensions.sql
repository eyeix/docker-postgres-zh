-- 启用核心扩展
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS hstore;
CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS unaccent;

-- 启用中文分词扩展
CREATE EXTENSION IF NOT EXISTS zhparser;

-- 为zhparser创建中文全文搜索配置
-- 包含常用的中文词性：名词、动词、形容词、习语、叹词、习用语、简称、时间词
CREATE TEXT SEARCH CONFIGURATION IF NOT EXISTS chinese_zh (PARSER = zhparser);
ALTER TEXT SEARCH CONFIGURATION chinese_zh ADD MAPPING FOR n,v,a,i,e,l,j,t WITH simple;

-- 创建测试表和索引示例
CREATE TABLE IF NOT EXISTS articles (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建全文搜索索引
CREATE INDEX IF NOT EXISTS idx_articles_fts ON articles 
    USING gin(to_tsvector('chinese_zh', title || ' ' || content));
