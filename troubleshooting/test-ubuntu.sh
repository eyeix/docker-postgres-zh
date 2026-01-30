#!/bin/bash
# PostgreSQL 中文镜像 Ubuntu 环境测试脚本

set -e

echo "=========================================="
echo "PostgreSQL 中文镜像 Ubuntu 环境测试"
echo "=========================================="
echo ""

# 清理之前的测试容器和卷
echo "1. 清理之前的测试环境..."
docker rm -f postgres-test-volume 2>/dev/null || true
docker rm -f postgres-test-dir 2>/dev/null || true
docker volume rm postgres-test-data 2>/dev/null || true
sudo rm -rf /tmp/postgres-test-data 2>/dev/null || true

echo "✓ 清理完成"
echo ""

# 测试 1: 使用命名卷
echo "=========================================="
echo "测试 1: 使用命名卷（推荐方式）"
echo "=========================================="

echo "创建命名卷..."
docker volume create postgres-test-data

echo "启动容器..."
docker run -d \
  --name postgres-test-volume \
  -e POSTGRES_PASSWORD=testpass \
  -e POSTGRES_DB=testdb \
  -v postgres-test-data:/var/lib/postgresql/data \
  -p 5433:5432 \
  eyeix/postgres-zh:v17

echo "等待容器启动..."
sleep 10

echo "检查容器状态..."
if docker ps | grep -q postgres-test-volume; then
    echo "✓ 容器启动成功"

    echo "检查日志..."
    docker logs postgres-test-volume | tail -20

    echo ""
    echo "测试数据库连接..."
    docker exec postgres-test-volume /usr/pgsql/bin/psql -U postgres -d testdb -c "SELECT version();" || {
        echo "✗ 数据库连接失败"
        docker logs postgres-test-volume
        exit 1
    }

    echo "✓ 测试 1 通过"
else
    echo "✗ 容器启动失败"
    docker logs postgres-test-volume
    exit 1
fi

echo ""

# 测试 2: 使用目录挂载
echo "=========================================="
echo "测试 2: 使用目录挂载"
echo "=========================================="

echo "创建测试目录..."
sudo mkdir -p /tmp/postgres-test-data
sudo chmod 777 /tmp/postgres-test-data

echo "启动容器..."
docker run -d \
  --name postgres-test-dir \
  -e POSTGRES_PASSWORD=testpass \
  -e POSTGRES_DB=testdb \
  -v /tmp/postgres-test-data:/var/lib/postgresql/data \
  -p 5434:5432 \
  eyeix/postgres-zh:v17

echo "等待容器启动..."
sleep 10

echo "检查容器状态..."
if docker ps | grep -q postgres-test-dir; then
    echo "✓ 容器启动成功"

    echo "检查日志..."
    docker logs postgres-test-dir | tail -20

    echo ""
    echo "测试数据库连接..."
    docker exec postgres-test-dir /usr/pgsql/bin/psql -U postgres -d testdb -c "SELECT version();" || {
        echo "✗ 数据库连接失败"
        docker logs postgres-test-dir
        exit 1
    }

    echo "✓ 测试 2 通过"
else
    echo "✗ 容器启动失败"
    docker logs postgres-test-dir
    exit 1
fi

echo ""
echo "=========================================="
echo "所有测试通过！"
echo "=========================================="
echo ""
echo "清理测试环境..."
docker rm -f postgres-test-volume postgres-test-dir
docker volume rm postgres-test-data
sudo rm -rf /tmp/postgres-test-data

echo "✓ 测试完成"
