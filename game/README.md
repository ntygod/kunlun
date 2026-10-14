# 昆仑 Godot 游戏工程

原生 Godot 4.6.3 · 单机 2D 像素 RPG。入口为 `project.godot` → `scenes/main.tscn`。开发从全游戏基础工程向序章、第01—20章推进，不建立独立华山样章。

## 当前可运行范围

- 输入、脚底碰撞、归一化斜向移动、四向临时形象、Y排序与语义场景加载
- 320×180 独立世界 SubViewport，最近邻整数放大，黑边居中；独立高清中文 UI
- JSON 驱动对白、勘查前置、玩家局部选择、记事与幂等场次事务
- 序章五个原场次 + 六个 MQ-00 任务补场的开发流程，可以从神仙度走到江畔辞王
- 有限的镜心拆招教学（准备/冷却/MP/非致命目标）与三架破山弩校准
- 手动/自动双存档槽，版本4有界跨章摘要＋当前章真实输入重放（版本1/2/3先严格校验迁移）、临时文件原子替换、加载前校验，坏档不覆盖当前状态
- 梁文靖固定 Lv.15，序章不向梁萧成长账发放 XP
- 序章结束后明确进入第01章：10节点、7个开发地图、47个事件步骤，含沙地练字、弹豆、避险/追母路线、两场真实遭遇、画地三招、掘墓刻碑与收犬东行
- 梁萧从 Lv.1 / 0 XP 开始；两场各30 XP、章节285 XP按收据一次发放，章末345 XP / Lv.4。战败重试回到战前，幼犬不是战斗目标

这不是完整游戏，也不是成品序章。地图当前只是按原尺寸元数据搭出的可通行临时路线，不代表完整关卡面积已经制作。人物含人工逐帧像素候选，场景仍为开发占位；没有成品肖像、剧情动作、音乐、音效、配音。任务补场是依据06的简要改编，未达到完整逐场剧本与45分钟序章预算。已有确定性回合内核与第01章成长/遭遇闭环；第01—03章开发功能及v4有界存档已冻结合入；第04章双人队与江南流程已通过本轮限定功能、独审和完整自然GUI验收，合招、后续首领、第05—20章仍未接入；`combat_rules.json` 的存在不等于全部规则已有代码实现。

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

普通桌面用户无需这些环境变量。存档位于 Godot `user://saves/`，`manual.json` 与 `auto.json` 独立；Linux 默认在用户应用数据目录，设置 `XDG_DATA_HOME` 后跟随该目录。自动存档保留完整场次事务提交；后续章节另有经过验证的玩法检查点。标题的“重新开始”需二次确认，不删除手动存档。序章/第01章沿原完整事务与返回探索的保存规则；第02章可从菜单保存机关进度；第03章受控机关与B01支持中途F5/F9严格存读，具体自动保存时机见下方。

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

旧版本3保留经旧验证器检查的章1终态基线，并严格按主线/支线交错的chronology重放。暂停支线会记录经地图边界验证的位置，支持部分拼图进度；字板按完整字提交，未写完的字需重新书写。升级保存保留`.v1.bak`/`.v2.bak`。未知字段、坏目标证明或账本不符均拒绝，失败不覆盖当前状态。战斗未完成时仍回到战前检查点。

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

## 第03章：灵台惊变（开发流程已闭环）

章2归档页可继续章3：15节点、4张开发地图、76个类型化步骤。包含药王分茶、清渊独立受挫视角、六/七/十二元教学消元、B01两阶段首领、双组拒位选择、物件条件换质、石影与披衣诱敌、独行谷外。小型算题明确为有限教学示意；离镜自掌只作剧情，不设力度或时机操作。

旧版本3严格兼容原章2存档，章3基线须来自合法章2终态；本章继承16/15岁和原有XP、物件、技能、伤损与铜钱。主线新增1030XP：B01前235、首领300、石影150、章末345；无前章支线终局2470/Lv14，前章两支线都完成为3120/Lv16。章末新增300铜，不清零前章财富。实际砚形态与算盘借用/损毁记录保存；第04章现已接入，见后续验收记录。

石影/诱敌为无实时QTE的逐格操作：方向键/WASD每次走一格；下方列表选观察、纠步、假势、喘息、取衣等操作后点“执行”，等待只前进一相。普通自由移动在此期间关闭；Esc可回菜单，恢复时保持已验证进度。第03章普通步进、论算中间输入、B01编排只更新内存；世界关键阶段、玩法完成/暂歇、B01每轮结算/重试自动保存。三类玩法中均可F5保存任意中途状态、F9读回；写盘仍完整校验，退出检查点保存失败会保留现场。B01公开意图、把手/环位与阶段检查点均由战斗会话验证，不能点击“成功”跳过。

附加测试（沿用前述隔离XDG目录）：

