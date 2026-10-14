# 第09章《功业成空》首版内容与定量合同

2026-10-14。基底第8冻结 `ad62466122023e71e6326c9479ec383fb1fc90cf` / tree `1d2e9eebc9769a9c67412f8f56f5414e7409b8db`，分支feat/chapter-nine。根负责人批准以下首版参数及source-decisions最终裁决。保留“候选”指尚未真实模型/GUI验证的开发候选，不表示列明数值尚未获批；新增或偏离必须再审。只提交两份文档，不实现生产、不操作GUI、不上传。

来源简称01—08及GBK物理行见chapter-nine-source-decisions。批准结果优先于其中保留的源审备选，禁止将互斥备选混入实现。

## 1. 16节点及预算（首版分额已获批，非V3原始分额）

|序|语义运行ID|内容/主来源|主线XP|
|---|---|---|---:|
|1|ch09_calendar_invitation|郭邀修历、拒绝继续杀伐的可能；03:407–423/原著4591–4596|40|
|2|ch09_shigong_confrontation|天地玄黄观阵、刺阿术/萧救/梁介入；06:461/原著4601–4668|70|
|3|ch09_pine_needle_lesson|碧微箭剧情传授、PZ-A实际完成；06:213–218/原著4768–4799|60|
|4|ch09_mountain_pursuit|贺挟雪、四种音器群强冲突、逃上绝峰；06:462/原著4857–4994|60|
|5|ch09_pine_prayer|阿雪祷树与自省选择；06:471/原著5005–5009|50|
|6|ch09_wood_bird_assembly|双人木鸟真实组装与试验；06:214–218/原著5010–5015|100|
|7|ch09_cloud_escape|解缆/掌托/滑翔/水落弃鸟；原著5019–5026|100|
|8|ch09_wang_ke_memorial|京口殉友死讯与真实L03回响；03:445–460/06:463|180|
|9|ch09_changzhou_retreat|云家死讯/守城者留守、止射云殊；06:464/原著5052–5072|80|
|10|ch09_prisoner_release|伤俘医治与释放；06:464/原著5073、5089|100|
|11|ch09_west_temple_window|L05世界窗口/暂停返回/选择前截止确认；06:1116–1142|120|
|12|ch09_blood_well|止乱兵必经遭遇/老妪同结局/扯披风；03:451–473|150|
|13|ch09_bayan_rupture|不可逆闯帐、重掌与空指回响；03:477–515|100|
|14|ch09_linan_banquet|临安降/哈里斯握手、唯一魔钻；03:518–543|100|
|15|ch09_western_order|修历被拒/西征令、整理行囊METHOD；06:466–470/原著5176–5199|100|
|16|ch09_abandon_seal|弃官事务/印甲/告别/雪同行逃亡、章界归档；06:473–474|120|

主线合计1530。PZ-A500在松针合法完成，PZ-B500在组装+双人解缆与成功逃峰完成（不能面板检查就领奖后不飞）；两个各500为候选拆分，源只给总1000。常州止兵唯一300遭遇，不在两个兵各发300。L05完整归档300含三流寇；无额外战斗XP。节点8、12、13、16静默入账，悲剧无升级烟花。

第11正常世界窗口可离开/返回，直到第13闯帐确认前仍可回L05。已批准保第13截止，血井后路口显示“先回救治点/去帅帐”，不反复播老妪死亡；不得私自把截止前挪第12。

## 2. 地图与动作候选

已批准8张实际空间（不把SC中跨城切镜当一张连通走廊）：石公山观阵台32×20、山路松台24×16、天都峰36×22、京口水营38×22、常州外城/断街38×22、西郊破庙及城隍枯井复合区30×20、常州帅帐16×12、临安行辕/孤山出口36×22。大小是候选；08仅给MAP17两子区32×20/36×22、MAP18 38×22/36×22、INT07 16×12。跨地图用清楚地名/时间过渡，不瞬移NPC偷做协作路径。

来源映射记录 `03:MAP-SHIGONG-MOUNTAIN-01 ↔ 06:MG15_HuangShan ↔ 08:MAP17A/B`；08:398“飞来峰”与06天都峰冲突，本章已批准名天都峰并保差异。京口/常州/临安分别语义ID映射03三个ID与06MG16/08MAP18，不按数字复用第8地图。临安08“抗元御营/二王行辕”属于后章语义，不提前摆二王。

