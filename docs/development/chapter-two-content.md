# 第02章《天机求学》内容契约与来源裁决

日期：2026-10-13。最初内容契约交付为 `game/data/chapter_two.json` 与本文，当时未改引擎；随后程序接入情况见第10节。V3权威来源与原著保持不变。

## 1. 边界与完整性

本文件最初为未注册内容契约；现已显式接入19节点开发流程，自动验证与实际GUI覆盖见末节和开发计划。尚未达到成品第02章质量，更不是完整游戏。`schema_version=2` 是内容字段提案，不承诺已支持的存档版本；`content_contract=chapter_two_content_contract_draft_v1` 与能力检查须显式注册，不能因为第一章正在接入就推定本文件可被同一加载器直接接受。

本轮读取了根 AGENTS/README、game/README、开发计划与第一章契约；完整读取上卷第02章四场、06的MQ-02/PZ-01/R01/K01与MQ-03出口，核对01人物/编队、05动作/配音、07当前80级成长与技能、08资源映射，并检索03/04后章物件与动物回响。原著仅使用用户仓库的GBK文本，没有外爬。

- 19个主线事件节点，覆盖MQ-02全部六步骤
- 4份完整SC逐字档案，附1基源行号、SHA256；原SC共38个引文单元，运行列表共89个对白/舞台单元，附10条支线原对白
- 8个原SC局部选项、2个任务应对选项、4个支线方法选项，共14个稳定choice ID；窗口继续/第十算歇手是额外必经确认，不伪称原分支
- 11个独立语义地图、4个语义动作映射、2个有真实目标的遭遇契约
- 1个PZ-01契约含9个有限演示题、1个明确无有限解盘的第十算收束；R01与K01各有独立执行凭据
- 71个主场完成凭据要求。它们是接口契约，不表示相应程序控制器已经存在
- 主线2.50小时、两支线各25分钟是源目标；未实测，不以文字量推定时长完成

完整归档解决“不遗漏来源”，并不意味着镜头、地图、关卡、动画、音频、战斗或谜题控制器已做好。九算小型演示题明确标作实施补写，只服务交互表现，不能宣传为原著九道高阶问题的完整数学求解。

## 2. 原SC完整保留

| 原场 | 权威源行号 | 运行节点 | 完整档案与运行规则 |
|---|---|---|---|
| SC-02-01 | 02:453–497 | west_lake_rescue / west_lake_secret | 误伤之前的因果另有任务补场；10原引文单位全部留存，归档中保留两分支原反馈 |
| SC-02-02 | 02:499–537 | array_abandonment / statue_shadows | 8原单位拆为被弃4个、月影4个；踏影必须验证后才能播已悟武反馈 |
| SC-02-03 | 02:539–584 | lamp_lesson | 11原单位；引笔之前进入写字操作，学会靖不等于改写墓碑 |
| SC-02-04 | 02:586–628 | tenth_sum_crisis | 9原单位；过载→劝慰→歇手→分支，绝不以“算出第十题”通关 |

每条原人物台词分开存 `text` 与 `stage_direction`；独立舞台行标 `kind=stage` / `player_dialogue=false`。完整导演知情账只在 `source_archive`，绝不可直接显示为主角知识或玩家对白。补场与修订反馈标 `implementation_adaptation` 等来源；`effective_dialogue_overrides` 必须在播放前应用，不能一边播原冲突台词、一边仅靠文档解释。

## 3. 主线场次与完成门槛

