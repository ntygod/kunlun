# 第12章可玩流程合同

2026-10-21，feat/chapter-twelve；依赖第10/11冻结候选0bf6c7a，不改旧章。本页与数据是首版实施合同，非全章验收结论；来源与适配见chapter-twelve-source-decisions.md。

|序与scene（ch12_前缀）|地图（map_ch12_前缀）|玩法及主线XP|
|---|---|---|
|1 jiuhua_news|road|行商闻讯、决定赴庄，250|
|2 road_relief|road|山道观察及R05窗口，300|
|3 bamboo_disarm|manor_gate|截止确认后竹丝止众，400|
|4 manor_reunion|manor_gate|柳首次露面、退半步与回应，350|
|5 duel_compact|arena|三局约定、晓霜四式选配，445|
|6 duel_han|arena|医理破韩、战后A05基础，500|
|7 duel_lei|arena|HS_A03前置、花生破器收掌，450|
|8 duel_chu|arena|诗意卦象拆招、楚收剑，600|
|9 liuying_freed|manor_gate|柳同一对象归队、真实出庄，300|
|10 wrist_crisis|care_room|扭腕、误伤、急救边界，400|
|11 two_months_care|care_room|分期复诊与两月照护，350|
|12 wulong_truth|care_room|五龙解释、回应、花生留守，300|
|13 jiangxi_clinic|jiangxi_clinic|辨轻重与医棚配药，300|
|14 meiling_departure|meiling_path|迷香兜底、按药单寻草，200|
|15 forest_betrayal|chiyou_clearing|第二次刺肩、蛇伤、骆介入，150|
|16 reverse_five_phases|chiyou_clearing|经文医理与反五行实际推导，120|
|17 chiyou_b09|chiyou_clearing|再整备四式、三人医毒战，400|
|18 healer_takes_control|chiyou_clearing|晓霜封毒囊、柳包扎、梁导毒，250|
|19 three_patient_oath|chiyou_clearing|逐人确认不加害，250|
|20 shennong_legacy|chiyou_clearing|神农典归晓霜、A05升阶、坦陈心意，200|
|21 medical_departure|forest_exit|实际同行出林、归档，175|

21场总6690；前5场1745、前16场5415。B09后独立650，铜750章末，R05另400且无铜。预算不是新的自然存档。全部节点奖励由其evt_ch12_<scene后缀>_complete收据与reward_mq12_<scene后缀>绑定，普通对白不充当语义事务。

## 模型和语义接口

四battle：enc_ch12_han_duel/enc_ch12_lei_duel/enc_ch12_chu_duel属于同编号B08的三局；enc_ch12_chiyou_medicine属于B09。均op objective_battle，XP0，成功后的内容事务按独立一次账结算。三个B08 attempt各自完整保存，不要求重打前局；复苏不能作用于剧情死亡角色。

四puzzle：pz_ch12_care_visits、pz_ch12_clinic_supply、pz_ch12_reverse_five_phases、pz_ch12_r05_rescue。七world：world_ch12_bamboo_disarm、world_ch12_freed_escort、world_ch12_herb_gather、world_ch12_healer_safety、world_ch12_three_oath、world_ch12_medical_departure、world_ch12_r05_road_repair。照护无重复取物世界段，战后无重复医疗面板；安全顺序由真实空间交互证明。R05机关先救人，之后世界修路，分别校验。

所有语义effect op为chapter_twelve_event，ID统一evt_ch12_前缀：news_learned、r05_window_closed、bamboo_disarmed、duel_oath、b08_loadout_committed、han_won、lei_prepared、lei_draw、chu_draw、liuying_rejoined、wrist_injury、care_completed、wulong_truth、healer_work、hxs04_ready、huasheng_stays、forest_injuries、reverse_five_phases、b09_loadout_committed、b09_survived、healer_control、three_patient_oath、shennong_inherited、chapter_archived、r05_completed。han_won包含A05基础，后hxs05_learned仅解释对白；lei_prepared授HS03；b09_survived独占650，chapter_archived独占750铜。伤标、恢复范围与资源写回必须由事务明确校验，不凭文本自由变数。

选配choice_ch12_b08_loadout/key b08_loadout，options ch12_b08_loadout_keep/recommended/counter；choice_ch12_b09_loadout/key b09_loadout，options ch12_b09_loadout_keep/recommended/healing。保持选项取实际旧装备，预设只取已学，四槽上限；选择之后独立loadout_committed事务生效。界面须允许选择前返回菜单，不收费、不治疗。

R05独立side_quests.R05，choice_ch12_r05_method/key r05_method，值r05_method_a/b由runtime映射模型context.r05_method的a/b。剧情接取含现场危险观察，模型须实际复核才可按法执行。side_ch12_r05位于road_relief，confirm_ch12_enter_manor位于bamboo_disarm开头且deadline=true；关闭后保留已完成/未完成历史，不能重入领取。归档reward_ch12_r05、MEM_R05_GENTLE_STRENGTH、item_ch12_r05_oil_lamp。两路同奖励，升阶遵07并记录事实，不直接授HS_A08。

主线医典item_ch12_shennong_classic归晓霜，与旧item_ch11_qingxing_volumes并列而不覆盖。主线记事MEM_MQ12_CHIYOU_OATH；柳重逢、五龙回应两组局部口吻不影响技能或预算。全章不篡改原第9/10/11自然存档，剧情永久死亡与旧信物按真实所有权继承。

## 验收准备与未完成范围

先验证源文件哈希、所有场景/对白/效果引用、唯一步骤与奖账；再从真实最低/自然旧史入章。重点覆盖R04有无及旧四槽、R05两法/未接/中途/截止、B08每局合法角色及独立重试、韩后技能/雷前技能/采药兜底、不提前归队、两月真实阶段和伤损账、B09三人奇毒/免死/复苏/阶段/辨药、战后晓霜控制锁与非致命誓约。坏档、旧回调、重复确认不得写资源。

有显示环境另做完整键鼠路线、640/1280界面、暂停与F5实际写盘/新进程F9恢复。玩家应看见竹丝牵兵器、受力改变、药性与病征反馈、诗剑拆招和三方施救动作，而非检查表。当前没有凭本文声称真实GUI、成品像素、全作音乐或导出通过。
