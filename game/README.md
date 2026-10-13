# 昆仑 Godot 基础工程

原生 Godot 4.6.3 · 单机 2D 像素 RPG。入口为 `project.godot` → `scenes/main.tscn`。开发从全游戏基础工程向序章、第01—20章推进，不建立独立华山样章。

## 当前可运行范围

- 输入、脚底碰撞、归一化斜向移动、四向临时形象、Y排序与语义场景加载
- 320×180 独立世界 SubViewport，最近邻整数放大，黑边居中；独立高清中文 UI
- JSON 驱动对白、勘查前置、玩家局部选择、记事与幂等场次事务
- 序章五个原场次 + 六个 MQ-00 任务补场的开发流程，可以从神仙度走到江畔辞王
- 有限的镜心拆招教学（准备/冷却/MP/非致命目标）与三架破山弩校准
- 手动/自动双存档槽，版本1格式、临时文件原子替换、加载前校验，坏档不覆盖当前状态
- 梁文靖固定 Lv.15，序章不向梁萧成长账发放 XP

这不是完整游戏，也不是成品序章。地图当前只是按原尺寸元数据搭出的可通行临时路线，不代表完整关卡面积已经制作。人物、场景均为代码逐像素定义的开发占位；没有成品肖像、剧情动作、音乐、音效、配音。任务补场是依据06的简要改编，未达到完整逐场剧本与45分钟序章预算。完整回合战斗、同伴护卫、合招、首领、80级成长运行系统与第01—20章均待实现；`combat_rules.json` 的存在不等于全部规则已有代码实现。

## 启动

安装 Godot 4.6.3（标准版，无需 .NET），在编辑器导入本目录的 `project.godot`，按 F6/F5，或从仓库根运行：

```sh
godot --path game
```

Linux 受限云环境必须给 Godot 可写的数据、配置和缓存目录：

```sh
mkdir -p /tmp/kunlun-cache /tmp/kunlun-data /tmp/kunlun-config
XDG_CACHE_HOME=/tmp/kunlun-cache XDG_DATA_HOME=/tmp/kunlun-data XDG_CONFIG_HOME=/tmp/kunlun-config godot --path game
```

普通桌面用户无需这些环境变量。存档位于 Godot `user://saves/`，`manual.json` 与 `auto.json` 独立；Linux 默认在用户应用数据目录，设置 `XDG_DATA_HOME` 后跟随该目录。自动存档发生在完整场次事务提交之后。标题的“重新开始”需二次确认，不删除手动存档。正在对白、抉择、战斗或机关时不能中途存档；先取消返回探索，可保存上一个完整事务及当前勘查记录。

操作：WASD / 方向键行走，E / 空格调查或继续对白，J 记事，Esc 菜单 / 安全退出对白，F5 手动保存，F9 读手动档。按钮支持鼠标、Tab 与 Enter；长菜单/记事及对白正文可滚动。选择与教学不会被“略过对白”自动完成。

首段：开始行旅 → 向右靠近华服死者 → E收敛衣冠 → 阅读或略过到选择 → 选择回应 → 确认继续前行。客栈需先查三处痕迹：左侧墨画、右侧旧弓、再右侧脚印，才可与白朴推进。

## 验证

从仓库根运行：

```sh
python game/tools/validate_data.py
mkdir -p /tmp/kunlun-cache /tmp/kunlun-test-data /tmp/kunlun-config
export XDG_CACHE_HOME=/tmp/kunlun-cache
export XDG_DATA_HOME=/tmp/kunlun-test-data
export XDG_CONFIG_HOME=/tmp/kunlun-config
godot --headless --path game --editor --import --quit
godot --headless --path game --script res://tests/run_tests.gd
godot --headless --path game --quit-after 120
```

使用独立测试数据目录，避免测试污染个人存档。运行测试需先执行 import，令干净检出生成脚本类型缓存与字体导入。测试失败时引擎退出非零；Godot 编辑器某些脚本解析错误仍可能退出0，因此还须检查日志中的 `SCRIPT ERROR` / `ERROR`。

`validate_data.py` 核对场次ID唯一、五个来源场次、在场发言者、分支反馈、调查引用、0 XP及战斗规则副本逐字一致。`run_tests.gd` 覆盖两类分支完整流程、重复/过期提交、调查前置、机关门槛、JSON/磁盘往返、损坏/未来版本/伪造进度、教学冷却与回气、实际场景树全部11节点推进、跳过/取消输入恢复、终态返回和1366×768整数居中。

这些测试不等同实机手感、完整战斗或导出构建验收。桌面图形检查与更深内容制作另外记录。

## 模块与扩展接口

| 路径 | 职责 |
|---|---|
| `data/prologue.json` | 有来源命名空间的场次、角色、对白、抉择、任务步骤与勘查 |
| `data/combat_rules.json` | 当前策划规则原样副本，不可与V3双向各自维护 |
| `scripts/story_state.gd` | 纯数据事务与恢复校验；场次ID即幂等键 |
| `scripts/save_store.gd` | 保存/读取与原子文件替换，拒绝未知版本 |
| `scripts/world.gd` | 临时地图绘制、NPC、交互目标、相机 |
| `scripts/player.gd` / `pixel_actor.gd` | 脚底物理、可替换的四向开发形象 |
| `scripts/training_battle.gd` | 有限教学规则，不能用作完整战斗引擎 |
| `scripts/main.gd` | 输入路由、独立高清UI、对白/选择/机关表现 |

扩章应新增章节数据与登记，不把剧情散落进绘制代码；当前 `StoryState` 仅接受序章schema，下一章须显式扩展状态与迁移，不能悄悄把第01章载入旧存档。运行场次ID为语义 snake_case，原 `SC` / `MAP` 保留作带 `source_document` 的引用。详见 `data/source_mapping.md`。

## 字体与美术来源

`assets/fonts/kunlun_ui.ttf` 是 Noto Sans CJK SC（原TTC face 2）的离线UI子集，改名为 Kunlun UI Subset Regular；OFL许可与原版权随 `LICENSE.txt` 分发。子集含当前JSON与脚本使用的字形。新增文字后运行 `python game/tools/build_font.py --source /path/to/NotoSansCJK-Regular.ttc`（仅构建需要 fonttools），重新导入字体，并检查缺字。运行游戏不依赖 Python 或系统中文字体。

所有当前环境/人物临时像素由 `world.gd` 和 `pixel_actor.gd` 显式几何与色值绘制，不使用AI图像、3D缩图或华山概念图。它们用于检验基础工程，后续须替换为按08逐帧制作并验收的正式素材。
