# 昆仑 Godot 游戏工程

原生 Godot 4.6.3 · 单机 2D 像素 RPG。入口为 `project.godot` → `scenes/main.tscn`。开发从全游戏基础工程向序章、第01—20章推进，不建立独立华山样章。

## 当前可运行范围

- 输入、脚底碰撞、归一化斜向移动、四向临时形象、Y排序与语义场景加载
- 320×180 独立世界 SubViewport，最近邻整数放大，黑边居中；独立高清中文 UI
- JSON 驱动对白、勘查前置、玩家局部选择、记事与幂等场次事务
- 序章五个原场次 + 六个 MQ-00 任务补场的开发流程，可以从神仙度走到江畔辞王
- 有限的镜心拆招教学（准备/冷却/MP/非致命目标）与三架破山弩校准
- 手动/自动双存档槽，版本3跨章格式（严格兼容版本1序章档及版本2章1档）、临时文件原子替换、加载前校验，坏档不覆盖当前状态
- 梁文靖固定 Lv.15，序章不向梁萧成长账发放 XP
- 序章结束后明确进入第01章：10节点、7个开发地图、47个事件步骤，含沙地练字、弹豆、避险/追母路线、两场真实遭遇、画地三招、掘墓刻碑与收犬东行
- 梁萧从 Lv.1 / 0 XP 开始；两场各30 XP、章节285 XP按收据一次发放，章末345 XP / Lv.4。战败重试回到战前，幼犬不是战斗目标

这不是完整游戏，也不是成品序章。地图当前只是按原尺寸元数据搭出的可通行临时路线，不代表完整关卡面积已经制作。人物含人工逐帧像素候选，场景仍为开发占位；没有成品肖像、剧情动作、音乐、音效、配音。任务补场是依据06的简要改编，未达到完整逐场剧本与45分钟序章预算。已有确定性回合内核与第01章成长/遭遇闭环；完整队伍玩法、合招、后续首领、第03—20章仍未接入；`combat_rules.json` 的存在不等于全部规则已有代码实现。

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

扩章应新增章节数据与登记，不把剧情散落进绘制代码；`StoryState` 保留版本1序章校验，`CampaignState` 路由章节、独立角色成长与版本2/3重放校验；进入新章需要显式事务。旧档加载仍停在原序章位置，首次升级保存保留 `.v1.bak` / `.v2.bak`。运行场次ID为语义 snake_case，原 `SC` / `MAP` 保留作带 `source_document` 的引用。详见 `data/source_mapping.md`。

## 字体与美术来源

`assets/fonts/kunlun_ui.ttf` 是 Noto Sans CJK SC（原TTC face 2）的离线UI子集，改名为 Kunlun UI Subset Regular；OFL许可与原版权随 `LICENSE.txt` 分发。子集含当前JSON与脚本使用的字形。新增文字后运行 `python game/tools/build_font.py --source /path/to/NotoSansCJK-Regular.ttc`（仅构建需要 fonttools），重新导入字体，并检查缺字。运行游戏不依赖 Python 或系统中文字体。

当前环境仍由 `world.gd` 显式几何与色值绘制；`assets/pixel_candidate` 为手工定义逐帧人物候选，生成源在 `tools/art`，帧锚点与色板有登记。无AI图像、3D缩图或概念图转像素。现有候选经审图但仍需成品精修；地图可通行不等于最终美术。

## 第01章操作与验证

序章收束页选择“十年后·继续第01章”。地图按任务提示靠近目标后E交互；行进目标必须按箭头经过有序路径点。沙地/墓碑字板用鼠标依次点绿色起点、金色终点，或方向键移动笔尖、Enter落笔/收笔；只写梁、文，靖仍空缺。掘墓需三次交互。战斗先选武学和目标、编排行动，再结算回合；真气与冷却会限制出招，战败可重试。画地三招需观察肩肘、选步位、出掌，错误步位需重新审势。

