# 更新日志

## 2025-09-29

### 🚀 重大更新：Pig 包管理器重构

#### ✨ 新增功能

- **Pig 包管理器集成**：使用 [Pig](https://pig.pgsty.com/zh/start/) 统一管理 PostgreSQL 内核和扩展
- **多架构支持**：支持 linux/amd64 和 linux/arm64 架构
- **容错安装**：智能处理安装失败的情况
- **专业扩展集合**：预装 30+ 个专业 PostgreSQL 扩展

#### 🔧 技术架构

##### 构建过程优化

- **之前**：手动下载、编译 SCWS 库和 zhparser 扩展
- **现在**：使用 Pig 包管理器统一管理（基于 Ubuntu 24.04）
- **优势**：构建时间更短，维护更简单，环境更统一

##### 环境管理

- **统一管理**：PostgreSQL 内核和扩展都通过 Pig 包管理器管理
- **自动依赖**：Pig 自动处理内核和扩展的依赖关系
- **版本控制**：支持 PostgreSQL 内核和扩展的版本管理

##### 项目结构简化

- **删除文件**：移除复杂的配置文件和多余脚本
- **保留核心**：只保留必要的构建和初始化文件
- **清晰结构**：项目文件结构更加简洁明了

#### 📦 扩展管理

```bash
# 查看已安装扩展
docker exec -it postgres-zh pig ext list

# 安装新扩展
docker exec -it postgres-zh pig ext install <extension_name> -y

# 更新扩展
docker exec -it postgres-zh pig ext update <extension_name> -y

# 搜索可用扩展
docker exec -it postgres-zh pig ext search <extension_name>
```

#### 🏗️ 架构兼容性

| 架构 | PostgreSQL | zhparser | 其他扩展 | 状态 |
|------|------------|----------|----------|------|
| linux/amd64 | ✅ 完整支持 | ✅ 完整支持 | ✅ 完整支持 | 🟢 推荐 |
| linux/arm64 | ✅ 完整支持 | ✅ 完整支持 | ✅ 完整支持 | 🟢 推荐 |

**注意**：由于 Pig 包管理器的限制，目前只支持 x86_64 和 aarch64 架构。

#### 🎯 优势总结

- **🎯 简化维护**：统一的 PostgreSQL 环境管理，减少手动配置
- **🔒 提高可靠性**：自动处理内核和扩展依赖关系，减少构建失败
- **⚡ 增强灵活性**：支持动态内核和扩展安装更新
- **🛡️ 更好的错误处理**：智能回退机制，提高构建成功率
- **📦 标准化管理**：使用业界标准的 Pig 包管理器

---

## 2025-09-28

### 技术特性

- 基于 PostgreSQL 16 的 Docker 镜像
- 支持中文全文搜索功能
- 集成 zhparser 中文分词器
- 多架构支持（7 种 CPU 架构）
- 预装常用 PostgreSQL 扩展
