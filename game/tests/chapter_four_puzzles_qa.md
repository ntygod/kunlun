# 第04章机关：冻结接口与验证边界

## 接口

`res://scripts/puzzles/chapter_four_puzzle_resolver.gd`（`ChapterFourPuzzleResolver`）模型版本2。

- `begin(puzzle_id, attempt_id, trusted_context)`，`set_context(context)`
- `apply_input(action)` 返回 `ok/message/view/receipt/receipts`
- `get_view()` 的 `kind=chapter_four`，完成判据为 `view.state.complete`
- `snapshot()` / `restore(saved, trusted_context)`：只信输入重放所得状态，JSON整数归一化
- `receipt()` 返回最新阶段；`get_receipts()` 返回当前轮全部阶段前缀证明
- `replay_receipt(proof,puzzle_id,attempt_id,trusted_context)` 严格重放并逐字段比对

| puzzle_id | 收据阶段 |
|---|---|
| tile_ch04_intercept | tile_trajectory_verified |
| board_ch04_wood | wood_count_derivation |
| trial_ch04_staff | staff_layout_verified → staff_trial_verified |
| r02 | r02_weave → r02_rain_test |
| l01 | l01_repair → l01_leak_test |
| ledger_ch04_r02 | r02_ledger_verified（仅R02揭黑账分支） |

主流程仅在 `state.complete` 后一次验证并提交本场全部阶段收据。不能看到首份阶段证明就结算场次。重试会清本轮阶段证明；已核对阶段清撤回栈，其他操作可撤回。没有机关XP或真实库存修改。

`context` 为只读透传，当前数理模型不依赖其任何必填key。**主流程必须独立门控**真实世界到达、调查证据、接取/选择、材料到场、角色可用性、原柳笠所有权等。面板的领取动作表示从已到场现场料堆取用，不声称替代走位、取图、还图、追回租钱等世界证据。L01所选货物分支由主流程保存，板面只验证卸载后载重变化，不声称未选货物同时获救。

## 真实规则

- 投瓦：三跳整数接触，前两次需合法水面；缆索命中后另推进水流转船，再验证 `(9,6)` 安全落脚。9组参数只有 `vx=2,dy=0` 通过。轨迹弧线为接触点间示意，不是现实水漂物理。
- 算木：六个独立cut ID；逐次三子组、上一行乘3得下一行；没有直接提交729入口。
- 细棍：9组各5个唯一棍位，45节点环（0↔44显式连边）；玩家1—3步、对手最短环路4步逐节点校验；三轮棍毁后手撑可赢，脚落地失败。图论教学模型，不声称已制作世界轻功碰撞。
- 修笠：3段材料各跨2槽；六槽上下交替；雨检逐槽核对；固定原物品 `item_ch04_liu_willow_hat`。
- 修船：3匹配板、3份填料、卸货载重≤1、码头柳树绞索、扶正后松索、3个独立潮汐零进水样本。
- 三层提示后，玩家主动点击 `assist_stage_v2`：同一验证器执行展示的小步；算木每次最多五步以免机械重复，永久标记assisted。v2在本行结束时立即停止；v1保留旧的最多五步语义，并有各板golden收据指纹测试。这些动作语义已冻结，后续改进须新增动作名/版本，不改变旧证明的重放。
- 最多1024输入；满额时reset/retry仍可重开，首条摘要仅含提示/协助/失败元数据与废弃日志hash，不带解题状态。

## UI与测试入口

共享 `PuzzlePanel` 路由 `kind=chapter_four` 到新 `chapter_four_puzzle_panel.gd`。新面板固定控件实例，既有ScrollContainer负责滚动，不因每次输入重建焦点控件。

```sh
export XDG_CACHE_HOME=/tmp/kunlun-cache XDG_DATA_HOME=/tmp/kunlun-test-data XDG_CONFIG_HOME=/tmp/kunlun-config
godot --headless --path game --script res://tests/test_chapter_four_puzzles.gd
godot --headless --path game --script res://tests/test_chapter_puzzles.gd
godot --headless --path game --script res://tests/test_chapter_three_puzzles.gd
# 图形环境：任选以上六个ID，固定640×360，直接点实际控件
godot --path game --script res://tests/preview_chapter_four_puzzles.gd -- trial_ch04_staff
```

