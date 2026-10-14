# 第03章《灵台惊变》内容契约与来源裁决

当前状态补记（2026-10-14）：本章现已实装为开发可玩流程，实际注册/存档与验收见第11节及开发计划；以下最初“未注册”措辞作为内容契约历史记录保留。
日期：2026-10-13。只新增 `game/data/chapter_three.json` 与本文。第02章仍由其他工作流集成，本轮不修改其文件，也未修改代码、地图、字体、测试、权威V3文件或执行Git操作。

## 1. 交付边界

本章是**未注册、不可玩的内容契约**，不是游戏章节实装。schema_version=2只是契约数据字段，不构成新存档格式或现有加载器兼容保证。严禁按文件名自动注册或从原档全文直接播放。真正接入前须完成 `required_capabilities` 所列控制器、资源、存档、字体和GUI验收。

已阅读根AGENTS/README、game README、开发计划、第01/02章契约与数据；核对V3 01人物/队伍、02本章四场与后章信物流转、05动作/配音、06 MQ-03及R01回响、07现行80级与B01、08地图/角色/动作及现行combat_rules与两个复核报告。原著只用用户提供的GBK文件，完整阅读天机卷第11–14章（2326–2558行），另读纯阳开头2559–2568行以核对离谷边界；无网络小说替代。

- 15个主线节点，覆盖MQ-03六步；4个语义地图、6条路线提案
- 四场完整原档，34个原引文单元（32人物台词、2独立舞台行）全部各分配一次
- 51个运行对白/舞台登记单元，其中17个桥接补写；另有6条显式条件覆盖
- 12个稳定选择ID，分为6个选择组；拒位节点有两个独立选择，不能把4项误当四选一
- 50个场次完成凭据、3个有限线性方程教学模型、1个B01首领契约、1个石影脱困战术交互
- 无第03章新R/K/L支线，不重发R01/K01奖励；1.50小时仅为策划目标，无实测时长

归档完整不等于演出、关卡、美术和配音完成；下文数值与动作也只约束后续实现。

## 2. 完整来源保真

行号为1基、含首尾。sha256对保持原换行的解码切片再编码UTF-8计算；每份档案另含原文件字节SHA256。原著以GBK解码；不能拿原GBK切片字节哈希误比UTF-8归档哈希。

| 原场 | 02源行号 | 完整切片SHA256 |
|---|---|---|
| SC-03-01 | 636–678 | `85b9c17ee95c07de23035a5e48c22540c086ce7bf5ecbbc4951d17fe65e0dfdf` |
| SC-03-02 | 679–717 | `1aa9bb2444e63ef262fcb93c98b8012bb21de0ce0e8afe43f756c77a6dd59006` |
| SC-03-03 | 718–761 | `b61b404cb9b821deebafd063a8103ab277a0730392d656876cee69684d6b5858` |
| SC-03-04 | 762–809 | `82425c95a83ae2ff6823e287ef25ae2435932a897110697e670abef9d46d5781` |

`related_source_archive` 还完整保存MQ-03、B01、R01回响、经验账、物件链、冲突动作/配音/地图行、原著四章及出口补段。源档包含知情范围、潜台词、走位、停拍、声景、两支完整选择反馈，不因运行侧修订而删去。`dialogue_registry.provenance=source_verbatim`保留逐字引文；新增对白和选择反馈均标implementation_adaptation。运行必须先应用effective_dialogue_overrides，不能把原铁砚碎裂/肩刺/石洞/梁萧青衫播出后再用文档解释。

章03开始仍不知长辈骗题、秋山死因或晓霜病因详情。药王茶叙后才揭寒毒，大典665行后才知十算骗局，公开论算结束后众人才知其研究成果，明归口供后才写秋山真相。来源导演知情账不能泄漏进主角任务簿。第十算从不写成已解，旁人“无人能解”是故事内认知，不当作数学不可解定理。

## 3. 场次覆盖与真实门槛

