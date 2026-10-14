# 昆仑像素 RPG 工作目录

当前策划基准为 V3，第 07 模块采用保留原战力终点的 80 级成长体系。护卫、行动时序、合招授权、续航与章节经验已统一为 `combat_rules_v1`，变更与检查见 [战斗规则收尾复核](docs/reviews/v3_combat_rules_review.md)。成长公式见 [80 级数值复核](docs/reviews/v3_level80_review.md)。已建立 Godot 4.6.3 基础工程、序章开发流程与第01—06章事件/遭遇/机关开发闭环（第05—06章限定功能与自然GUI已验，第06章仅本地冻结；战斗节奏、动线与候选演出仍需打磨），运行与范围见 [游戏说明](game/README.md)。这不是完整游戏或成品序章；资源编号与地图面积问题仍按 [初稿审阅](docs/reviews/v3_numeric_review.md) 处理。

仓库：[ntygod/kunlun](https://github.com/ntygod/kunlun)，主分支为 `main`。开发从完整游戏的基础工程开始，随后从序章按章节推进，取消独立可玩样章作为前置步骤。

## 常用入口

| 内容 | 位置 |
| --- | --- |
| V3 八个分模块与合并稿 | [docs/design/v3](docs/design/v3/) |
| 80 级数值复核 | [docs/reviews/v3_level80_review.md](docs/reviews/v3_level80_review.md) |
| 战斗统一规则与验证 | [复核报告](docs/reviews/v3_combat_rules_review.md)、[规则参数](docs/design/v3/combat_rules.json) |
| 初稿数值与一致性审阅 | [docs/reviews/v3_numeric_review.md](docs/reviews/v3_numeric_review.md) |
| 80 级方案与经验预算 | [docs/design/proposals/level_80_proposal.md](docs/design/proposals/level_80_proposal.md) |
| 属性、经验、技能引用和地图面积复算 | [docs/reviews/v3_numeric_data](docs/reviews/v3_numeric_data/) |
| 原著及阅读报告 | [references/novel](references/novel/)、[docs/reference/reading_reports](docs/reference/reading_reports/) |
| 华山故居概念图与提示词 | [assets/concepts](assets/concepts/) |
| Godot 工程与运行说明 | [game](game/) |
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

维护时以 V3 八个分模块为编辑来源，合并稿、HTML 和 PDF 作为同版阅读快照。修改分模块时同步更新合并稿和阅读快照，避免把合并稿再次作为另一套独立来源。

`game/data` 只放已明确结算口径的运行数据。审阅用 CSV 保留在 `docs`，作为正式策划的复算参考；进入游戏时从已核对的策划建立运行数据。地图、动作、台词和技能在进入程序前先统一 ID 映射。

现已建立输入、场景加载、角色移动与交互、数据对白、任务及版本化存档基础，并接入有限的序章教学与机关流程。确定性回合内核已接入第01章两场遭遇，版本化章节状态与梁萧成长已运行；第03章集成验证进行中，完整队伍玩法及第04—20章继续逐章制作，华山故居作为第 06 章内容正常实现。整体排期与未完成项见 [开发计划](docs/development/development-plan.md)。

原著 `references/novel/昆仑.txt` 为 GBK，读取时明确指定编码。现有 Markdown 和新工具文件使用 UTF-8。`.idea` 为既有 IDE 配置。

## 复算命令

在工作目录使用 Python 运行：

```powershell
python tools/balance/audit_v3.py --design-dir docs/design/v3 --out-dir docs/reviews/v3_numeric_data
python tools/balance/verify_combat_rules.py --design-dir docs/design/v3 --out-dir docs/reviews/v3_numeric_data
```

脚本读取策划并输出检查结果，不改写策划原文。前者检查表格算术和部分引用；后者核对规则参数、任务授权与经验账，并验证有限的结算边界场景。它们不代替游戏引擎和完整战斗试玩。

同步合并稿后，可使用 `python tools/design/build_v3.py` 更新当前 HTML 与 PDF，需要 ReportLab、pypdf 和 Windows 微软雅黑字体。历史排版脚本包含旧绝对路径，留在归档中，不作为当前构建入口。