| 节点ID | 步 | 内容 | 必须取得的完成凭据 |
|---|---:|---|---|
| ch02_luzhou_pursuit | 1 | 庐州流浪 · 逃出生天 | luzhou_escape_route_safe, qin_rescue_performance, ch02_gear_received |
| ch02_chess_prank | 1 | 千钧棋局 · 好意闯祸 | chess_board_observed, prank_consequence_seen, pursuer_discovered |
| ch02_protect_qin | 1 | 折返棋坳 · 舍命护恩 | enc_ch02_protect_qin_result, sword_retrieved, qin_sheltered_and_watered |
| ch02_west_lake_visit | 2 | 西湖初望 · 病女出门 | xiaoshuang_medicine_packed, xiaoshuang_willow_bank_reached, liang_control_restored |
| ch02_west_lake_rescue | 2 | 画舫斗气 · 背负求医 | zhang_san_aftermath_seen, monkey_rescued, capsize_and_injury_seen, xiaoshuang_delivered_to_villa |
| ch02_west_lake_secret | 2 | 听雨轩 · 相护的秘密 | mq02_responsibility_choice_recorded, ch02_01_branch_performed |
| ch02_pavilion_scout | 3 | 十里长亭 · 护药察变 | pavilion_injury_observed, pavilion_exit_observed, pavilion_liang_control_restored |
| ch02_pavilion_antidote | 3 | 长亭脱困 · 智取解药 | mongolian_intel_interpreted, enc_ch02_antidote_escape_result, qingyuan_antidote_administered, family_pavilion_escape |
| ch02_valley_journey | 4 | 彩贝峡 · 木牛千里舟 | valley_transit_complete, wooden_ox_observed, water_power_observed, route_warning_seen |
| ch02_array_abandonment | 4 | 两仪幻尘 · 独留月下 | array_entry_route, xiaoshuang_story_medicine_given, xiaoshuang_removed_safe, liang_alone_in_array |
| ch02_statue_shadows | 4 | 圣贤留影 · 求己之始 | shadow_motion_observed, shadow_practice_verified, ch02_02_branch_performed, qingyuan_rescue_reached |
| ch02_ten_sums_oath | 5 | 琴心水榭 · 十算之约 | ten_problem_inscriptions_observed, oath_recorded, study_room_unlocked |
| ch02_lamp_lesson | 5 | 灯下授字 · 靖字之解 | jing_written_on_practice_paper, ch02_03_branch_performed, qingxin_inkstone_received |
| ch02_study_window | 5 | 寒窗初年 · 错稿与日影 | r01_window_disposition, k01_window_disposition, study_window_continue_confirmed |
| ch02_isolation | 5 | 灯影远去 · 独自求索 | optional_windows_closed, xiaoshuang_visits_restricted, isolation_world_state_set |
| ch02_four_seasons | 5 | 五载寒窗 · 四时不辍 | season_spring_observation, season_summer_manipulation, season_autumn_note_sort, season_winter_recopy, five_years_time_milestone |
| ch02_nine_sums | 5 | 九算攻克 · 水枢贯通 | pz01_problem_01, pz01_problem_02, pz01_problem_03, pz01_problem_04, pz01_problem_05, pz01_problem_06, pz01_problem_07, pz01_problem_08, pz01_problem_09 |
| ch02_tenth_sum_crisis | 6 | 元外之元 · 天地有缺 | pz01_tenth_overload_seen, accept_imperfection_choice, ch02_04_branch_performed, pz01_nine_plus_acceptance_complete |
| ch02_morning_departure | 6 | 病愈清晨 · 可恃唯我 | jing_book_inspected, recovery_corridor_walk, ch02_export_inventory_verified, ch03_exit_requested |

所有节点显式要求前一节点完成，章末要求全部18个前场。`event_sequence` 是面向实现者的操作顺序，不是已有引擎命令，不得照字符串自动递增scene index就视作完成。

### 两场遭遇不能替换成按钮

