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
SELECT extname, extversion FROM pg_extension;
