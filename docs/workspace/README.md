# V3 工作目录迁移记录

2026 年 10 月 13 日完成 16 次路径迁移，共整理 183 个文件，并验证原位置保留的 8 个 IDE 配置与概念图文件。迁移前后逐文件比较长度与 SHA256，全部一致；V3 的九份原稿保持原始字节。

| 原位置 | 当前位置 |
| --- | --- |
| `策划工作/v3_详细设定与剧本` | `docs/design/v3` |
| `策划工作` 下的阅读报告与改编建议 | `docs/reference/reading_reports` |
| 根目录 `昆仑.txt` | `references/novel/昆仑.txt` |
| V1 与 V2 稿件及旧排版脚本 | `archive/design_history/v1` 与 `v2` |
| 三处逐页预览目录 | `archive/preview_cache` |
| V1 与 V2 PDF 和 HTML | `archive/exports/v1` 与 `v2` |

当前 V3 PDF 与 HTML 继续放在 `output/pdf`。新增审阅、80 级草案、复算数据与游戏工程预留目录的入口见根目录 [README](../../README.md)。

[完整迁移清单](v3_workspace_move_manifest_2026-10-13.csv) 记录每个文件的原路径、新路径、长度和原始 SHA256；[完整性核验结果](v3_workspace_integrity_2026-10-13.json) 记录核验状态。如需恢复旧布局，可按清单把 `Destination` 移回 `Source`，先检查原位置不存在新文件，避免覆盖后来修改。

[整理脚本](../../tools/workspace/organize_v3_workspace.ps1) 只用于本次迁移，不作为日常构建或定期清理任务。整理保留历史文件，没有删除旧稿或预览图。
