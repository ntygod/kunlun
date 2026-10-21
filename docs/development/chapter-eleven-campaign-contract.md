# 第11章角色迁移与存档合同

第10章尚无本环境自然GUI终档。第11章集成用第9章原自然档经实际无界面命令运行第10章得到的终档，明确称为自动命令检查点，不冒充自然实机游玩。原第9章源档不写入。另以真实0—10最低路线接入第11章，避免修改经验、装备或生命伪造最低入口。

## 角色与资源

`Progression.actor_panel`继续返回裸装与装备面板，旧章不改。晓霜、花生的初次核心迁移才采用`PartyProgression.newcore_panel`，把明确内功的有效最大值/防御写入永久派生面板，并登记`panel_internal_skill`。战斗按相同标志不再重复乘算；该标志来自事务重放，不信任存档自由声明。

晓霜沿用`char_hua_xiaoshuang`同一字典，保留原年龄、`story_injury`和所有旧物。原档没有HP/MP/装备时，首次数字面板初始化当前等级满值，登记`initial_numeric_panel`；初始医者装备采用07第2章标准25HP/10MP/6ATK/5DEF/1SPD。这是明确初始化适配，不声称旧档已经记有这些装备。若旧对象已有数值生命/真气/装备，则保留并按新上限截断，绝不补满。N01最大MP加20%，受施疗15%属于战斗机制而非再改永久攻击。

石洞显式选择N02，仅改变有效最大HP(+20%)/DEF(+15%)及主修心法，不回复HP/MP。第11章标准补给为独立必经事务，梁230/25/50/32/5、霜190/35/38/28/4；换装不治疗。柳缺本章装备行，旧装备照实保留。花生沿`char_huasheng`语义身份，在黄河推石证明后首次成为核心，标准装备320/20/48/45/2，N01有效HP+25%/DEF+20%；P02由07明确推石节点授予，热粥不自动授P04。两人的非致命标记不占被动槽。

共享经验只遍历明确四个核心ID；未迁移的晓霜、未招募花生、死亡角色和所有剧情/动物角色均不发经验。已亡阿雪完整旧面板不变。快雪是`animal_kuaixue`非战斗白驴，不是物品、核心角色或隐含属性奖励。

## B07前四槽选配

营救前通过普通选择与独立`evt_ch11_loadout_committed`事务明确编排晓霜的四个主动槽，默认望诊/捻针/杏林/龙须；已完成R04并习得迷香者，可用迷香替换其中任一项。未学迷香不显示替换选项，普通攻击与护卫不占主动槽。选择写入`equipped_active_skills`并逐输入重放，战斗只收到这四项且严格核对顺序；不会多出第五槽，也不会因为装配回复资源。选择前可使用现有“暂且想想”返回菜单，未确认不推进。

## 战斗与有界归档

B07只编组梁、霜，双人生还是救师目标；任一0HP为失败。Engine负责装备HXS_P01时胜后一次20%HP恢复，活动结束不恢复MP，事务不二次治疗。跨阶段不回满，重试返回真实战斗入口，部分指令/完整命令史均严格重放。

新11摘要独立检查五位历史人物边界生命（梁、柳、霜、花生、阿雪），老4—10摘要白名单不扩大。角色、物品、奖励、世界对象由事务重建并比较。R04保留第一次合法访问窗口、最后完成窗口以及按顺序完成的两个机关子集，支持选过方法/完成分诊后暂停并错过截止；不补经验、药杵或HXS_A04，也不丢真实选择记忆。

## 可复现来源与测试

为避免依赖某台机器隐含的`/tmp`文件，`test_chapter_eleven_campaign.gd`与`test_chapter_eleven_optional_boundaries.gd`必须显式设置`CH11_SOURCE`。先运行已提交的第10章检查点生成器与独立恢复器：

```sh
# 每次执行都设置独立的 XDG_CACHE_HOME / XDG_DATA_HOME / XDG_CONFIG_HOME。
CH10_FIXTURE_DIR=/absolute/evidence/command10 godot --headless --path game --script res://tests/chapter_ten_state_process_driver.gd
CH10_FIXTURE_DIR=/absolute/evidence/command10 CH10_STATE_MODE=read godot --headless --path game --script res://tests/chapter_ten_state_process_driver.gd
CH11_SOURCE=/absolute/evidence/command10/command_terminal.json godot --headless --path game --script res://tests/test_chapter_eleven_campaign.gd
CH11_SOURCE=/absolute/evidence/command10/command_terminal.json godot --headless --path game --script res://tests/test_chapter_eleven_optional_boundaries.gd
CH11_SOURCE=/absolute/evidence/command10/command_terminal.json godot --headless --path game --script res://tests/test_chapter_eleven_loadout.gd
godot --headless --path game --script res://tests/test_chapter_eleven_minimum.gd
godot --headless --path game --script res://tests/test_chapter_eleven_progression.gd
```

生成器同时写`manifest.json`，逐个载荷核对SHA256和字节数再使用。当前第10章自动终档SHA256为`36ee5c17f97abc183b135aba85d101f28a7d4beac500f00c200fbd5396a588cb`；后续合法行为或序列格式改变应重新生成、核实并记录，不能改写旧清单假装一致。

本合同不签署GUI、成品像素美术、导出或整部游戏验收。最低路线的实际伤损受第10章战法影响，推荐路线和守护路线必须区分；测试通过只针对实际运行入口。