| 节点 | MQ步 | 内容 | 必须完成凭据 |
|---|---:|---|---|
| `ch03_medicine_visit` | 1 | 药王亭 · 辞行误会 | `medicine_route`, `treatment_misunderstanding_seen`, `tea_seated` |
| `ch03_tea_truth` | 1 | 分茶问病 · 九阴之忧 | `tea_shared`, `cold_meridian_truth_heard`, `medicine_supply_packed`, `ceremony_arrival` |
| `ch03_ceremony_rupture` | 2 | 开天大典 · 七鹤旧怨 | `seven_cranes_observed`, `murong_defeat_seen`, `qingyuan_trial`, `liang_control_restored` |
| `ch03_deception_exposed` | 2 | 元外之元 · 五年之欺 | `deception_reveal`, `return_to_stairs`, `choice_ceremony` |
| `ch03_reckoning_setup` | 2 | 论算备案 · 旧稿回响 | `math_desk_prepared`, `abacus_received`, `r01_echo_disposition` |
| `ch03_public_reckoning` | 2 | 牛虱北斗 · 以字代元 | `reckoning_six`, `reckoning_seven`, `reckoning_twelve`, `choice_reckoning`, `b01_entry_xp` |
| `ch03_refuse_sword_teaching` | 3 | 不学旧剑 · 三才迎敌 | `taiyi_refused`, `armillary_inspected`, `b01_entry_ready` |
| `ch03_lingtai_battle` | 3 | 灵台论剑 · 浑天借势 | `b01_result` |
| `ch03_throne_refusal` | 4 | 胜而不居 · 太阿辞位 | `throne_walk`, `choice_throne_reason`, `choice_post_battle`, `taie_not_acquired` |
| `ch03_hostage_confession` | 5 | 黄鹤败露 · 秋山旧案 | `hostage_taken`, `qiushan_truth`, `padding_reserved` |
| `ch03_hostage_exchange` | 5 | 怀砚换质 · 誓言反覆 | `padding_used`, `exchange_betrayal`, `array_captive_arrival` |
| `ch03_assassin_shadows` | 5 | 刺客石影 · 以虚脱困 | `shadow_escape` |
| `ch03_forest_shelter` | 6 | 血迹追踪 · 古树藏霜 | `carry_route`, `shelter_inspected`, `keepsake_secured`, `xiaoshuang_sheltered`, `choice_farewell` |
| `ch03_blood_cloak_decoy` | 6 | 披衣引敌 · 此去经年 | `medicine_left`, `followers_safe`, `cloak_decoy_placed`, `decoy_route`, `ming_diverted` |
| `ch03_valley_departure` | 6 | 独行谷外 · 失散牵挂 | `export_continuity`, `mq03_complete`, `ch04_exit_requested` |

每个节点要求前场完整事务，最终要求全部14个前场。event_sequence是操作顺序契约，**不是**“按数组播放到底即完成”的解释器。展示对白和玩家行动应交错：论算未过不播明三秋认输；B01未得真实结果不播辞位；石影未脱困不播已逃到林间。

### 药王茶叙与清渊受挫

药王亭路径、窗边观察、退让医者与分茶都需世界/物件输入。分茶补写为3份茶入3盏各1份，错误可取回，不宣称历史真实定量，不制作针灸或用药教学。吴常青的毒舌与尽心续命并存；梁萧知道病情后仍未获得医术或万能治病物品。

02要求短时操作花清渊，01/06却规定章03主控及战斗梁萧单人。契约用独立、无成长的清渊受挫视角：读袖掌转势、守退、认输三步；错误重看局势，不生成可逆死亡或“清渊赢了”的分支。无需伪造07未提供的可成长面板，不给清渊XP，结束恢复梁萧。B01只有梁萧参战。

### 公开论算不能用三个成功按钮

V3/原著只给牛虱、北斗、十二生肖文学题面，没有可完整求解的所有系数。本契约明确补写三组6/7/12元有限教学线性系统：前n−1行x_i+x_(i+1)=2i+1，末行x_n=n，唯一解1…n。JSON存完整矩阵与常量。

玩家须将符号分配到不同列、做合法行消元、填值并逐式代回；校验器使用精确有理数且检查变换前后等价。仅提交答案向量或solved=true不是凭据。第三层辅助须用户明确选择，逐步显示合法操作并经同一校验器，记录assisted。小题旨在演示“以字代元”，不是冒称完整重现高阶原题，也不证明任意元均可解。

原著2435行十二生肖推至未能继续，V3却强调十二元超群。本契约保留V3叙事改编及原文差异，绝不因此发放“第十算成功”。R01已完成且确有算册时翻旧案；只装后半册仍有有效中段；由晓霜代存的第一页不瞬移。没做支线则在空白纸推演，同样通主线。回响不发400XP，也不强制补做已关闭支线。

## 4. B01：两个数值阶段、三段教学

