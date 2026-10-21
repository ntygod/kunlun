# 第十一章空间流程

来源：06/MQ-11、R04；03/SC-11；第十一章预检与来源取舍。六张480×320手工布局扇区是开发像素表现，未声称完整MG18面积或成品美术。R04医疗诊断与执行归独立谜题模型；地图提供实际接近位置，不另造采药任务。

| 控制器 | 场景 / 地图 | 可验证过程 |
|---|---|---|
| world_ch11_town_truce | town_truce / town | 侧身制止两侧兵刃，百姓沿实际路径到安全屋檐；无额外XP |
| world_ch11_reunion_observe | herbal_reunion / clinic | 院外先观察晓霜独立问诊，再等旧白犬循路认主 |
| world_ch11_sunrise_ascent | sunrise_promise / sunrise_peak | 背起晓霜、两处背风石休息、登峰放下；不修改HP/MP |
| world_ch11_cave_escape | cave_escape / rear_path | 抱晓霜绕开巡追区，借树掩护到洞口 |
| world_ch11_plum_practice | plum_apprenticeship / clinic | 晓霜主控，实际走四个步位并依次练势 |
| world_ch11_river_boulder | yellow_river_boulder / river_ferry | 梁萧托一侧、花生稳另一侧，共推三次且双方脚位随石移动；再引百姓到草亭，结束前未招募花生 |

场景/地图分别省略ch11_与map_ch11_。世界动作仅move(dx,dy)、interact、必要时wait，以及不改变状态的inspect；没有“完成”输入、奖励输入或角色切换输入。旧身份沿用 follower_baichier、follower_jinlinger、char_hua_xiaoshuang。快雪为非战斗白驴animal_kuaixue；只由章节赠礼事务生成。

模型沿用begin/apply_input/snapshot/restore/get_view/get_receipts/receipt/replay_receipt契约，可信上下文须chapter11、revision、token、scene/phase、map和controller一致。模型保存演员路径、制止/认主/休息/步法/推石次数、实际角色与坐标；JSON恢复须全部输入重放一致，失败不得改变现场。next_demo_action是合法输入测试驱动，非实机验收。

展示层project只在同地图同场景使用历史空间状态，且不得覆盖调用方已经验证的当前位置、主控和携带状态；实时sync才移动玩家。防止旧重逢收据隐藏后续了情、赠驴场景。阿雪没有地图实体。角色数值、伤势、技能、花生入队与奖励归章节runtime，空间模型绝不补满资源或发放物品。

## 实际验证与待验

Godot4.6.3：`test_chapter_eleven_world.gd`本轮618项检查零失败，包含六条合法路线、局部存档JSON重放、坏输入原子拒绝、角色绑定、NPC真实路径及重复完成拒绝。日志 `/tmp/ch11-world-test.log` 是本环境临时证据。`test_chapter_eleven_world_projection.gd`实测2466项零失败：真实World.configure/sync与渲染帧、六地图碰撞一致、历史投影不改已验证脚位或主控；日志 `/tmp/ch11-world-projection.log`。这不属于截图像素验收。

实机仍需真实游玩并保存截图：院外问诊先于白犬认主；背负/放下身份与动画无重复角色；山路两休息点可达且不治疗；秘洞避追不穿石；晓霜练步时主控正确；两名推石者随巨石移动、百姓走到草亭后才入队；快雪赠礼前不出现、骑乘不重复。640×360与1280×720、F5/F9新进程及当前伤势继承另验。无界面通过不等于上述图形、节奏或成品美术通过。
