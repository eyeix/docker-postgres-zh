-- ===========================================
-- PostgreSQL 中文适配镜像扩展初始化脚本
-- ===========================================
-- 此脚本会在 PostgreSQL 启动时自动执行，安装中文数据处理相关扩展
-- 扩展按功能分类和依赖关系顺序安装，确保依赖扩展先于被依赖扩展安装

-- ===========================================
-- 1. 基础数据类型扩展（无依赖）
-- ===========================================
CREATE EXTENSION IF NOT EXISTS hstore;
CREATE EXTENSION IF NOT EXISTS ltree;

-- ===========================================
-- 2. 基础功能扩展（无依赖）
-- ===========================================
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS pg_auditor;

-- ===========================================
-- 3. JSON 和 GraphQL 扩展（无依赖）
-- ===========================================
CREATE EXTENSION IF NOT EXISTS pg_jsonschema;
CREATE EXTENSION IF NOT EXISTS pg_graphql;

-- ===========================================
-- 4. 消息队列扩展（无依赖）
-- ===========================================
CREATE EXTENSION IF NOT EXISTS pgmq;

-- ===========================================
-- 5. 索引扩展（无依赖）
-- ===========================================
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- ===========================================
-- 6. 全文搜索基础扩展（无依赖）
-- ===========================================
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS pg_bigm;
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;
CREATE EXTENSION IF NOT EXISTS unaccent;

-- ===========================================
-- 7. 需要预加载的扩展（无依赖）
-- ===========================================
CREATE EXTENSION IF NOT EXISTS pg_search;
CREATE EXTENSION IF NOT EXISTS pg_tokenizer;
CREATE EXTENSION IF NOT EXISTS pg_duckdb;

-- ===========================================
-- 8. 地理位置基础扩展（必须先安装）
-- ===========================================
CREATE EXTENSION IF NOT EXISTS ip4r;

-- ===========================================
-- 9. 地理位置扩展（依赖 ip4r）
-- ===========================================
DO $$
BEGIN
    BEGIN
        CREATE EXTENSION IF NOT EXISTS postgis;
        RAISE NOTICE 'postgis extension created successfully';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'postgis extension not available: %', SQLERRM;
    END;
    
    BEGIN
        CREATE EXTENSION IF NOT EXISTS geoip;
        RAISE NOTICE 'geoip extension created successfully';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'geoip extension not available: %', SQLERRM;
    END;
END $$;

-- ===========================================
-- 10. 时间序列扩展（容错处理）
-- ===========================================
DO $$
BEGIN
    BEGIN
        CREATE EXTENSION IF NOT EXISTS timescaledb;
        RAISE NOTICE 'timescaledb extension created successfully';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'timescaledb extension not available: %', SQLERRM;
    END;
    
    BEGIN
        CREATE EXTENSION IF NOT EXISTS timescaledb_toolkit;
        RAISE NOTICE 'timescaledb_toolkit extension created successfully';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'timescaledb_toolkit extension not available: %', SQLERRM;
    END;
END $$;

-- ===========================================
-- 11. AI/向量基础扩展（容错处理）
-- ===========================================
DO $$
BEGIN
    BEGIN
        CREATE EXTENSION IF NOT EXISTS vector;
        RAISE NOTICE 'vector extension created successfully';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'vector extension not available: %', SQLERRM;
    END;
END $$;

-- ===========================================
-- 12. AI/向量相似度扩展（依赖 vector）
-- ===========================================
DO $$
BEGIN
    BEGIN
        CREATE EXTENSION IF NOT EXISTS pg_similarity;
        RAISE NOTICE 'pg_similarity extension created successfully';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'pg_similarity extension not available: %', SQLERRM;
    END;
    
    BEGIN
        CREATE EXTENSION IF NOT EXISTS smlar;
        RAISE NOTICE 'smlar extension created successfully';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'smlar extension not available: %', SQLERRM;
    END;
END $$;

-- ===========================================
-- 13. AI/向量高级扩展（依赖 vector）
-- ===========================================
DO $$
BEGIN
    BEGIN
        CREATE EXTENSION IF NOT EXISTS vchord;
        RAISE NOTICE 'vchord extension created successfully';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'vchord extension not available: %', SQLERRM;
    END;
    
    BEGIN
        CREATE EXTENSION IF NOT EXISTS vectorize CASCADE;
        RAISE NOTICE 'vectorize extension created successfully';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'vectorize extension not available: %', SQLERRM;
    END;
END $$;

-- ===========================================
-- 14. AI/向量 BM25 扩展（依赖 vchord + vector）
-- ===========================================
DO $$
BEGIN
    BEGIN
        CREATE EXTENSION IF NOT EXISTS vchord_bm25;
        RAISE NOTICE 'vchord_bm25 extension created successfully';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'vchord_bm25 extension not available: %', SQLERRM;
    END;
END $$;

-- ===========================================
-- 15. 高级全文搜索扩展（容错处理）
-- ===========================================
DO $$
BEGIN
    BEGIN
        CREATE EXTENSION IF NOT EXISTS pgroonga;
        RAISE NOTICE 'pgroonga extension created successfully';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'pgroonga extension not available: %', SQLERRM;
    END;
END $$;

-- ===========================================
-- 16. 中文分词扩展（容错处理）
-- ===========================================
DO $$
BEGIN
    BEGIN
        CREATE EXTENSION IF NOT EXISTS zhparser;
        
        -- 为zhparser创建中文全文搜索配置
        -- 包含常用的中文词性：名词、动词、形容词、习语、叹词、习用语、简称、时间词
        IF NOT EXISTS (SELECT 1 FROM pg_ts_config WHERE cfgname = 'zhparser_zh') THEN
            CREATE TEXT SEARCH CONFIGURATION zhparser_zh (PARSER = zhparser);
            ALTER TEXT SEARCH CONFIGURATION zhparser_zh ADD MAPPING FOR n,v,a,i,e,l,j,t WITH simple;
        END IF;
        
        RAISE NOTICE 'zhparser extension and zhparser_zh configuration created successfully';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'zhparser extension not available for this architecture: %', SQLERRM;
    END;
END $$;

-- ===========================================
-- 17. 分析能力扩展（无依赖）
-- ===========================================
CREATE EXTENSION IF NOT EXISTS pg_analytics;
CREATE EXTENSION IF NOT EXISTS pg_partman;
CREATE EXTENSION IF NOT EXISTS pg_duckdb;
CREATE EXTENSION IF NOT EXISTS citus;
CREATE EXTENSION IF NOT EXISTS tablefunc;

-- ===========================================
-- 18. 显示已安装的扩展信息
-- ===========================================
DO $$
DECLARE
    ext_record RECORD;
    total_count INTEGER := 0;
BEGIN
    RAISE NOTICE '=== PostgreSQL 中文适配镜像扩展状态 ===';
    
    FOR ext_record IN 
        SELECT extname, extversion 
        FROM pg_extension 
        ORDER BY extname
    LOOP
        RAISE NOTICE '扩展: % (版本: %)', ext_record.extname, ext_record.extversion;
        total_count := total_count + 1;
    END LOOP;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE '总计安装扩展数量: %', total_count;
    RAISE NOTICE '========================================';
END $$;