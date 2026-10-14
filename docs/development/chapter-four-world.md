# 第04章世界几何与空间操作开发记录

2026-10-14。本文件是开发实现说明，不是最终美术或完整章验收。

## 文件与接口

- `game/data/maps/chapter_four_maps.json`：姑苏水街、醉楼、屋巷、院门、寒山寺、钟内、雨廊、枫桥8个640×384紧凑可玩切片。源图面积仍在内容契约保留，不以本切片冒充全源图。
- `game/scripts/world_actions/chapter_four_world_actions.gd`：独立确定性空间控制器，不发经验、物品或存档事务。
- `begin(objective_id, attempt_id, trusted_context)` / `apply_input` / `get_view` / `snapshot` / `restore(saved,trusted_context)` / `receipt` / `get_receipts` / `static replay_receipt(proof,trusted_context)`。
- 主集成负责可信前置、当次attempt、领队/角色可行动状态和结果消费。空间控制器拒绝调用方输入position/success；输入只有每次单轴一格、现场E、观察、护住、等候、恢复起点，以及钟纹次序。
- `world.sync_controlled_view(view)` 仅展示已演算位置。`world_objects.ch04_spatial_state` 只应由已验证结果写入；同地图段间承接位置、背负、马与楚婉状态，跨图使用新图锚点。普通路线结尾也需更新此位置，防止接回旧位置。

## 可重放目标

window_anchor_verified、horse_call_and_arrival、liu_carried_not_combat、shelter_route_verified、shelter_care_performed、patrol_escape_verified、horse_release_verified、horse_calm_and_led、gate_encounter_verified、chu_wan_released、bell_cover_position、moor_and_sit、bell_response_verified。

- 系索和清窗在不同真实位置；呼马后马每拍移动16像素到落点，未到不能越窗。
- 泉/船分支由可信选择指定；实际到泉边擦拭，或实际到船内关闭屏障，无回血或医学治愈效果。
- 巡逻逐拍看前、转向、步进；墙/柴堆阻挡射线；同拍换格、交叉线段用相对运动距离检出接触。
- 解开同一匹 `animal_yanzhi` 的缰绳后逐格牵引，远处不能把马瞬移到身后。
- 院门须门前观察、两次实际追兵接近、楚婉位置短暂制住、越过院门；对白之后另一个session在放行点释放，无伤害或HP目标。
- 钟内护耳有两次声脉操作；参纹分支到三个不同位置，再依空/色/相依次序输入。三字是已标明的教学比喻，不作梵文译文。
- 最多4096条输入，日志满仍允许恢复可信起点。中途快照重放输入和引擎事件哈希，JSON整数/浮点表达规范化；未知输入、额外位置/成功字段及改动收据拒绝。

## 自由路线及侧线锚点

普通dock_walk、pursuit_first_route、pursuit_second_route、tavern_arrival、ride_route、temple_route、quiet_walk仍采用原world自由移动/有序路点机制。所有路线末路点等于E交互点；不能将路径完成和可交互终点分开。

R02雨廊动作：r02_notice、r02_inspect_hat、r02_rope_anchor、r02_ledger（rope_access→back_eaves→ledger）、r02_witness_one/two、r02_reclaim_drawing、r02_willow_0/1/2、r02_repair_seat、r02_rain_seat。柳上檐、梁采访的角色门控由campaign处理。

L01水街动作：l01_notice、l01_hull_inspect（舟侧→浅水船底）、l01_collect_boards/hemp/oil、l01_priority_cargo、l01_repair_site。现场材料证据先于修船板；不能用板内取料按钮替代世界调查。

浅水区普通自由行走速度乘0.5。可信 `l01_water_movement_no_slow` 解锁仅使乘数恢复1.0，不改变基础65速度、战斗SPD或深水碰撞。深水渠仍为实体障碍。

## 候选人物与坐骑

