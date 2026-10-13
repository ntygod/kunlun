# 昆仑像素 RPG 工作目录

当前策划基准为 V3。开始开发前先处理 [V3 审阅报告](docs/reviews/v3_numeric_review.md) 中的技能解锁、行动时序、续航和资源编号问题。[80 级成长方案](docs/design/proposals/level_80_proposal.md) 是保留原战力终点的草案，尚未替换 V3 的 40 级设定。

仓库：[ntygod/kunlun](https://github.com/ntygod/kunlun)，主分支为 `main`。开发从完整游戏的基础工程开始，随后从序章按章节推进，取消独立可玩样章作为前置步骤。

## 常用入口

| 内容 | 位置 |
| --- | --- |
| V3 八个分模块与合并稿 | [docs/design/v3](docs/design/v3/) |
| 数值与一致性审阅 | [docs/reviews/v3_numeric_review.md](docs/reviews/v3_numeric_review.md) |
| 80 级方案草案 | [docs/design/proposals/level_80_proposal.md](docs/design/proposals/level_80_proposal.md) |
| 属性、经验、技能引用和地图面积复算 | [docs/reviews/v3_numeric_data](docs/reviews/v3_numeric_data/) |
| 原著及阅读报告 | [references/novel](references/novel/)、[docs/reference/reading_reports](docs/reference/reading_reports/) |
| 华山故居概念图与提示词 | [assets/concepts](assets/concepts/) |
| 游戏工程预留目录 | [game](game/) |
| 当前 V3 的 PDF 与 HTML | [output/pdf](output/pdf/) |
| 旧稿、旧导出和预览缓存 | [archive](archive/) |
| 本次迁移记录 | [docs/workspace](docs/workspace/) |

```text
novel/
  docs/
    design/v3/             当前用户策划原稿
    design/proposals/      待纳入正式策划的方案
    reviews/               审阅与复算结果
    reference/reading_reports/
    workspace/             目录迁移与完整性记录
  references/novel/        原著文本，保持 GBK 编码
  game/                    scenes、scripts、data、assets
  assets/concepts/         概念图，不直接作为像素成品
  tools/balance/           策划数值复算
  tools/workspace/         本次目录整理脚本
  output/pdf/              当前版本导出
  archive/                 历史稿与预览缓存
```

## 策划与数据使用约定

维护时以 V3 八个分模块为编辑来源，合并稿、HTML 和 PDF 作为同版阅读快照。原稿本次只移动位置，保留全部内容；以后修改分模块时同步更新阅读快照，避免把合并稿再次作为另一套独立来源。

`game/data` 只放已明确结算口径的运行数据。审阅用 CSV 和 80 级草案先保留在 `docs`，不自动当作正式数值。地图、动作、台词和技能在进入程序前先统一 ID 映射。

先建立 Godot 工程，实现输入、场景加载、角色移动与交互，再接入对白、任务、存档和回合制战斗。剧情内容从序章开始逐章制作，华山故居作为第 06 章内容正常实现。

原著 `references/novel/昆仑.txt` 为 GBK，读取时明确指定编码。现有 Markdown 和新工具文件使用 UTF-8。`.idea` 为既有 IDE 配置。

## 复算命令

在工作目录使用 Python 运行：

```powershell
python tools/balance/audit_v3.py --design-dir docs/design/v3 --out-dir docs/reviews/v3_numeric_data
```

脚本读取策划并输出检查结果，不改写策划原文。它检查表格算术和部分引用，战斗体验仍需原型试玩。历史排版脚本包含旧绝对路径，留在归档中，不作为当前构建入口。