动作预算候选：郭示圭与交竹简；三强短交锋；松针运劲；雪被挟与群音；祷树/梁悬斧；双人搬骨架/摇柄/解缆；木鸟滑轨→掌风→云海→漂去；李庭展示焦牌/交铁锤；梁闻死讯呕血；止箭、医官治俘/松绑；L05嗅药/递钥匙/三流寇退场；血井伸手落空；重掌/扶肩；幻魔手褪魔钻；整理首位行囊；解印脱袍挂甲；雪披旧衣/并肩出营。均是候选动画，不称成品。05 ACT11与08 ACT11严禁混绑。

## 3. PZ-04完整有限模型候选

### A 松针推阵（500XP）

定位为纸上/青石盘“有限教学阵”，不是声称三根针等于原著完整玄黄九变。5×5可见盘，东南生门(4,4)、中岳景门(2,2)、西北霜降阵眼(0,0)。公开可通路径依次(4,4)→(4,3)→(3,3)→(3,2)→(2,2)→(2,1)→(1,1)→(1,0)→(0,0)，其余格显示阵旗封锁。三根针唯一ID start/middle/end；按观察旗象确认生门、景门、中枢，先自由放三针，再“推演一拍”沿四邻路径推进领阵标记，不能只比最终坐标。

号角三相phase0/1/2公开循环；生门只phase0可入，中岳只phase1可过，阵眼只phase2可破。玩家可“等下一声号角”，或连续走一合法边（两者都使phase+1 mod3）；当前格与下一可走格、各门时窗常驻显示。撞旗/错误门窗拒绝、保持state且说明原因，不扣HP/MP/钱。提供跳到下一可用时窗的单步等待按钮，但实际记录必要wait次数而不跳移动。

纸面标准序列：先将三针放到(4,4)/(2,2)/(0,0)，初始phase0由盘外执行进入生门，进入后phase1；再依次走(4,3)[到后phase2]、(3,3)[0]、(3,2)[1]、(2,2)[2]、(2,1)[0]、(1,1)[1]、(1,0)[2]、(0,0)[0]。三门的进入前相位分别0/1/2，均合法；共进入1步+移动8步，摆针另3次，标准解无需等待。偏离后允许等待修正相位，不要求最短。这里只做静态规则复核，开发仍须独立穷举正式模型再将正式命令序列写入演示。

三层提示分别高亮旗象、解释三相开口、逐步执行合法place/wait/move。演示每步使用正式命令，停止立即撤销定时器，存档记assisted与当前盘而不自动续播。完成需三针正确、经过三个门且路径合法、阵眼达成；观阵/打开面板/播放演出都不领奖。松针只是场景筹，不给无限伤害暗器。

### B 木鸟（500XP）

有限配重教学，单位为“筹/格”，不是现实尺寸或航空设计。6件有限构件：机身1、左翼1、右翼1、尾舵1、骨架1、绞柄联动件1。配装选项：机身质量6；每翼轻松3/厚木5，左右须相同；尾舵薄片1/双薄片2；骨架直竹强度1/弯韧竹强度2；绞柄须连接两侧四风车。梁/雪模型载荷4/3，站位前梁-1/后梁+1；尾舵力臂+3，机身及翼0。骨架与绞柄的固定结构质量已含于机身6筹，不能再重复相加；总质量=6+两翼+尾舵+7，承载上限21；力矩=3×尾质量+4×梁位+3×雪位，要求-1（略前）；强度≥2，左右翼平衡，双柄/四风车连接完整。唯一公开标准解轻翼3+3、尾2、韧竹、两人前梁：质量21，力矩6−4−3=-1。厚翼超载、轻尾重心过前、后站重心后移，皆即时画清原因。

部件与人员须走可见四邻工作位；梁负责固定翼轴/绞柄，雪负责稳尾/递骨架/观察风口（不取决于新战斗技能）。只一个“推进施工拍”让已就位两人并行动作，不每块木头连续点确认。尝试装配/撤销不消耗永久财物。风向标只有“偏风/可借升力”两状态，试验显示可飞准备；实际逃峰仍包含固定失速/掌风，不把贺的无意一掌变成NPC听玩家命令帮忙。