- 棋坳护恩：梁萧单人战术控制，秦伯符是受保护伤者，九如为剧情支援。玩家依据铁索意图与地形护住秦伯符，完成两次真实敌动作结算后，九如援手条件方可开放。胜利是何嵩阳退去、秦伯符获救，不能让Lv4少年直接清空高手血条。“两次”是实施目标草案，待配平验证，不称原著指定回合数。
- 长亭解药：实际侦听→假投诚接近→窗口内制住脱欢→核对解药交换→给花清渊服药→非致命阻追→护送至出口。花晓霜不能因此被加入战斗队或成为可杀目标。原文断马筋阻追作为短促离镜演出，不做伤害动物操作教学，也不擅换成杀人过关。
- 两场各60XP是120XP章节预算的实施拆分，不是V3逐战数值。固定关卡基准提议Lv4/Lv5，对应入场445/505累计XP；K=100+4×39×(基准等级−1)/79，不能随玩家等级动态抬高。敌面板、完整意图轮换、场景碰撞与实际胜率仍待接入配平。
- 遭遇收据由可信目标解析器生成，带attempt、输入/引擎事件、前后状态摘要；UI不能提交 `won=true`。失败还原战前，不推进、不发XP、不丢信物。演出支援也须验证其目标条件，不能把“九如出手”按钮当战斗。

### PZ-01与九算

源文PZ-01只有三阶段纲要，未提供所有九题可计算输入。本契约补了明确标注的简化教学样例，并把“研究蒙太奇的九项成果”与“小样例的算术答案”区分开：

1. 天地生成解：1–9独占九格，中心5，横竖斜八线15
2. 太玄两难上：12与8两盘移2筹，得10与10
3. 太玄两难下：a+b=9、a−b=3，验证a=6、b=3
4. 双手十指题：十位二进制按512→1权重，分别表示5、13、42
5. 二十八宿：28格仪器从0每次转7，观察0/7/14/21并回0
6. 治河图：纸上渠模型12×3×2=72立方尺，不是已完成黄河治水
7. 鬼谷子问：逐层搭1/3/6/10筹并总计20
8. 子午线：明确虚构比例模型3度对应300里，推演一周36000里，不当作真实地球测量结论
9. 日变奇算：五个未知量的简化联式，a+b=3、b+c=5、c+d=7、d+e=9、a+e=6；逐式代回验证1/2/3/4/5

第十算没有“正确九宫布局”。一次明确操作可见关系继续发散，随后进入执念与劝慰演出，玩家主动歇手方完成。不能要求无限尝试或数学能力才能继续，也不能把演示发散称为任意元问题的数学不可解证明。

每题三层提示：观察实物→展示约束/公式→逐步演示合法操作。源允许故事模式第三层协助，但实现必须显式选择、演示真实操作、调用相同校验器并记录assisted；略过对白不得替代任何解谜。R01错误提示仅高亮真正正确的构件；K01只增加几何参考线，不自动把所有机关判成成功。

## 4. 支线与时间窗口

R01未合算册：散纸发现→三张各三片比对→确认第三张有效中段→选择全册保留或晓霜代存首张→糊封面/穿线/题名→分食静默→归档。保留分支都授同一记事，另记录册页变体与代存页所有权。源说“七阶”，条目合并为六步，本契约将接取/勘查/抉择/执行/余波/归档与未发现状态显式列出。400XP仅归档一次；“试错反三”为机关辅助，不虚构战斗被动数值。

K01日影初算：在首年、隔离前的晴日露台窗口完成。支线卡原写中期，与主线隔离冲突，采用父线程同意的最小移窗方向，待最终集成审阅。两条支线都可明确放弃/稍后再说；走入隔离前给一次截止提醒，未完成写missed、不发奖励，不阻塞主线。源20章总截止表仍提K01，不解释为允许20章凭空重开童年任务。

### K01可复算数据

源只给八尺杆、四尺影、百步间距，没有退距或峰影，不能推出“八百丈”。不硬凑该答案：