07 B01胜利原文：

> 打空阶段二气血，或利用浑天仪借力成功打断其绝技3次，明三秋内伤爆发吐血溃退；随后梁萧当众谢绝接任宫主之位，剧情胜利！

07给阶段一HP680/MP100/ATK58/DEF32/SPD18，阶段二850/120/66/36/21；06给观势、铜球、三识三个教学环节。本契约分开二者，**不凭空造第三条血条**。阶段一50%阈值=340，第二阶段是否满850、过量伤害是否截到阈值并丢弃仍是明列待战斗worker复核的参数。配置总HP1530不是实际必需输出1530。

主角HP/MP/CD/每战次数/机关计数跨阶段继承；不得满血满蓝刷新。每阶段可信快照可重试，快照本身不能发XP。胜利令明三秋非致命失战，不标死亡。

意图须公开：1回合蓄力的1.80倍璇玑引星剑、速度+10的1.35倍天玑绝命刺、最大HP20%护盾和20%反震。盾应按当阶段HP向下取整为136/170，不取说明里的“约150”当固定值。

浑天仪打断必须同时有：当前公开蓄力意图ID、该意图的观势记录、可达把手、真实指针/铜环对位输入、目标不处韧性保护。观势在蓄势宣布轮，下一轮释放前操作机关；暂拟机关速度修正+30、0MP、CD0且占正常行动，参数须后续战斗平衡复验。错误/过期/受保护/同意图重放不增加计数；三个不同合法窗口才可走三次打断胜利路线，不能任意点三次。有效机关造成其当阶段最大HP8%反噬，统一破招易伤/韧性规则照现行combat_rules执行。

LX_A02仍是准备阶段虚实诱导，不能偷换为打断蓄力；保护期只有35%自守，不让攻击无条件落空。现场“三才料敌”是既有LX_A02或本场机关的语义包装，提前开放后再允许选用、不另送行动/伤害/永久技能。允许07直接HP胜利或3次机关胜利，不另设隐藏第三阶段必须通关。三识台词若胜利太快尚未播放，胜后补演知识提示而非强迫追加战斗。

嘲讽分支的源【心浮气躁】留在档案；契约只增清楚的开场提示，不擅造减防、增伤或自动成功。其数值影响仍列待定；解释算理分支有青年支持回响，普通主线支持不被选择锁死。

## 5. 换质、石影和追兵

清心砚/铜算盘选择只能从实际拥有物品中选。铜算盘在论算案边有唯一实体、领取凭据和借用身份，这是为06分支补的桥接，不冒称源有领取剧情。选择仅预留物件；取消放回，进入离镜自掌演出后才同事务变更物品状态。该段没有自伤力度/时机小游戏，也没有玩家可计算的HP攻击。

- 砚路线：同一个 `item_ch02_qingxin_inkstone` 从intact变broken_fragment，不删除后重发新砚。两种诀别回应都会保全唯一残角；B只是抚砚特写。无材料值、无永久5%抗性。
- 算盘路线：实际消耗算盘至destroyed，清心砚仍intact；额外要求两座不同石像阴影完整隐蔽喘息。不能让此路也凭空获碎砚。
- 未用算盘保持借用记录，不能卖/丢/加属性；不假写已还。后章可再安排真实交还，不让玩家在逃离中折返宫内。
- 源“四成卸力”只限本场。当前逃离演出没有HP伤害模型，所以不配置战斗减伤，并未把源值抹成零或永久化；未来若做HP结算必须重新核对。

石影控制器是确定性网格/相位/视线：观察豫让定位、纠正明归错步、朱亥假势衔专诸影、背负晓霜、舞阳接渐离/荆轲。三相位approach→overlap→recede；正确位置和overlap窗口才诱开明归。追兵按最后可见位置行动，掩体阻断视线。被截住回到该段尝试快照，没通关不消费奖励；同一掩体不能重复凑两次休息。02刺穿肩胛与原著石像惊敌不同，运行暂按06/原著非杀伤诱敌，原肩刺仍归档待集成复核。

外衣诱敌先调查血迹、安置晓霜、取她外衣、覆在枯枝、走到另一岔路。世界控制器必须证实明归看见诱饵并实际走过分岔，藏身洞始终不在其视线。把外衣放在目标上不自动完成追兵引离；重试恢复之前物件/位置，不能复制衣物。

## 6. 队伍、信物与后章连续性