PZ完成检查：材料来源已决/祷树事件、全部6构件合法、双方位置/联动、真实绞动/解缆/轨道行进、云海出口到达。失败回组装合法前态，不出现阿雪摔死分支。大鸟最终江面漂去只留记事，不入便携背包。材料已批准按06祷树后伐活松；不得再出现03拾枯木可无损造鸟的备选。

## 4. 战斗/场景遭遇候选与恢复

本章无编号Boss。三强与群音用互动过场/短目标段，不把萧千绝、公羊羽、贺陀罗打死，不擅自复制第20限定面板，不追加Boss经验。伯颜重掌固定叙事，不借B06数值。三强/群音已批准仅互动过场，不得擅自追加完整战斗。

必经300候选为血井两乱兵非致命卸刃：场景威胁计数2，不注册假2000生物HP。每兵两拍，第一拍公开举刀蓄势（0伤），第二拍意图1.30×130点梁，候选ATK130/K按基准Lv40=100+4×39×39/79。梁第一拍“察兵刃”（0MP、一行动），第二拍“架刃推离”（0MP、一行动、仅该已观察有效），该兵沿退场路径离开且取消这次伤害，威胁-1。同ID不能重复奖励。四个完整行动可零伤，合法非技能场景控制不授P03/三才回气。错误行动承伤后循环该兵两拍；公开能退回入口重试。这是已批准的场景解救，与03授首差异明确保留；不改成通用战斗或普通HP击杀。

L05三流寇建议沿用第8真实空间非致命交互：3唯一实体、先挡住药箱通路，借柱绕侧卸刃、引出门，各有可见路径，完成才给300支线总额。没有三个新Boss或额外900XP。两分支共享流寇去向但场景协作不同，不能只改一句文字。

恢复合同：血井遭遇前一次显式免费整备活着在场梁HP全满，MP完全保持；无独立通用战斗start调用。雪/柳不治、不重算等级、不共享恢复。受掌/呕血不数字扣血。retry恢复该场景原入口快照，不再执行整备/成长/奖励，不能多刷恢复。无L05、无药、最低合法与声明低HP必须实际验证；尚未实跑。

## 5. L05双方法与全部资源账

来源06:1116–1142。“完整七阶”实际列6项，运行可分勘查/开锁为两步但不伪源有第7项。

接取→查青杏纹/24格药与半卷本草→公开铜锁题/有限开锁→方法→协同排除流寇→分药与余话→归档。开锁建议三个刻槽按箱上公开标记对齐，不作为第三个PZ发奖；不设凭空密码或猜数。
A：询西侧轻伤兵→城隍枯井寻张郎中→真实扶回破庙路径→还箱→郎中主持配药。
B：雪按公开药签分药、梁置疑阵引巡骑→小喜子代师发药；不谎称已找到/救出张郎中。
所有分支拦住三流寇并将其驱离；药箱/24格药/本草仍属医者，不清空进玩家道具栏、不生成可售药品。归档才发钥匙唯一和采药辨味探索高亮，无HP药效/暗装备槽/战斗加成。未完成可暂停，闯帐确认后closed无XP/钥匙/记事；完成后永远不转未完成。第11回响按真实完成和A/B，不将无支线玩家说成见过郎中。

