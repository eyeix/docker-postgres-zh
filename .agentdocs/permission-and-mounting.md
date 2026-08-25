# 挂载权限与编码

涉及数据目录挂载、entrypoint、权限问题排查时必读。

## 当前方案：完全依赖官方 entrypoint

镜像**没有自定义 `docker-entrypoint.sh`**。`Dockerfile` 直接继承 `postgres:17` 的 entrypoint 与 `ENTRYPOINT` 指令，由官方脚本处理数据目录初始化、权限调整与用户降权。

这是 2026-01-31 迁移到官方镜像后的最终形态（提交 `7e31f90`）。官方 entrypoint 已正确处理挂载权限，包括命名卷、宿主机目录挂载以及 NFS 等网络文件系统。

## 历史背景：不要重新引入自定义 entrypoint

早期版本自建了 entrypoint，用 `groupmod`/`usermod` 动态改写容器内 postgres 用户的 UID/GID 去匹配挂载目录所有者。该方案已废弃，原因是官方镜像本身就解决了同一问题，自定义脚本只是重复实现且增加维护面。

**约束**：遇到权限报错时不要新增 entrypoint 或权限修复脚本。先按下面的排查路径确认是宿主机侧配置问题，还是官方 entrypoint 的已知行为。

## 排查路径

1. 优先建议命名卷（`docker volume create`），可移植性与性能都更好，且绕开宿主机 UID/GID 差异
2. 目录挂载报权限错误时，检查宿主机目录所有者与权限位，必要时在宿主机侧调整
3. NFS / 云存储挂载需在挂载参数上放开权限（例如 NFS 导出侧 `no_root_squash`）
4. 不需要 `--privileged`；如果某个方案只能靠特权模式跑通，说明方向错了

用户向的完整排查步骤见 `troubleshooting/TROUBLESHOOTING.md`。

## 编码

数据库以 UTF-8 初始化。镜像额外生成 `zh_CN.UTF-8` locale。中文分词与部分扩展依赖正确编码，改动 locale 或 initdb 参数前需确认不破坏 `zhparser` 与 `pgroonga`。