```sh
godot --headless --path game --script res://tests/test_chapter_three.gd
godot --headless --path game --script res://tests/test_chapter_three_boundaries.gd
godot --headless --path game --script res://tests/test_chapter_three_main.gd
godot --headless --path game --script res://tests/test_chapter_three_combat.gd
godot --headless --path game --script res://tests/test_chapter_three_battle_panel.gd
godot --headless --path game --script res://tests/test_chapter_three_battle_lifecycle.gd
godot --headless --path game --script res://tests/test_dialogue_layout.gd
godot --headless --path game --script res://tests/test_chapter_three_puzzles.gd
godot --headless --path game --script res://tests/test_chapter_three_world.gd
godot --headless --path game --script res://tests/test_chapter_three_escape.gd
```

真实GUI从章2人工终档沿算盘路线完成15节点，到3120XP/Lv16、550铜，退出后独立进程读回通过。新版辅助、固定B01面板/规则弹层、小窗对白及连续网格输入已单列局部GUI复验；19282项常驻回归与独立审查证据见开发计划。当前是功能流程验收，B01重复自守回合、地图折返与后续跨章存档性能仍有明确打磨任务。操作检查点与独立world预览只供QA，不是游戏中的跳关菜单。美术仍为候选，无成品分镜/音频，未验策划1.50小时节奏，未导出或发布。


### 有界存档 v4（2026-10-14）

新保存使用扁平已完成章摘要，按登记规则重新派生奖励、物品、知识及必要记事；当前未完成章仍保留并真实重放输入、战斗检查点、assisted与部分支线。已完成摘要保证声明结果内部一致，不再证明历史每次按键或精确受伤路径。v4首次冻结时只注册序章至第03章；当前第04—05章通过显式摘要适配器扩展，第05章仍在集成验证，第06章不被存档入口接受。

旧v1/v2/v3读取先经过原严格校验，读取本身不覆盖磁盘。第一次F5/自动保存替换旧槽时保留原字节 `.v1.bak` / `.v2.bak` / `.v3.bak`；备份失败或既有同名备份内容不同则保留旧槽与当前内存并提示。备份可用原格式独立读取，无需网络账号。新格式不嵌入旧原始存档。

实际第03章自然终档537441→13251字节，同机后续恢复中位约29.5ms；石影中途424714→90120字节，当前章仍严格重放，中位约487ms。测试条件、摘要保证边界和可复现工具见[有界跨章存档](../docs/development/bounded-campaign-saves.md)。


### 第04章限定功能验收（开发候选）

从第03章真实终档的归档页进入江南花柳。17节点、双人行动、投瓦/算木/45棍、窗绳/胭脂/背负避险与R02/L01已完成本轮自然图形验证。战斗编排和逐格移动不每步写磁盘；F5保存任意中途状态，F9严格恢复，阶段/暂歇自动保存。普通勘查时可在菜单切梁萧/柳莺莺领路。支线第一次窗口关闭不算错过，最后西行确认才关闭未完成的支线；战斗进行中可存档离开游戏，但不能跨往另一支线。

双人装备换装不回满气血；零钱袋从实际铜钱托管，归还不新增财富。已完章摘要按本章里程碑与合法选择归约；未归档支线的真实修补结果可以保留，但不会提前发支线XP、A03或水上无减速奖励。源码/数值依据及阶段证据见开发计划，不代表成品演出、预算时长或发行导出已完成。

第04章从章3人工自然终档重走主线及R02揭账/L01，终局5815XP / Lv23、550铜，梁224/675、柳548/588；独立进程读取同一19685字节v4终档通过。算木后五行显式协助，其他自然主线/支线机关按实际手工输入验收；不冒称全部分支的手工穷尽。最后两支归档文案和当前同行/历史牵挂年龄显示也经独立局部GUI复验。完整常驻28474项及最后显示70/主层195/旧章3主层679窄回归全部通过，具体版本和历史失败/重走证据见开发计划。

仍待打磨：上一空间反馈的清理、舟首同锚重叠和钟醒短暂背负姿态、跨章行囊中文名解析；人物/地图仍是开发候选，尚无真实release导出、完整声音/演出或预算时长验收。第05章仍未注册。


### 第05章正在集成（尚未完成自然GUI验收）

21节点/13地图；真实三联链、六锁、反八卦、百桔四解、外光三镜及同盒拆装；双人B02/B03、梁萧临时耗损覆盖、柳暂离但保留核心成长、限定阿雪固定23级。船舱与北岸安全调息须各自真实确认一次；中途输入与重试不会重复领取恢复。章末系统明确结算400铜，核心新增2535XP，章6尚未登记。

首轮自然旧档全章101、main209、事务138检查零失败，独立状态/历史矩阵已开展；这不是完整图形、release导出或最终平衡验收。阶段记录与来源裁决见开发计划及chapter-five-content.md。