第01章保存以事件日志和战斗命令重放验证，不接受“胜利=true”作为奖励凭据。正在进行的交锋回到战前检查点；字板未完成的笔画不存档。角色死亡、离开和收犬分别记录；母亲被带往北方，父亲抱子追赶。墓前断刃与铉元剑是不同物件。

在前述XDG环境下另运行：

```sh
godot --headless --path game --script res://tests/test_combat.gd
godot --headless --path game --script res://tests/test_chapter_one.gd
godot --headless --path game --script res://tests/test_chapter_main.gd
godot --headless --path game --script res://tests/test_chapter_world.gd
godot --headless --path game --script res://tests/test_battle_panel.gd
```

2026-10-13集成验证：原476项、战斗134项、章节628项、main/world105项、地图333项、战斗面板7项均0失败。静态校验覆盖四场来源快照SHA、10节点/7地图/47步骤、两场遭遇引用、路径/字板与345 XP预算。真实GUI章1完整路线已到章末345 XP；独立存档/分支审查通过。字板等比修复及独立进程终局读档均实测通过，最终证据见开发计划。

`tests/prepare_chapter_gui.gd` 在隔离XDG数据目录生成由真实模型步骤与战斗结算得到的序章结束档和章1节点档，专供复验，不是游戏中的跳关入口。控制器自动测试通过不等同实际键鼠手感或画面验收。

## 第02章：天机求学

章1结束页可继续章2，不重置梁萧成长或遗物。已接19主节点、11开发地图、两条可选支线和117个主支线事件步骤。章节注册是显式白名单，内容JSON不会自行赋予机关或战斗完成权限。

- 棋坳护恩：依据铁索意图保护伤者，目标是撑过实际敌方行动迎来九如支援，不要求打空高手气血。
- 长亭脱困：侦听、假投诚、制敌窗口、核对解药交换、服药、非致命阻追与撤离分别结算。
- 靖字采用13笔等比字板；练纸学字不会改写章1父墓。影阵要求观察相位、实际站到亮起的脚印，再选对应姿态。
- 九算使用明确标注的简化教学模型，包括九宫八线15、三组二进制与其他演示题。三层提示后的协助逐步执行合法操作并记录assisted，不绕过校验器。第十算先演示发散，劝慰之后主动歇手，不提供假答案。
- R01/K01在首年夜读窗口进入，可暂缓后恢复，也可放弃；隔离前确认截止，未完成记错过，无奖励且不锁主线。K01先在世界记录七处测量，再验算808尺＝80丈8尺。R01奖励只高亮真正正确的构件，K01辅助只增几何参考线。
- 主线新增1095 XP，累计1440/Lv.10；两支线全做累计2090/Lv.12。标准装备替换前阶，不叠加；铜钱250章末一次。观势察机九算后Lv.2，接纳留缺后得九算天资；后章武学没有提前发。

版本3保留经旧验证器检查的章1终态基线，并严格按主线/支线交错的chronology重放。暂停支线会记录经地图边界验证的位置，支持部分拼图进度；字板按完整字提交，未写完的字需重新书写。升级保存保留`.v1.bak`/`.v2.bak`。未知字段、坏目标证明或账本不符均拒绝，失败不覆盖当前状态。战斗未完成时仍回到战前检查点。

附加验证命令（沿用前述XDG目录）：

```sh
godot --headless --path game --script res://tests/test_chapter_two.gd
godot --headless --path game --script res://tests/test_chapter_two_main.gd
godot --headless --path game --script res://tests/test_chapter_two_boundaries.gd
godot --headless --path game --script res://tests/test_chapter_two_combat.gd
godot --headless --path game --script res://tests/test_chapter_puzzles.gd
godot --headless --path game --script res://tests/test_chapter_two_world.gd
```

真实GUI全支线路线已到2090 XP / Lv.12，独立新进程读回同一终档通过；当前5134项常驻回归全部通过，完整覆盖及独立状态审查见开发计划。当前地图、人物和舞台动作仍为开发候选；没有成品音频、完整分镜或2.50小时节奏验收。尚未导出；后续章节未完成。