梁萧16/晓霜15继承章02；“求学第六年”只解释为已过五年，不再加一年。17岁属于04次年暮春显式时间节点。母亲暂离未死、父亲永久死亡，父墓仍缺靖，不能再发02识字成长。花慕容是清渊妹妹、晓霜姑姑。明三秋是明归亲侄兼养子，明三叠才是亲子；07“前宫主之子”不进入运行身份。

晓霜从剧情同行到“失散牵挂”，不是死亡，也不是已加入又永久除名的战斗成员。第11章才正式入队。只有梁萧领本章XP；所有已获得物品、记事和旧分支原样带入，不补发未做支线。

包布长剑一直保留，太阿剑从未进入梁萧装备；原791行扔剑演出改成挂回腰间以免石阵用剑或出口凭空找回。清心砚材质留空，其晓霜赠物身份明确是V3改编：原著2549只是临场算题丹砚。04偷钱袋/托付信物应检查intact/broken_fragment，分别称清心砚/残砚，实际选托付时才把同一实例给莺莺。

晓霜故事药瓶在药王亭检查、必要时由主线补齐一次剧情份额，量为1、不可转梁萧通用战斗药，离别后仍留在晓霜身边。A显式嘱金猴守护，B默默安置同一只猴。白犬也领到安全藏处，避免单人诱敌中动物凭空消失或进入敌人目标列表；这项位置安排明确是实现桥接，尚待集成审核，不是原著逐字情节。两只都不得按同名改成灵貂或人形角色。

运行暂按06古树洞、晓霜浅碧外衣，02石洞/梁萧青衫及原著后来白衣全部留差异记录。原著随后写梁萧再被明归擒住和千里船出谷，V3这里直接止于诱敌、04从次年姑苏开场。本章只记录诱敌离去，**不宣称明归已死或梁萧已经完成原著后续逃脱**；该叙事间隙是V3压缩，不能私自增删整段过场冒称既定。

## 7. 80级成长和奖励账

累计公式TotalXP(L)=100(L−1)+15(L−1)(L−2)/2，成长x=39(L−1)/79，上限80，沿用现行规则，不复用40级旧账。

| 节点 | 本章主线XP | 必经遭遇XP | 无支线累计/等级 | 带02两支线累计/等级 |
|---|---:|---:|---|---|
| 继承02 | 0 | 0 | 1440 / Lv10 | 2090 / Lv12 |
| 论算完成，B01前 | 235 | 0 | 1675 / Lv11 | 2325 / Lv13 |
| B01胜利 | 300 | 0 | 1975 / Lv12 | 2625 / Lv14 |
| 石影突围 | 0 | 150 | 2125 / Lv12 | 2775 / Lv15 |
| 章末 | 345 | 0 | 2470 / Lv14 | 3120 / Lv16 |
| 本章合计 | 880 | 150 | 增1030 | 同增1030 |

235是权威首领入场预算；300/150/345是实现侧拆分。B01奖励已经计入主线880，不另叠150或额外首领奖励。论算没有PZ-02，也没有机关XP；石影150从本章遭遇池结算一次。R01单做继承400、K01单做250，仍应分别计算，不只有全无/全有两个合法存档。

章末铜钱300一次；原有财富不清零。装备保留02标准套HP30/MP5/ATK8/DEF5/SPD1，不凭空给03新阶，也不叠01装备加成。基础属性随等级自然增长。LX_A01 rank2、LX_A02 rank1、LX_P01继承；本章不永久授予或升阶后章武学，不把不慕王侯变成未定义面板加成。K固定采用推荐11–13中点12，K=100+4×39×11/79，不随做支线升级追涨。

全部奖励按唯一事务发放，舞台略过、失败重试、阶段快照重进、回忆录都不重发。重大余波屏蔽升级/物品弹窗，静默不等于不记账。

## 8. 映射、事务及接入要求

地图：02 MAP-05-D→运行lingtai→08 MAP-08/08A；02 MAP-05-E为刺客境+外林复合36×20，不能把每个拆图都伪称有36×20权威面积。08 MAP-07/07A是语义候选；药王亭和独立外林无权威尺寸，留null。原分镜X/Y属于320×180构图，不当世界地图坐标。当前只有锚点拓扑，实际坐标/碰撞/追兵寻路必须由关卡worker制作后才注册。