|资源|继承/获得/终态候选|
|---|---|
|自然梁|17665XP/Lv43，1027/1291HP，122/143MP；两槽P01/P03；A03 Lv2；无N01不凭章节授予|
|自然柳|暂离17665XP/Lv43，821/1032HP、83/120MP；本章与梁同XP，只有真实升级最大HP差额加当前，不回MP/召回|
|自然雪|0XP固定Lv23，236/480HP、75/75MP；场景同行，不授技能/升面板/恢复|
|最低|合法第8无旧支与无L04=15015XP/Lv40/1050铜；不能称0铜历史。章9必经结束17845/Lv44/1650铜；加L05=18145/Lv44/1650铜。|
|自然结尾|不做L05=20495/Lv47/3050铜；做L05=20795/Lv47/3050铜。HP/MP必须由真实玩法算，不在规划中伪报完成血蓝。|
|装备|第8梁HP160/MP20/ATK36/DEF24/SPD4保留，不叠、不在挂印时清空；第9无新标准阶；不升级暂离柳装备。|
|技能|不新增碧微箭战斗slot，仅剧情技巧；A01/A02已有等级、A03 Lv2继承；普通获得+2/+5章升阶按07:279现有规则归约，不能误把“本章九”统一所有技能升阶。P03不提前第14、P04不提前16；A04/N02留10/13条件。|
|旧独物|父书/托款仍四婶故居；鸟/盒按旧分支；血书寄/留不重造；扳指仍囊古歹；阴阳球destroyed；断弓two_halves；杨榷竹蚂蚱唯一梁持，杨/赵已死；王可此前活到本章固定亡。|
|第8药与星珠|方/膏/半年材料仍叙事不可售无HP；星珠A雪持/B仍留原枝，不因逃亡自动拾取。L04平安符仅完成者保有。|
|郭物|已批仅新测影竹简唯一，铜圭为郭持展示；不能送两件却说同一物。|
|王物|已批铁锤唯一新携带；焦牌归李庭、石留空帐且L03有条件回响，均无数值。|
|行囊选择|铁锤/竹简“置首位”不表示另一件销毁或复制；都存在时改变priority与一种探索提示特性（无材料折扣数值或战斗增益）；未选物保包内原owner。|
|魔钻|唯一完好、梁持、剧情不可售无数值；非朝廷赏赐，不随印甲消失。|
|新大木鸟|只场景建造→飞行→江面折翼漂离；旧小鸟绝不升级/消耗。|
|朝廷赏赐|印/袍/军功甲/独立金银箱集合只剧情标记，弃官统一location=linan_tent_rack，owner=camp；共用铜钱另账。不要做成可刷钱卖物。|
|L05|完整归档300XP、铜钥匙一件、MEM_L05、探索提示；医箱/本草/药归张郎中或小喜子。没有支线铜奖励。|
|章9总记事|MEM_MQ09_ABANDON_GENERAL_SEAL一次，另分松针、祷树、王可、俘虏、受掌、魔钻、METHOD、离营阶段证明；以稳定ID归约。|

无法从第8归档终态重建曾用MP/CD/P03层；第9新独立遭遇不能把第8本战3层带过来。既有自然档只一路，不作全部合法入口模板。

## 6. 可并行分工（本合同冻结后）

1. 内容/事务：16节点、来源hash/行号、奖励1530、全旧分支、L03/L04/L05跨章回响、弃官资产分层及bounded summary。按已冻结D9选择编写；不动旧refs。
2. 松针模型/UI：有限三相盘、可达性穷举、三层提示/可停演示、stable ID与正式输入重放，500收据。
3. 木鸟世界模型/UI：有限材料/配重有理整数、双人四邻施工、解缆与飞行阶段，500收据；不造新通用技能。
4. 常州/L05：必经300非致命候选与三流寇支线、暂停返回/截止确认/钥匙/医生归属；协作窗口的NPC真实状态。
5. 集成与安全审计：存档version迁移、导航/历史/奖励与资源绑定、独立进程验证、数据校验、全回归。与前四共享文件集中根合并，避免多worker改main/campaign_state。
6. 最后GUI独立所有者：冻结候选后的真实自然0—8入口接9，640×360/1280×720，F5实际写盘hash和内容匹配、独立重启/F9，分清连续自然与隔离回放。未冻结前不让GUI与生产同时漂移。

## 7. 验证矩阵及停止条件