- 使用同一标定几何模型，地面水平、杆竖直且等高8尺；游戏测量单位明确1步=6尺，1丈=10尺（不宣称宋元各地单位一律相同）
- 两杆间距100步=600尺；对同一峰顶齐杆瞄线，近杆后退12尺、远杆后退18尺
- 重差法：H=8+8×600/(18−12)=808尺；近杆到峰脚水平距600×12/6=1200尺，用来交叉核验图形
- 相似法：同场可量的地面模型显示杆影4尺、峰影404尺；H/404=8/4，所以H=808尺
- 两法求同一个峰高808尺=80丈8尺，不是800丈。现实山脚不可达，因此第二法使用可测影端点的标定模型，不能暗中假定山脚/山影可走到
- 必须先在世界量出数据，再选方法、记录单位换算、建立等式、提交图样。零/负退距差、错单位、不一致几何都拒绝；分支按钮本身不产生成功凭据
- 得250XP、《重差测天图说》与辅助虚线。LX_A04只记未来强化资格；第10章基础技仍锁，未定强化档不猜数字

## 5. 角色、知识、物品与成长

- 主控梁萧，MQ-01已完成/累计345XP/Lv4进入，不重置XP、不继承文靖固定面板。文靖永久死亡、玉翎暂离未死、白痴儿仍在，长剑保留；可选草纸有则带入，无则不凭空补发。
- 漂泊段承接10岁→SC-02-01十一岁；初年冬12岁；求学五年后16岁。晓霜对应10/11/15岁。年龄随故事推进，不能用等级当年龄。01六年概览与02三年赌约留在冲突账，运行按MQ-02五年主线，不制造三年驱逐软锁。
- 花晓霜只在西湖、长亭短探索切换，随后归还梁萧操控。07中HXS_A01/A02“已掌握”可作角色知识，不授权她参战；第02/03章仍梁萧单人。花生只幼年NPC，秦伯符/花清渊/九如是剧情支援。
- 本章475主线+500PZ+120必经遭遇=1095；继承345后1440=Lv10。R01/K01全做再加650=2090=Lv12（Lv13阈2190）。不额外叠首领XP，没有本章B01。
- 主线100在入章秦救后、100在入谷、275在章末；两遭遇60+60，机关500在九算及接纳留缺全部完成后结算。各类总额均不超章节预算，数值拆分是实施提案。
- 铜钱250章末一次发，标准装备免费提前配齐。第02章标准加成HP30/MP5/ATK8/DEF5/SPD1，替换前阶，不能与第01章标准套叠加。Lv10裸板327/61/50/29/19，穿标准套357/66/58/34/20。
- 80级公式TotalXP(L)=100(L−1)+15(L−1)(L−2)/2；成长x=39(L−1)/79。不复用旧40级表，不把技能Lv1–3与人物80级混淆。
- 九算后LX_A01升2，接纳第十算留白后授LX_P01，两支原选择都能拿主线技能。幻尘身法、大贤心经、九九步义理与可恃唯我作知识/演出；源分支永久速度+2、悟性+5、终极心性、天行剑不直接改战斗面板。飞星九宫剑第06章、滴水穿石劲第10章、后期天行谐律等均不提前发。
- 靖字只写练纸和算册，父坟还是“梁文”残碑，第15章才真正补碑。
- 清心砚必经获得，不让第03章换质道具来自可选支线。材质生铁/青石及受击口径待第03章裁决；现在不锁素材也不提前做四成减伤。
- 未合算册、代存页、测天图说、御寒袍、白梅素帕作为持久记录；第十算焚稿仅烧本题散页。解药为一次性任务用物，交换/服用须同事务防复制；晓霜药瓶不作为可无限刷的通用药。
- 金灵儿为金猴、白痴儿为白犬，非战斗跟随者。后章同名文本误写灵貂/人形，不能据同名替换当前种族与身份。
- 梁萧此时不知道九阴绝脉的完整真相、花无媸骗局或所有长辈不会第十算，仍由MQ-03药王亭/开天大典揭露。第九算成果不写入全谷NPC知识。

## 6. 地图与动作命名空间