独立测试覆盖逐输入JSON往返、阶段证明重放、篡改、错参数/错时序、撤回、满日志恢复、整数三跳、六行指数、45独立棍位与逐棍追逐、手撑/脚落地、逐槽试雨、三潮汐，以及所有六板在616×336和1200×650面板中的真实控件信号、辅助完成、宽度、可滚动正文和已完成锁定。

本worker已通过headless真实控件/布局检查；独立图形环境视觉QA由项目协调者安排，不以headless尺寸断言冒充截图验收。没有新增配音或最终美术。

## 2026-10-14 本地证据

- 最终章4独立机关：3027 checks，0 failures（含与JSON契约对照、实际中文字体下双尺寸控件检查）。
- 旧章2机关：1150 checks，0 failures。
- 旧章3机关：4543 checks，0 failures。
- 编辑器headless import：未见SCRIPT ERROR或ERROR。
- 这些记录不替代完整章4集成、图形路线或成品资源验收。


## 细棍初距实施裁决（2026-10-14）

旧开发契约玩家0/追者22、三轮、每轮玩家±1—3与追者4，在216条合法三轮序列中全数避开，方向选择不影响胜负，被擒不可达，不能算有效轻功赌斗。经项目负责人批准，仅调整有限教学模型起点为0/12；45棍、三轮、毁棍后手撑的来源因果不变。两套独立Python oracle一致：216序列99可生存、117被擒（36在第二轮，81在第三轮）。连续逆时针3可生存，连续顺时针3在第二轮被擒；逆1/逆1/顺2在第三轮被擒。仍须棍毁后观察、选择双手撑地并通过裁定才算胜，生存路线数不意味着直接获胜。

模型升至VERSION2并更新content hash，明确拒绝未发布的章4VERSION1开发checkpoint；主集成已获通知重新生成章4测试检查点。已发布前三章接口、快照、动作语义均不变。v1辅助动作仍保持原最多五步行为，UI使用v2的当前行末停止行为，测试指纹按模型2冻结。


## 小窗动作反馈改进

独立GUI在640×360发现：原布局需从观意图按钮向上滚三屏读反馈，再回操作区；反馈文字由一行扩两行时，下方控件视觉位置漂移。现于staff观意图/移动按钮附近直接显示编号、两向距离、追4与本轮路径；其他板动作区及辅助按钮旁也有反馈。render保留当前焦点控件的屏幕y位置，而非只保留滚动条整数。两个尺寸的真实控件测试验证多行反馈后y偏差≤1px；独立GUI复验仍由GUIworker负责。


## R02示例账目窄补

主集成要求补上契约“先揭黑账”分支的实算。新增独立 `ledger_ch04_r02`，只有该分支且真实账簿/证词调查后由主流程授权打开。分别核读本金10、议定利息2、索款15三项，再填写 `10+2=12` 与 `15-12=3`，核对后签 `r02_ledger_verified`。仅形成证据，不发XP/钱物，不跳过非致命对质。UI明确标作改编示例账数，不声称原著精确数字。

动作：`inspect_account(field: principal/interest/demand)`、`sum_account(principal:10,interest:2,total:12)`、`compare_account(demand:15,legal:12,excess:3)`、`submit`。新题独立content hash；原五模型的版本2收据指纹完全不变。


独立GUI复测回报：投瓦错投→撤回→三跳/转船/安全落脚完整，R02手工三段六槽与逐槽试雨完整，细棍版本2被擒→重试通过；就近反馈与视觉锚定明显改善。L01独立preview在绞索阶段窗口退出，日志无错误，原因未定；不能据此声称修船GUI通过。已增真实手动L01按钮全链回归，挂索/扶正/松索/三潮汐均不发close_requested且完成正常；preview诊断日志新增输入与关闭信号。正式main的L01及细棍成功路线待GUI复验，headless不替代该项。