- 合法历史：自然第8；真实0—8最低无L03/L04；托款/托书；鸟/盒/无；原血书寄/留；星珠A/B；L04A/B/未做；两被动任意合法两槽、单槽/空槽（若现规则允许），不假穷举全笛卡尔积。0铜仅独立压力。
- 奖账：1530+500+500+300；L05恰300；600铜一次；逐节点顺序与重复/skip/retry/archive不重复，离队柳同XP，雪记录除明确同行状态外不动。放弃赏赐不损共享配装/金币/任务药。
- 松针：错针/门时窗/非法跨格/非最短合法路；所有有效状态可达或可撤销；place重复/撤回、phase改写、fake win/proof/sync拒绝。提示不能直接set solved。
- 木鸟：左右不平衡/重翼/轻尾/站错/强度不足/柄缺一；总料守恒，负数/超界/重复部件拒绝；实际施工path→解缆→飞行→弃鸟缺一步不可完成。
- L05：A/B完整；未接/部分/暂停/返回；关窗取消无副作用，确认后无奖励；重复救郎中/分药/卸刃不复制；B不称郎中获救；只钥匙归玩家，药箱不成为无限药源。
- 连续性：王可必死、赵杨不复活；无全城获救分支；星珠B不自动回包；扳指不归来；无竹笛/银票幽灵；大木鸟不可跨章召唤；新英雄/二王/阿雪死/B06/A04不出现。
- 存读：三相盘中途、木鸟一翼/双人搬件、启动未解缆、L05A护送/B疑阵、闯帐确认未提交、已重伤、魔钻已取、行囊首位、弃官未归档各独立进程；恢复失败不能污染live；已完成摘要验证旧入口账而非信任自报HP。
- UI：正常规则/公式/目标都可见；少确认，不按下拉索引保存；箭头逻辑优先保持；示范启动/停止/Esc/F9/重开不会迟延自动走；提示/演示不承诺完全免失败但必须合法。
- 最低资源采用已批准场景模型可纸面零伤通关，仍须真跑证据；不得切换通用战斗。错误受击按既有K/DEF与减伤取整公式，重试恢复真实入口。
- 独立原第8自然档再次hash确认；严禁覆写旧原档。沿用第8教训：文件名不是证据，读真实token/phase/actors/hash确认。实际源档39290B/SHA41299aae21511c4a3913c9d15ec124b098c07470ab59fb6bc24d266606adf42e。

本次完成的是两份文档合同。尚未实施/模型实跑/测试/GUI/美术成品/音画/导出/release/远端发布。通用消耗品API与商店尚未做，medicine_uses=0只是占位，绝不声称已有2份实装。


## 8. 首版完整语义事件ID与事务边界

以下是待实现合同ID，尚非生产已注册。每个节点的事件按表内顺序执行；台词可分行但不得复制语义事务。旧事件ID/旧章摘要不改。节点统一终态事件 `evt_ch09_<节点短名>_complete` 发唯一 `reward_mq09_<节点短名>`，金额按第1节；不靠进入节点发奖。短名即上表ID去掉ch09_前缀。

