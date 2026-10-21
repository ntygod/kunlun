# 第10章《钱塘惊潮》可玩流程合同

2026-10-21。基线main `80e8dae503a8c20f3d68911c1bcae47587bc7d86`，开发分支 `feat/chapter-ten`。此为首版数据和实施合同，尚不代表引擎或GUI验收通过；来源与适配理由见 `chapter-ten-source-decisions.md`。

## 顺序、玩法与主线预算

|序|运行节点|地图|必要玩法/因果|主线XP|
|---|---|---|---|---:|
|1|ch10_rescue_children|map_ch10_pass|护住孩子、打开安全通道；不虚构十二人战斗奖励|200|
|2|ch10_repair_ox|map_ch10_pass|校传动/载重/试走，再真实护送；楚婉启程前选择引兵口吻|250|
|3|ch10_hide_friends|map_ch10_forest|非致命安置五宝于隐蔽树冠|200|
|4|ch10_draw_pursuit|map_ch10_forest|避雨石棚主动包扎一次、送雪西行、布置引兵|300|
|5|ch10_axue_return|map_ch10_reeds|阿雪独立辨迹避骑折返，挡箭|250|
|6|ch10_last_embrace|map_ch10_levee|扶稳/挡雨的微交互，无文字选择/状态药栏；永久离队|150|
|7|ch10_river_farewell|map_ch10_levee|实际临水送别，划地断义|155|
|8|ch10_bayan_tide|map_ch10_levee|B06独守六回合、第四回合阶段变化、潮吞江岸|300|
|9|ch10_silent_shore|map_ch10_shore|潮退独行60个活跃秒，菜单/暂停不得计时|100|
|10|ch10_elder_awakening|map_ch10_stone_array|疯老人击穴、淤血清醒；身份未揭|150|
|11|ch10_stone_array|map_ch10_stone_array|三石改变来劲方向，实际争取调息回合|250|
|12|ch10_three_months|map_ch10_stone_array|三月苦练后授A04，听鼾/覆草两口吻，可选灶旁追思|300|
|13|ch10_laoshan_departure|map_ch10_stone_array|忆及吴常青、携老人北行并归档|165|

主线2770，B06成功唯一额外300（`reward_mq10_bayan_once`），机关无独立XP，无侧线XP，合计3070。第一至第七节点主线1505，所以真实最低17845入口在B06前为19350。自然20795入口终局23865、最低17845入口终局20915；铜钱只在章末加650。这里是守恒预期，不是已实跑结果。每节点的 `reward_mq10_<suffix>` 绑定其末尾 `evt_ch10_<suffix>_complete`；主线奖励一律silent。

## 数据和接口

`chapter_ten.json` 登记13节点、两个选择组、角色、物品、来源哈希、奖励和57个步骤的完成门槛；`chapter_ten_runtime.json` 按节点列出运行步骤。普通对白与末尾对白仅给事件收据，effects为空；只有下表13个有意义的事务使用 `chapter_ten_event`，防止将任意显示文字当作游戏状态写入入口。

|事务ID|前提与单次结果|
|---|---|
|evt_ch10_children_entrusted|`pz_ch10_wooden_ox`与`world_ch10_escort_children`均有合法完成证明后，孩子交付楚婉|
|evt_ch10_friends_hidden|`world_ch10_friends`完成，五宝安全隐蔽且非致命|
|evt_ch10_prepare_escape|主动石棚包扎；只将活着的梁萧HP补满一次，其他资源不动|
|evt_ch10_axue_sent_west|阿雪转西山离开场景同行，之后只能通过其独立返回流程重现|
|evt_ch10_axue_return_resolved|`world_ch10_axue_return`完成后挡箭，剧情受创，不提前永久离队|
|evt_ch10_axue_died|`world_ch10_farewell`完成后死亡、永久席位/针线包/记事一次落账|
|evt_ch10_river_release|`world_ch10_river_release`完成，不生船、不留可携遗体|
|evt_ch10_sever_oath|划地断义，不伤旧友、不复制扳指|
|evt_ch10_bayan_survived|可信六回合B06证明后唯一额外300，不能以任意“胜利=true”授予|
|evt_ch10_elder_clears_clot|清醒剧情标记，不增加未定义的数值治疗或角色战技|
|evt_ch10_stone_training_complete|`pz_ch10_stone_array`完成，只记录实践，尚不授A04|
|evt_ch10_three_months_training|三月苦练共同事务授LX_A04基础/行路知识，两口吻不分技能奖励|
|evt_ch10_depart_laoshan|携老人北行，章末650铜唯一结算；老人非可操战斗队员|

世界目标ID依次为 `world_ch10_rescue`、`world_ch10_escort_children`、`world_ch10_friends`、`world_ch10_decoy`、`world_ch10_axue_return`、`world_ch10_farewell`、`world_ch10_river_release`、`world_ch10_shore_walk`。机关为 `pz_ch10_wooden_ox`、`pz_ch10_stone_array`；战斗为 `enc_ch10_bayan_tide`，结果 `ch10_tide_survived`。

`world_ch10_recollection` 仅供灶旁可选停留，不列入任何节点完成门槛。两个选择组为 `choice_ch10_diversion`（truth/hurry）和 `choice_ch10_elder_response`（listen/cover）；诀别没有choice步骤。章节data里的cast用于在场/可发言核对，不表示全部人物变为常驻战斗角色。

## 玩家反馈和表现边界

救童、藏友、阿雪返援必须看见安全路径、目标位置和行动结果；重试应明确回到何处，不能仅静默拒绝输入。木牛盘与石阵盘必须呈现传动/载重及三股来劲的方向；三层提示和演示都执行正式合法命令，assisted记录保留，演示能及时停止。小窗不靠缩小中文字体挤入全部控件。

诀别隐藏数值状态和伤药入口，交互只表示扶稳、抱住和挡雨，不提示“救活/失败”。生死事务后不弹装备回收或奖励窗。沙滩一分钟为可操独行，不用一段不可操作的等待替代；追思三秒只在合适安全地点触发，不强行打断战斗、机关或关键对白。

采用320×180整数像素世界与独立高清中文UI，PAL-06冷灰泥滩/芦苇/潮白为候选表现依据。程序绘制和现有角色候选仍须标为开发资源；没有成品原画、逐帧ACT-12、雨潮音效或配音时不宣称成品。

## 验收准备

- 从第9原自然档副本和真实0—9最低流程分别进入；逐事件往返、重复确认、旧代回调和非法字段不改变资源。
- 检查包扎一次性、B06前最低XP、B06六回合/第四回合/低伤损入口/重试与实际资源、A04授予时点。
- 阿雪存活→受创→永久离队的每个边界独立进程恢复，R03有/无/鸟/盒/托管旧史不复制物品；旧营物和铜钱守恒。
- 木牛完成不能代替孩子护送；五宝未全藏不能推进引兵；阿雪回援必须有三类线索及安全路径；石阵必须真实改流并获得调息回合。
- 时间玩法检查菜单、暂停、失焦、读档不累积隐藏时间；追思可略过而主线照常。
- 实机需要原云端从精确候选SHA启动，对自然整线和640/1280布局、诀别微动作、静默沙滩/追思做真实输入与存档；未完成前不能写成GUI通过。

上述为待执行门槛，测试结果由运行日志与后续验收台账填写，不能靠本文复述验收目标就视为完成。