| 语义运行地图 | 名称 | 来源映射 |
|---|---|---|
| map_ch02_luzhou_road | 庐州城外追捕路 | quest06:MG04_LinAn/MQ-02 Step1 |
| map_ch02_chess_hollow | 千钧棋坳 | quest06:MG04_LinAn/MQ-02 Step1 |
| map_ch02_west_lake | 西湖柳岸与画舫 | script02:MAP-04-A；quest06:MG04_LinAn；art08:MAP-04/04B |
| map_ch02_linan_villa | 临安天机别府听雨轩 | script02:MAP-04-A；quest06:MG04_LinAn；art08:MAP-04/04A；art08:INT-02 |
| map_ch02_long_pavilion | 十里长亭 | quest06:MG04_LinAn/MQ-02 Step3；art08:MAP-04/04B |
| map_ch02_valley_transit | 彩贝峡与千里船入谷 | quest06:MG06_TianJi_Outer/MQ-02 Step4 |
| map_ch02_statue_array | 栖月谷两仪幻尘阵 | script02:MAP-05-A；quest06:MG06_TianJi_Outer；art08:MAP-07/07A |
| map_ch02_waterwheel | 天池浑天水枢 | quest06:PZ-01；art08:MAP-07/07B |
| map_ch02_study | 风骚小筑算室 | script02:MAP-05-B；quest06:MG06_TianJi_Outer；art08:MAP-08/08B；art08:REV-01 |
| map_ch02_terrace | 灵台测影露台 | quest06:K01/MG06；art08:MAP-08/08A |
| map_ch02_tianyuan_chamber | 天元阁藏经静室 | script02:MAP-05-C；quest06:MQ-02 Step6；art08:MAP-08/08B |

脚本MAP-05-A是天机石阵，美术MAP-05/05A却是姑苏街巷；运行不按05号码绑图。学舍20×14室内与美术38×22北院外景、柳岸别府合场36×20与美术40×22/32×22也不能互当已完成地图。所有asset_path=null，未给权威尺寸的补图不伪造“V3面积”。

脚本ACT-03是授字递卷，05 ACT-03指第十算，08 ACT-03是抢拽伸手、ACT-04才是十算劝慰。授字与劝慰拆开语义动作；05 VO-02-01错误关联石阵而说西湖包扎，不能直接以编号接音频。世界320×180最近邻整数缩放、中文UI独立高清，暂取更保守底部48px安全带；曲目和环境声均只是需求名，没有音频资产。

## 7. 来源冲突与最小裁决

以下“父线程方向同意”仅表示可继续准备实现侧内容，仍不重写V3。未决项不能做成玩家的解锁按钮或伪称已消失。