柳独立手工四向候选 `liu_yingying_jiangnan_16.png`，绿衣/朱红腰绦/背笠；不是晓霜贴图换色。年龄由main可信context传入，梁17岁不回退幼年体形。背负柳使用独立绿衣笠影，晓霜的旧背负身份保持原样。

`animal_yanzhi` 绑定64×64马格（足锚32,58）而非人物32×48。白底朱红斑。四向双骑使用 `horse_yanzhi_riders.png` 与马同行同列、同锚点，柳前梁后专门屈膝坐姿，已含bob，不硬叠行走人物。`mounted_on=animal_yanzhi` 或riding=true时只显示一个骑乘组合，隐藏独立柳和马。上下马当前为状态切换，无完整动作动画；美术仍为候选。

剑、钱袋、砚显示跟随可信物品owner；切柳主控不会把梁的剑转给柳。没有因为外观生成物品或改变所有权。

## 独立GUI入口

`godot --path game res://scenes/chapter_four_world_preview.tscn`

- 1—8：地图；WASD/方向：自由行走
- M：预览四向双骑状态切换；非campaign操作
- Tab：依序切特殊目标，进入逐格模式
- 方向/WASD：走一格；E：现场操作；O：观察；G：门前护住；Space：等一相；R：恢复段起点
- F5/F9：独立预览的内存快照，无个人存档写入
- 门前示例：到(144,240) O、G两次；到(240,240) E；到(368,240) E。下一释放段到(464,240) E。
- 呼马示例：窗(128,240) E，等马真的到(144,240)，再E。

GUI预览每目标独立起点，真实campaign承接已验证前段状态；预览不能证明main奖励/存档完整。

## 验证入口与边界

沿AGENTS隔离XDG目录：

- `godot --headless --path game --script res://tests/test_chapter_four_world.gd`
- `godot --headless --path game --script res://tests/test_chapter_four_routes.gd`
- 旧world三个测试：test_chapter_world、test_chapter_two_world、test_chapter_three_world

新路线测试用真实Input.action_press方向输入、物理步进走完整条路径，终点再按interact检查；没有靠改player.position绕过路径。独立controller测试逐输入走到目标、E、快照JSON重放、错误/篡改/日志上限/追兵截获/换格线段碰撞，并串接泉/船两条背负马路线。

需另验：main空间UI输入接法、角色状态授权、campaign奖励和F5/F9磁盘往返、全章含侧线键鼠、坐骑上下马时机与声音/完整动作动画。独立图形检查由主线程组织，不将自动测试冒称最终实机验收。

### 2026-10-14局部验证证据

- 控制器689项/0失败（含共享真实输入driver、泉/船串接、任意中途JSON恢复、非法追加输入拒绝、满日志恢复、被巡逻实际截获）。
- 路线物理输入＋配角站位＋切领队/物品所有权/双骑唯一显示481项/0失败。
- 旧world回归333＋429＋348项全部0失败，独立preview headless启动无SCRIPT ERROR/ERROR。
- 图形检查人员已实际验证两处系索/窗E、等待马到场、背负/泉边/照拂/柴堆；四向双骑实际走动无重复独立马/柳，侧向屈膝与前后座可辨。反馈发现巡逻/院门阶段不可感知的问题后，已补位置/朝向/截断射线、守势/接近计数、楚婉同行释放及钟声中间反馈，等待新进程复验；不将初轮可按通当作该修订的图形验收。
- 配角严格采用章4actor_registry的npc_jiu_ru/npc_chu_wan/npc_chu_xianliu等语义ID；旧章角色名映射保持原样。每图有独立梁萧实例用于切柳后跟随，不用消失的领队假装双人队。

02:50 UTC开发检查点变更：dock_walk由出生点(80,240)移至(144,240)，action与末路点同步，实际走入码头后才能E。此地图配置更新使旧章4开发收据hash失效；只应重建开发检查点，不声称兼容之前未冻结的章4存档。已先与集成线程协调，并通知GUI确认是否使用过main。旧0—3章地图和存档不变。
