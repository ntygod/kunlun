# 第11章可玩流程与接口合同

2026-10-21；第10候选f1f8825基础上的feat/chapter-eleven，尚未验收完成。来源裁决见chapter-eleven-source-decisions.md，初步差异记录见chapter-eleven-preflight.md。数据不是成品美术或实际游玩的证据。

|顺序与scene（ch11_前缀）|地图（map_ch11_前缀）|玩法与主线XP|
|---|---|---|
|town_truce|town|实际止争留通道，150|
|herbal_reunion|clinic|驻足诊察、故人相认、晓霜迁移核心、R04开放，200|
|elder_recognition|clinic|吴常青识老，175|
|dragon_needle|clinic|刘梓事件、晓霜取针、标准补给，225|
|sunrise_promise|sunrise_peak|背人登峰及歇脚、旧诺、袭山前R04最后确认，200|
|herbal_assault|rear_path|袭山与挟持虚张被识破，150|
|cave_escape|rear_path|护人真实穿过后山路径，225|
|meridian_insight|cave|经脉互参、CO02授予、主动运转N02，300|
|rescue_b07|clinic|双人公开意图两阶段救师，300|
|qingxing_legacy|clinic|十册医典、A03升阶、殉道、止虐方法，150|
|yaer_treatment|clinic|主控晓霜诊治、复诊、练声，175|
|plum_apprenticeship|clinic|七日学拳及真实步法，125|
|kuaixue_gift|clinic|了情主持、哑儿牵赠快雪，125|
|gongyang_parting|clinic|误伤、身世、放行与离庐，100|
|yellow_river_boulder|river_ferry|两人真实协作推石救人，175|
|three_companions|river_ferry|花生正式入队、营火口吻、归档，135|

前8场主线1625，全16场2910；B07成功另400，主线总3310。最低入口20915→战前22540→章末24225；第10自然路线预期23865→本章无R04终态27175（R04完成27575），这些为守恒期望而非新自然存档证据。700铜章末一次，无支线铜钱、无独立机关奖励。

## 运行接口

普通对白与scene_complete仅有事件收据，effects为空。语义写入使用chapter_eleven_event：town_truce_resolved、xiaoshuang_rejoined、elder_identified、dragon_needle_removed、standard_supplies、r04_window_closed、meridians_understood、circulate_yin_yang、b07_survived、qingxing_inherited、wu_changqing_died、healer_boundary_respected、yaer_treated、plum_apprenticeship_complete、kuaixue_received、gongyang_parting_resolved、river_people_saved、huasheng_joined、chapter_archived及r04_completed，均以evt_ch11_为前缀。事务各自前提、完整对象与一次性语义账由runtime/summary重放校验；显示文本不能代替证明。

世界ID：world_ch11_town_truce、world_ch11_reunion_observe、world_ch11_sunrise_ascent、world_ch11_cave_escape、world_ch11_plum_practice、world_ch11_river_boulder。机关ID：pz_ch11_dragon_needle、pz_ch11_meridian_channels、pz_ch11_yaer_treatment、pz_ch11_r04_triage、pz_ch11_r04_medicine。B07为enc_ch11_laoshan_rescue，op objective_battle。唯一基础空间action为evt_ch11_circulate_yin_yang，须在cave设合法触点，不能以打开对白自动换心法。

R04用独立side_quests.R04数组、独立完成门槛、reward_ch11_r04、MEM_R04_TRIAGE_ORDER。choice_ch11_r04_method写choice_key=r04_method、值r04_method_a/r04_method_b，runtime将其映射为模型context.r04_method的a/b，冻结后不能偷换方法。先给三位病人的明确诊断信息，再选法；triage模型仍逐一观察/操作，medicine模型另完成熬汤和正骨。完成只发400一次，授迷香基础/捣药杵，不叠额外治疗被动。side_ch11_r04提供早期窗口，confirm_ch11_leave_clinic为deadline=true可返回确认，关闭事件保留已归档或记录未完错过，不删旧输入账。

选择组另有choice_ch11_reunion、choice_ch11_healer_boundary、choice_ch11_companions，均为有反馈的局部表达；不改变死亡、全章XP、B07必需技能和队伍加入。L05回响evt_ch11_l05_echo由真实继承状态派生；未完成时用普通医庐对白，不生成药箱。旧R03没有触物步骤，不把历史标签变成当前持有物。

物品契约：item_ch11_qingxing_volumes为晓霜持有十册医典；animal_kuaixue为晓霜拥有的非战斗随行白驴，登记actor而非可交易物品，不参与核心成长；item_ch11_qingxing_pestle为R04永久无数值信物。前章针线包、信物、军营托管物保留；永久死亡记录和白色空席不可被核心招募挤掉或复活。

## 验证准备

来源/引用/奖励静态检查后，从真实最低及自然第10合法输出进入，逐节点保存恢复，覆盖晓霜迁移前后、衣装与内功前后、B07两阶段、托卷/死亡/止虐、花生入队与终态；真实主控和存档同一身份不可分裂。额外覆盖R04未接/暂停/两方法/完成/截止，旧L05各法与无支线，R03真实持有/托管组合。

战斗需实际证明公开意图、保护期、三敌清场、DOT优先级、治疗净化、单内功、合招消耗、非致命与双存活目标；最低路线不用可选迷香、战后A03rank2或未来A06。疗伤/推石/登山不得以伪造proof跳过。针药面板和角色UI须640/1280实际可操作，F5写盘/F9新进程恢复，不把无显示模型检查当GUI。具体通过数字另由各负责模块和集成报告登记。