| 问题 | 来源证据 | 最小裁决 / 状态 |
|---|---|---|
| 源第三层[2,9,4;3,5,7;8,1,6]左右列与两条斜线为13或17，非15。 | quest06:PZ-01 lines192-197 | 使用[4,9,2;3,5,7;8,1,6]；八线自动验15。（resolved_parent_direction） |
| 三年期限、五年寒窗、六年概览并存；11/12/16岁跳时。 | script02:SC-02-03 lines548,566;SC-02-04 lines590-596;character01 line66;quest06 lines308-309;novel lines2291-2294 | 五年求学以MQ-02为准，入谷11、首年冬12、章末16。三年旧约留来源，不设驱逐计时；运行台词改“十道天机算题”，不擅编续约情节。年龄只随剧情里程碑。（implementation_direction_pending_final_integration_review） |
| 中期协作与第一年后隔离冲突。 | quest06 lines308,1178-1179;novel line2291 | 两条支线都在首年隔离前窗口，错过标missed，不堵九算主线。（implementation_direction_pending_final_integration_review） |
| 8尺/4尺/100步未给退距；不能推出800丈。 | quest06 lines1186-1197 | 教学测量模型补退距12/18尺、基线600尺、峰影404尺；两法都算808尺=80丈8尺，非800丈。（implementation_direction_pending_final_integration_review） |
| 02全谷知九算与03旁人惊讶矛盾；第三提示提前揭无解骗局。 | script02:SC-02-04 line616;SC-03-02 lines687-689;novel lines2297,2301,2420 | 仅梁萧/晓霜知成绩，删全谷上下谁人不知；不在PZ提示告诉玩家花无媸设局，MQ-03揭晓。（implementation_direction_pending_final_integration_review） |
| 速度+2、悟性+5、终极心性/天行剑/九九步与07正式节点不符。 | script02:SC-02-02 choices;SC-02-03 choices;SC-02-04 choices;combat07 lines306,308-310,329;novel line2321 | 本章只升LX_A01至2并授LX_P01；大贤、幻尘、九九步保留叙事领悟。无未定义永久面板加成。（implementation_direction_pending_final_integration_review） |
| K01可提前强化LX_A04，但基础技能第10章才授；强化具体级数未写。 | combat07 lines309,315 | 仅记录未来强化资格，不提前授基础技能或猜Lv2/3。（implementation_direction_pending_final_integration_review） |
| 焚所有草稿会吞掉后章必要信物/错页。 | script02:SC-02-04 line623 and choiceA;quest06:R01 lines781-783 | 火盆只允许当前第十算散页；未合算册、代存错页与图说永久留存。（implementation_continuity_rule） |
| 生铁残砚与青石砚台；源SC编号亦误配。 | script02 line1506;quest06:MQ-03 Step5 lines331,336 | 本章只绑定清心砚语义和归属，不锁材质/受击动画；第03章接入前裁决。（unresolved_review_before_ch03） |
| 后章把金猴写灵貂、白犬写人形至亲。 | script03 lines732,752;script04 lines114,130-132;novel lines1893,2153 | 父线程确认本章固定白犬/金猴独立非战斗ID，后章不按名字绑人形或灵貂；原文保留回查。（resolved_parent_direction_for_runtime_identity） |
| V3写晓霜姐姐并称凌为娘；原著为花清渊妹妹、晓霜姑姑；06又写兄长衣袖。 | script02:SC-02-01 lines459,478;quest06 MQ-02 local response;novel lines2269-2273 | 父线程亲读原著2269–2274确认兄妹/姑姑关系，运行娘→嫂嫂、妹妹→晓霜、姐姐→姑姑；06袖口演出中性化，原SC全文保留。（resolved_parent_verified_novel） |
| 同号不同地点动作；VO-02-01绑SC-02-02却写西湖。 | script02:MAP-05-A/B/C and ACT-03;voice05:ACT-03/VO-02-01;art08:MAP-05/MAP-07/MAP-08/ACT-03/04 | 全部按文档+ID命名空间，地图候选按语义；灯下授字、十算劝慰分开动作ID，声音未制作不硬绑。（semantic_mapping_only） |
| 算尽黄河治水可能误读成未来实绩。 | script02:SC-02-04 line612;novel line2295 | 保留台词，knowledge仅paper_river_volume，不给MQ-08/MQ-18完成或记事。（resolved_parent_direction） |
| 花无媸真实动机属于导演知情账，不应提前成为梁萧可见剧情日志。 | script02:SC-02-03 metadata;quest06:MQ-03 knowledge ledger | source_archive为编辑资料不播出；第02章玩家日志只见求学赌约。（implementation_continuity_rule） |

时序补缝：石阵独困在十算立约之前，原独白“花老太婆也不肯教”会预设尚未发生的拒教；运行最小改为“也不知花家肯不肯教”，原话仍完整归档。

另：R01正文第三页差“一筹”、对白写“三筹”是原文微差，本契约片段美术未制作，不拿这个数字充当验证答案；有效中段是实际完成凭据。原文“第十算无人能解”是角色/时代认知，不作数学绝对不可解的科普命题。