|节点|顺序事件ID及含义|
|---|---|
|calendar_invitation|evt_ch09_guo_calendar_offer；evt_ch09_guo_show_bronze_gnomon（郭持）；evt_ch09_guo_give_shadow_slips（唯一竹简）；evt_ch09_calendar_invitation_complete|
|shigong_confrontation|evt_ch09_observe_xuanhuang；evt_ch09_gongyang_assault；evt_ch09_xiao_rescue_ashu；evt_ch09_liang_interpose；evt_ch09_shigong_confrontation_complete|
|pine_needle_lesson|evt_ch09_biwei_story_lesson；pz_ch09_pine_needle（正式操作入口）；evt_ch09_pine_proof_complete（唯一500）；evt_ch09_pine_needle_lesson_complete|
|mountain_pursuit|evt_ch09_he_abducts_axue；evt_ch09_four_instruments_clash；evt_ch09_escape_to_tiandu；evt_ch09_mountain_pursuit_complete|
|pine_prayer|choice_ch09_pine_prayer（惜命/还债）；evt_ch09_pine_prayer_recorded；evt_ch09_pine_harvest_authorized（场景唯一料源）；evt_ch09_pine_prayer_complete|
|wood_bird_assembly|pz_ch09_wood_bird_begin；evt_ch09_wood_bird_assembled（结构准备proof，无500）；evt_ch09_wood_bird_assembly_complete（节点100）|
|cloud_escape|evt_ch09_wood_bird_resume；evt_ch09_dual_crank_ready；evt_ch09_release_mooring；evt_ch09_launch_rail_traversed；evt_ch09_fixed_stall；evt_ch09_he_palm_lift；evt_ch09_cloud_exit_reached；evt_ch09_water_landing；evt_ch09_wood_bird_drifted；evt_ch09_wood_bird_proof_complete（唯一500）；evt_ch09_cloud_escape_complete（节点100）|
|wang_ke_memorial|evt_ch09_wang_ke_death_news；evt_ch09_liting_shows_charred_tag；evt_ch09_l03_stone_echo（真实L03才播放，石留帐）；evt_ch09_liting_gives_wang_hammer；evt_ch09_wang_ke_memorial_complete|
|changzhou_retreat|evt_ch09_yun_family_death_news；evt_ch09_jin_fang_last_defense；evt_ch09_stop_shooting_yun；evt_ch09_changzhou_retreat_complete|
|prisoner_release|evt_ch09_prisoners_protected；evt_ch09_physician_treats_prisoners；evt_ch09_prisoners_released；evt_ch09_prisoner_release_complete|
|west_temple_window|evt_ch09_l05_window_open；side_ch09_l05（可接/不接，可暂停，允许L05）；evt_ch09_west_temple_window_complete（离开节点11才一次结算120，完成不强迫支线完成）|
|blood_well|evt_ch09_blood_well_rest（一次梁HP）；enc_ch09_well_disarm（两兵威胁）；evt_ch09_well_disarm_complete（唯一300）；choice_ch09_well_response（抢救/僵立）；evt_ch09_well_fixed_loss；evt_ch09_discard_general_cloak；evt_ch09_blood_well_complete|
|bayan_rupture|confirm_ch09_enter_command_tent（可取消/回L05）；evt_ch09_l05_window_closed；evt_ch09_confront_bayan；evt_ch09_bayan_story_wound；choice_ch09_sever_old_favor（空指/冷言）；evt_ch09_bayan_rupture_complete|
|linan_banquet|evt_ch09_linan_surrender；evt_ch09_harris_handshake；evt_ch09_take_serpent_diamond；evt_ch09_linan_banquet_complete|
|western_order|evt_ch09_calendar_petition_rejected；evt_ch09_western_campaign_order；choice_ch09_pack_priority（锤/竹简）；evt_ch09_pack_priority_recorded；evt_ch09_western_order_complete|
|abandon_seal|choice_ch09_farewell_tone（珍重故人/与雪同行，两口吻不增赠物/承诺）；evt_ch09_leave_court_rewards；evt_ch09_hang_seal_and_armor；evt_ch09_axue_travels_with_liang；evt_ch09_leave_linan_gate；evt_ch09_abandon_seal_complete；evt_ch09_archive_mq09（MEM_MQ09及600铜一次）|

行囊首位两选的有效物品需已存在：锤由节点8交、简由节点1交；任一缺失是存档/事务错误，不自动补造。辞别口吻为源抉择的已批准适配，不冒称原台词；文本不得在珍重故人路发旧竹笛或银票。

L05事件：`side_ch09_l05_accept` → `side_ch09_l05_inspect_box` → `side_ch09_l05_unlock_box` → `choice_ch09_l05_method`。A实际命令链 `side_ch09_l05_question_wounded` → `side_ch09_l05_find_physician` → `side_ch09_l05_escort_physician` → `side_ch09_l05_return_box`；B链 `side_ch09_l05_axue_sort_medicine` → `side_ch09_l05_place_decoys` → `side_ch09_l05_lure_patrol` → `side_ch09_l05_xixizi_distribute`。共通 `side_ch09_l05_disarm_raiders`（r1/r2/r3真实退场）→ `side_ch09_l05_finish_treatment` → `side_ch09_l05_aftermath` → `side_ch09_l05_archive`（唯一reward_ch09_l05=300、钥匙/MEM/探索特性）。其中协作可交错，状态图保存真实先后，不要求一按钮瞬移走完全链；归档必须选定方法全部前置满足。

奖励独立稳定ID：`reward_mq09_pine_once=500`、`reward_mq09_wood_bird_once=500`、`reward_mq09_well_encounter_once=300`、`reward_ch09_l05=300`、`currency_mq09_once=600`。命令拒绝/暂停/重试不创建收据，归档回放不再增长。受掌、闻死、固定失速与弃印本身不隐含新数值奖/扣费。

## 9. 木鸟跨节点proof与存档连续性合同

一个持久机关ID `pz_ch09_wood_bird`、schema版本1；不是节点6/7各一只鸟。状态枚举 `collecting / assembling / prepared / cranking / mooring_released / rail_moving / stalled / palm_lifted / cloud_exit / water_landed / drifted / completed`。状态沿合法事件单向推进；装配阶段可合法撤回，解缆后不准回改材质而不重试。

