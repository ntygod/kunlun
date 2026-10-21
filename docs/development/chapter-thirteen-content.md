# 第13章《南海鲸波》内容合同

基线为第12冻结候选5bb6efcd3a6ad4f676f91105bff25892e41aaab1；本章在独立feat/chapter-thirteen，不修改第12候选。V3 01/03/05/06/07/08为来源，冲突裁决见chapter-thirteen-source-review.md。tools/content/build_chapter_thirteen.py确定性生成两份内容JSON；目前26场、90步骤、114对白条目，包含8空间操作、4谜题和1场B10。它是可玩开发内容，不是2.50小时成品演出、成品像素/声音或GUI验收通过。

## 角色与因果

先回医棚接花生，再赴崖山兑现救童承诺，不宣称助宋复国。幼帝赵昺作为受护儿童活下来，陆秀夫投海死亡；云殊仅护童时临时结盟，不加入核心成长队列。背后一掌使梁萧失踪，船上人物只知道生死未卜。路线实际交替为柳修缆→梁鲸背→花生撑梁/晓霜护童换水→梁十三息→柳分水守夜/二女和解→梁救幼鲸→重返孤舟；不可提前让船上人物知道鲸背事实。

重聚结义后贺陀罗杀阿滩、毁船，玩家夺艇接应众人；快雪死亡不可被读档投影或技能复活，白痴儿/金灵儿/胭脂存活。荒岛悟掌、假病止战、明伪暗真造船，B10保留03/06云殊与贺陀罗两人并存活，不能以击杀替代真实起锚断后。返航幼帝自主弃帝学医。柳莺莺戴柳笠骑胭脂离开，留下书信/胭脂盒；不采用05留笠的冲突动作。离队事件永久记忆，人物仍活着、后章可归，不等于删角色或死亡。

每场显式controller；活跃机关与场景控制一致。scene控制使对白、菜单、读档都能接回正确人物，不能仅依赖live模型临时切主控。剧情伤势、失踪与死亡由campaign事务拥有，内容不修改自然存档。

## 接口与门槛

世界事件对应同名scene：world_ch13_yashan_rescue、storm_rigging、huasheng_brace、cabin_treatment、whale_harpoon、sinking_rescue、ship_materials、chaoyun_farewell。四机关分别pz_ch13_water_watch→ch13_water_council，pz_ch13_whale_breath→ch13_thirteen_breaths，pz_ch13_decoy_ship→ch13_hidden_ship，pz_ch13_star_navigation→ch13_star_navigation。B10为enc_ch13_island_departure→ch13_island_departure。地图入口ID/position/radius由world地图提供。

所有语义事务使用chapter_thirteen_event effect，分别等实际机关proof再授技能/改状态。分水choice_key=water_priority、选择ch13_water_vulnerable/workers，谜题上下文由campaign转换a/b；二女和解key=sisters_response；整备departure_loadout明确keep/recommended/alternate四槽；离别前departure_confirmation可继续或通过系统返回菜单，不补发旧支线。K01与R02回响使用memory_tag/memory_refs，未完成支线时普通对白，不伪造记忆/奖励。

主线2030XP中B10前累计485，机关PZ05完成另1500，B10胜后另500，之后主线剩1545；最低入口31565→B10前33550→章末35595。800铜仅章末一次，机关/演示/重放不重复发奖。LYY_A06/A07/N02/P03、HS_A04/P02、CO03、LX_N02/A05按事务节点获得，四主动/内功槽不因已学集合扩大。章末HXS_A03升3及常规已到期升阶由campaign统一执行。

## 已运行与待验

内容生成断言主线预算2030、B10前485；静态逐事件检查step唯一、refs/memory_refs、choice group、completion receipts及13个可操作入口全部存在，通过。实际campaign/replay、引擎输入和GUI由集成负责人分别记录；本内容工作不冒称运行过GUI或自然通关。源稿哈希写入source_mapping，开发脚本不修改V3原稿。