## 8. 第03章出口与实现依赖

章末提交所有主场、PZ-01九算+歇手凭据、成长/物品/支线关闭/记事账，再请求MQ-03“药王茶叙·始知寒毒”。仍梁萧单人战斗、晓霜剧情支持，携清心砚、原长剑、猴犬、已获信物及稳定选择ID。不得预置B01获胜、解出第十算、药王真相或花无媸骗局已揭露。目标章节不存在时应显示真实开发终点，不能空白场或伪通关。

集成至少需要：

1. 显式章节能力登记与版本化迁移；验证旧档、首次入章、异常退出、损坏档，不覆写第一章有效存档
2. typed speech/stage演出系统，按来源覆盖与分支条件播放；角色知识与导演知情分离
3. 两场完整遭遇配置、真实敌意图与非致命阶段目标；场景支援不是队伍入列
4. 世界物件联动算筹面板、可验证手势/描字/踩影/季节/测量操作，禁止跳过生成胜利凭据
5. 支线七状态、截止提醒、未完成退出、变体册页所有权与回响；支线缺失不造成主线软锁
6. 场次、输入恢复、控制角色、物品、世界状态、技能、经验、铜钱在同一幂等事务；正常/略过/重试/载入终态一致
7. 11张图布局、四季版本、少年代际形象、手工像素动作/音频、字体新字、世界/UI实际视觉检查
8. 亲属纠正覆盖检查与砚材质未决项整合审阅；后章动物与回响单独核对，不能把疑点静默写成新正典

## 9. 验证记录

本轮独立只读Python校验实际运行：JSON/ID唯一性、地图与前置链、四份SC逐字/散列/行号、38原引文覆盖、角色在场、14稳定选项、71完成凭据归属、经验分项与80级阈值、固定遭遇基准、标准装备、有效洛书八线、三组二进制、五元示例代入、K01单位/两式一致、禁授后章技能、章末出口与未注册声明。

实际结果：190项独立静态断言通过，0失败；随后补入石阵独白时序纠正，另验原档未改、纠正索引/在场角色/未注册状态，4项通过。没有修改或调用会改写设计输出的数值审计脚本；没有修改任何测试文件。既有程序测试不覆盖未注册的本章，所以不借其绿灯冒称本章可玩。

未运行：Godot本章接入/启动、所有分支正常与略过播放、全部存读档、战斗配平、谜题实操、地图/字体/像素/声音视觉、2.50小时节奏和导出构建。以上均仍是制作与验收门槛。

## 10. 引擎接入记录

现已登记 `ChapterRegistry[2]`，`chapter_two_runtime.json`提供98个主线＋19个支线类型化步骤。主程序复用章节分派，章1逻辑与合法v1/v2存档保留；章2使用版本3、严格旧章基线与统一chronology重放，未复制整份main。

两场目标制战斗、九算/第十算、R01/K01的独立解析器均已接入，UI只能发操作。世界行动收据带地图与实际位置检查，路径按序验证；影阵检验相位、姿态和脚印位置，字板检验实际规范化笔画采样。全部选择方法反馈按分支播放，舞台行与人物台词有类型区分。原SC完整快照及SHA保留，亲属修订在播放前应用。

自动流程已覆盖无支线与两种全支线方法、逐节点v3往返、旧版本备份、部分拼图暂停恢复、截止关闭和失败不重复奖励。发现并修复了支线真实移动后暂缓坐标未写进chronology的问题；不能仅凭默认出生点测试声称存读档完整。最终断言数量、精确提交与实际GUI记录见开发计划。

文中前述“本轮未运行”是内容契约交付阶段的历史边界，已由这一接入记录补充。2.50小时节奏、成品资源、音频和导出仍未验收。九算样例仍是实施教学模型；源中未定义的高阶数学题没有被冒称完全求解。