持久记录至少含：唯一id/version、来源节点及已经确认的祷树选择/取材receipt、六件ID/规格/唯一归属、四连接状态、有限材料守恒、公开质量/力矩/强度计算输入、梁雪工作位/连续路径/当前搬件、双柄进度、命令revision/token、演示assisted/停止状态、解缆flag、轨道位置与合法有向路径、失速/掌托/云海/水落/漂去各唯一阶段标记、跨节点历史前缀、entry checkpoint、prepared checkpoint、两节点主线收据与PZ500收据。

1. 节点5取材授权只生成一次场景材料，无可售库存；携带的旧竹鸟完全独立。六件是body/left_wing/right_wing/tail/frame/linkage；frame/linkage质量含body6，不再加。四风车连接为linkage的四条边，不新增四个部件或料源。
2. 节点6全部组装计算/空间动作真实完成才令prepared。将同一模型的可验证摘要及完整合法命令前缀写入campaign/world导航持久状态，随后发该节点100XP。此时PZ500尚不存在。
3. 节点7从campaign信任的prepared记录恢复同一个id，不能用UI自报prepared/新session默认满料覆盖。合法主线100成长由PartyProgression处理；梁雪资源来自当前campaign，不从旧机关入口快照覆盖成长。木鸟本身从不治HP/MP或重置两槽。
4. 节点7双人绞动、解缆和沿轨移动用正式命令；之后固定失速/掌托是依条件触发的剧情阶段，只能在轨道终点出现，不允许未造鸟就跳片获得飞行。云海、落水、折翼作桨/漂去阶段保存唯一结果，不成为可反复取材动作。
5. `evt_ch09_wood_bird_proof_complete`只在全部阶段达到drifted且双方脱险、模型/素材/连续路径proof通过后发PZ500；随后节点7发100并归档该机关为completed。比“云海出口”更晚的一次结算符合完整成功逃峰proof，不会提前领500而未水落收束。
6. F5/F9/导航切换可保存任一阶段；恢复验证必须从可信入口与已验证节点6前缀重放，或由正式bounded摘要验证规则验证已完成部分。禁止外来sync/resume/set_phase/grant_reward伪装玩家输入；阶段flags与history自洽但来源不可信也应拒绝，且不污染live。
7. 错误试装回合法编辑态不扣资源。解缆后若允许显式重试，只回同一prepared checkpoint并保留已发节点6奖；不得新生成材料、重发节点100或500、重置角色MP。固定失速不是失败菜单或阿雪死亡，正常只进入掌托阶段。
8. 演示不能越节点6完成自动替用户离开当前剧情，暂停/菜单/读档取消自动回调；手动继续仍复用合法命令。跳过仅跳已满足条件的演出，不能将机关输入变成set_completed。

## 10. 补充微参数、空间实施权限及待验范围

根已批准：铜锁三个轮各可选叶/花/果，箱上公开左叶/中花/右果，一次提交核验，错误无成本可撤回，无额外PZ经验。两乱兵每个两拍，第一拍只允许察刃建立本次观察，第二拍已观察才可架刃推离；错过/受击清本次观察再开该兵循环。错选已退兵拒绝不耗行动；失败retry恢复同一真实入口快照。骨架/绞柄重量已含机身6、四连接不额增部件，见第9节。

原报告8张地图的精确碰撞/安全路径格位由world实现者在获批尺寸中选定并记录，须实BFS与独立验证。只要不变剧情、模型数值、资源或窗口因果，不逐格再报根；新增伤害、额外物料、传送、恢复、关闭窗口或奖励变化仍需根批准。此权限不等于布局已完成或可玩。

模型必须可观察地表现阵盘时窗、木鸟质量/力矩/联动、NPC出入口；按稳定ID归约而非控件index。三层提示逐层解释，最终演示真实命令、可停、可存读；固定合法路径不表示已验所有GUI误操作。新合同不修改第8逻辑方向键冻结补丁。


### 实施期节点11顺序澄清（2026-10-14 22:17 UTC）

根批准实际节点内顺序为 open → 可暂停window/可选L05 → complete。既有窗口token保留，120XP仍只在离开节点11主线收束时发一次；重复进出破庙不再次发120。此处只澄清节点内事件编排，第13闯帐最终确认的L05截止不变；没有将截止前移或将完成支线变成必经。