动作：script02 ACT-04是披衣，voice05 ACT-04是藏砚且刺胸，art08 ACT-04是上章灯下劝慰，完全分开语义ID。VO-03-01误绑论算且有玉佩，运行应该在辞位，不能额外生成玉佩。均asset_path=null，不假称音频/像素资产存在。世界320×180最近邻整数缩放，中文UI独立高清，48px字幕安全带。

收据由可信控制器生成，至少含chapter/scene/objective/attempt、输入日志、引擎事件日志、前后状态哈希、唯一消费事务。保存章节状态、道具形态/归属、角色状态、知识和奖励账须原子。禁止UI给won/solved=true、越级scene_index、选不存在的道具、把导演知识写给角色。取消未完成操作回安全点/战斗快照，不留下已消耗但未过关的唯一砚台。加载回放必须用冻结配置；未知版本/伪造收据拒绝，不覆盖原档。

正文演出可略过，选择/论算/战斗/走路/诱敌不可被略过自动做完。所有来源覆盖必须切片播放，完整来源档绝不直接送UI。

## 9. 冲突及裁决登记

“父线程方向同意”仅授权实现侧最小契约，不等于改了权威原稿；pending项不做成玩家审批按钮。已核对的小证据按本文方向保留，不因文案异形让用户逐一审批。

| 决策ID | 来源 | 最小方向 | 状态 |
|---|---|---|---|
| `inkstone_material` | script02:792,806,1506；quest06:331,336；novel:2548-2549 | Material left null; retain V3 keepsake adaptation, preserve original records; 40% remains scene-specific source claim with no HP damage adapter yet. | parent_direction_confirmed |
| `inkstone_continuity` | script02:803-806,853,988-989,1506；quest06:336 | Inkstone padding transforms unique instance to fragment; both farewell branches secure it. Abacus padding destroys only owned abacus, preserves intact inkstone. Future dialogues branch by actual form. | parent_direction_confirmed |
| `abacus_acquisition` | quest06:336 | Borrow physical desk abacus before debate with unique acquisition receipt; bridge authored here, no source acquisition scene exists. | parent_direction_confirmed |
| `ming_identity` | script02:643；quest06:325；combat07:595；novel:2394,2518 | Ming Sanqiu is Ming Gui nephew and foster son; Ming Sandie biological son. Not prior palace master son. | parent_direction_confirmed |
| `b01_two_vs_three` | quest06:333；combat07:597-611 | Two numeric phases, three teaching beats, exact07 alternative win condition. Enemy P2 reset/overflow explicitly pending battle integration; do not manufacture third HP pool. | parent_direction_for_contract_balance_pending |
| `action_self_strike` | voice05:ACT-04；script02:792；quest06:331；novel:2527 | 02/06/novel self-palm as offscreen performance; not05 stabbing, not art08 ACT04 comfort. | parent_direction_confirmed |
| `cloak_and_shelter` | script02:780-800；quest06:332,340；novel:2556,2561 | Follow06 Xiaoshuang cloak and tree hollow; original novel no hollow in this passage and white cloak later. This is explicit V3 adaptation, not literal novel reproduction. | implementation_direction_pending_integration_review |
| `shadow_wound` | script02:794；quest06:331；novel:2542-2553 | Real shadow-induced escape, no mandatory shoulder stab or kill; source variant archived. | implementation_direction_pending_integration_review |
| `math_claim` | script02:687-710；novel:2435 | V3 twelve-variable superiority kept as story; novel reaches an unfinished point. Finite teaching boards never prove arbitrary-variable solution, tenth_sum_solved stays false. | implementation_adaptation_disclosed |
| `source_time` | script02:640；quest06:308-309；chapter_two.exit_contract | 第六年 means five years elapsed;16/15 inherited, no extra one-year jump in03. | continuity_rule |
| `trial_roster` | script02:644；character01:147；quest06:324 | Qingyuan short non-growth observation/defense trial, fixed story defeat, no invented level/panel or permanent roster; Liang remains sole B01 actor. | implementation_direction_pending_integration_review |
| `animal_exit` | script02:803-804；chapter_two.exit_contract | A explicitly tells monkey to guard; B silently leaves same monkey with Xiaoshuang. White dog is led into safe shelter before decoy in both branches; tagged bridge because no exact03 source placement. | implementation_continuity_bridge_pending_integration_review |
| `source_act_and_map_ids` | script02:MAP-05-D/E;ACT-04；voice05:ACT-04;VO-03-01；art08:MAP-07/08;ACT-04 | Namespace semantic maps/actions; no numeric-ID auto-binding. | required |
| `no_numeric_choice_bonuses` | script02:714,756,806；combat07:rules | 心浮气躁 only extra tell pending numeric review;不慕王侯 memory only;残砚5% resistance not in current combat model, retained source but not silently added. | numeric_integration_pending |
| `source_inherited_gear` | combat07:Lv10 milestone；chapter_two.item_registry | No03 independent standard equipment tier provided. Keep02 bonus30/5/8/5/1 and current skill ranks;03 levels raise base panels only. | explicit_no_invented_tier |

