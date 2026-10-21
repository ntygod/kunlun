# 第十章空间流程与验收边界

本实现依据 `chapter-ten-preflight.md`、06/MQ-10、03/SC-10 与 08/MAP-19、PAL-06。六块 480×320 紧凑扇区是可玩开发美术，不等同 MAP-19 全尺寸地图、成品素材或导出验收。实体绘制采用固定整数坐标与冷灰、泥色、芦苇、潮线；没有以随机生成素材充当成品。

| 控制器 | 场景/地图 | 实际动作 |
|---|---|---|
| world_ch10_rescue | rescue_children / pass | 到伤者身边稳住孩子，暂不护送 |
| world_ch10_escort_children | repair_ox / pass | 木牛谜题由剧情先验；楚婉与赵昰逐步跟随，幼童随楚婉，到安全山口才结束 |
| world_ch10_friends | hide_friends / forest | 到五人各自树下，非致命安置到遮蔽处 |
| world_ch10_decoy | draw_pursuit / forest | 穿过林间到树外设置诱兵机关 |
| world_ch10_axue_return | axue_return / reeds | 阿雪独行，依次查看折苇、蹄印、布片，绕开巡骑抵达出口 |
| world_ch10_farewell | last_embrace / levee | 到背风石旁，按住两段各1.5秒的扶稳、遮雨动作；无文字选项框 |
| world_ch10_river_release | river_farewell / levee | 怀抱阿雪走到江边，放手后移除其实体；没有船 |
| world_ch10_shore_walk | silent_shore / shore | 连续方向输入缓行至少60秒，并抵达240像素外的终点 |
| world_ch10_recollection | three_months / stone_array | 可立即离开；走到临灶停留3秒才记录追思，不阻断主线 |

上述场景名省略 `ch10_`，地图名省略 `map_ch10_`。普通交互 `evt_ch10_prepare_escape` 在林中 [352,256] 的石棚，有屋顶图形与安全接近路径。木牛、石阵、B06 地图入口另有明确 action geometry。

## 状态与集成契约

`ChapterTenWorldActions` 提供 begin/apply_input/snapshot/restore/receipt/get_receipts/get_view/replay_receipt。身份、场景、地图、目标、revision 与 current_token 均绑定可信上下文；`next_demo_action` 仅用于合法输入测试驱动，不能代替真实操作验收。恢复通过完整输入重放与结构比对，拒绝写入 complete、布尔坐标、额外字段等伪造。跨阶段同地图同角色保留此前可信 `ch10_spatial_state.player_position`；其他场景按入口加载。章节资源、死亡和奖励归 runtime 事务处理。

View 中 `timed_mode` 为 farewell、shore_walk、recollection 或空串。`world_state` 包含 phase、stage、player_position、actor_positions、actor_paths、visible_actor_ids、carrying_actor_id、hold_ms、active_ms、target_position、at_target。展示层只投影，不授予任何奖励。

普通 move 是16像素网格；shore walk 必须为250ms的一像素有效移动（4px/s），墙上或无方向不累计。farewell hold、recollection linger 每次最多250ms。步行打断扶稳/追思累计。模型回放证明输入合法，**不证明真实墙钟经过时间**；可见、焦点、暂停/菜单与帧时间上限由界面输入层负责。追思允许直接 leave，不以等待解锁前进。

## 本环境实际测试

Godot 4.6.3 headless：

- `test_chapter_ten_world.gd`：1662 checks，0 failures。九条完整合法路径、部分 JSON 存档恢复、完整证明、非法输入原子拒绝、同地图坐标续接、真实NPC路径、59.75秒不能退出、60秒且抵达出口、追思可跳过。
- `test_chapter_ten_world_projection.gd`：2463 checks，0 failures。实际 World.configure、控制角色/位置投影、六地图实体碰撞一致，以及渲染帧无报错。此项不是截图像素审查。

命令：`godot --headless --path game --script res://tests/test_chapter_ten_world.gd`，投影测试替换脚本文件名。日志在执行环境 `/tmp/ch10-world-test.log`、`/tmp/ch10-world-projection.log`；这些临时日志不声明长期存档。

## 待图形环境验收

使用集成版本真实玩到各场景；不编辑存档。特别核查：幼童没有瞬移越过障碍；五宝安置后无死亡状态；阿雪独行期间梁萧不作为可控人出现；640×360窗口下扶稳/遮雨无选项菜单或血量栏；按住E/Space，两动作中途释放、移动、开菜单和切出窗口不偷计时；静默沙滩持续走路约60秒可抵达终点，暂停不累计、无追踪箭头；江边放手后无阿雪幽灵；追思可直接离开，也可到灶边真实停留3秒。保存/新进程恢复要使用游戏自身功能，并核对原档哈希。以上实机项目尚未在本环境宣称通过。