## 10. 验证记录与未完成项

独立只读Python断言已通过：JSON解析；四场和15份相关切片逐字/SHA一致；15个唯一snake_case场景及前置链；4个地图引用；全部34原引文各落一场且发言者在场；51对白引用；12个选择唯一且六组齐全；50个目标凭据；6条路径锚点有效；三组教学矩阵代回正确且单位上三角保证唯一解；奖励880+150=1030、B01前1675、全支章末3120/Lv16；技能无提前永久授权；未注册状态和空资源路径。

另运行 `python game/tools/validate_data.py` 通过：序章11节点、第01章10节点/47步骤、第02章19节点/117主支线步骤。该脚本未发现或校验章03，不能把旧章通过算作新章验收。未运行Godot、GUI、胜率/回合数、实际路径碰撞、字体子集或导出。后续最低测试需覆盖：砚/算盘×两诀别分支；R01全册/半册/未做及K01独立组合；B01两胜利条件/两阶段重试/保护期/错误机关/伪造收据；六组选择、正播/略过一致；各节点保存重载；晓霜失散不死亡、动物和药物位置；完整/破损砚进入04条件台词；铜算盘实体唯一及剩余借用记录；最低Lv11无支线可胜；分辨率/中文字体/鼠标键盘实际完整路线。

本文件没有章03注册入口，不能宣称完成可玩章节。若接入遇到缺失能力，报告具体接口而不是用“完成机关”“成功突围”按钮代替。

## 11. 引擎接入记录（2026-10-13，验证进行中）

上文“未注册/未运行”是最初内容契约交付阶段的历史状态，来源档案与既有裁决保留。当前显式登记 `ChapterRegistry[3]`，`chapter_three_runtime.json` 将15节点接为76个类型化步骤；第04章仍未登记。共用章节事务、chronology、注册机关面板及主程序路由复用，第三章专属效果由 `chapter_three_runtime.gd` 适配，没有复制另一份main。

- 章2合法终态继续使用版本3，第三章增加有明确判别键的 `chapter_three` 变体；仅接受精确的章2已验证终态为基线。基线链固定为章3→章2 v3→章1 v2→旧序章，禁止任意同版递归或用户指定章节。实际章2人工终档载入、16/15岁/2090XP/250铜与原伤损继承已检验；后续逐节点往返及GUI证据由开发计划记录。这一有限适配不是第20章长链存档的既成设计。
- 公开论算、分茶和清渊受挫采用真实输入解析器，chronology重放每个操作。适配曾发现直接JSON动作中的整数float未被分茶枚举接受，已在解析器入口规范化并补直接JSON动作回归。提示只读、逐步协助留痕，不把按钮成功标记当证明。
- B01沿真实战斗会话，在移动把手、旋环、编排和回合结算后保存可重放快照；阶段重试仅回可信阶段起点，不重置累计机关次数/成长或凭快照领奖。低血入口与数值阶段裁决见[战斗接入记录](chapter-three-combat.md)。
- 清心砚以原ID增加intact/broken_fragment形态；铜算盘经世界领取后才可选择，离镜剧情提交时改变形态。唯一药瓶、晓霜与猴犬藏身处、未还算盘借用身份与衣物诱饵分别落账。R01只根据真实记事/物件播放回响，不再发经验。
- 石影/披衣控制器按网格移动、相位、视线与真实NPC步进生成收据。可信已安置上下文让披衣段从树洞开始，不把已藏好的晓霜重新背回林口；同图转场保持最后合法位置，避免诱敌后被传送回藏身处。任务层只在独立重放验证后接受机关/首领结果。

本阶段尚不能称成品第03章。实际完整键鼠流程、最终候选画面、全部分支/异常存档、性能、音频、1.50小时节奏与导出边界继续以开发计划中的最终记录为准。
