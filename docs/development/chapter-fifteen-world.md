# 第15章空间动作与投影

8张语义地图、11段可重放空间序列：通州止斗、合葬补靖、受限公审、百丈救仇、晓霜脱险、墓前问诊、泥丸曲直、饶过贺陀罗/哈里斯、战后照护、东线远行与R06草庐修缮。R06图谱/药储与灯具设计属独立puzzle，本模块只清井搬水、修门、扫地、实际悬灯，不重复授证或奖励。

world_actions/chapter_fifteen_world_actions.gd沿用begin/apply_input/snapshot/restore/receipt/replay_receipt/get_view/next_demo_action接口。context必须chapter15及token/objective/map/scene/phase/controller一致；冻结地图和上下文，快照逐条重放后全字段比较。碰撞与实际World脚底范围一致。只有玩家单步命令推进，无自动计时；菜单/失焦不推进，UI持久控件防止跨阶段鼠标按压串入。

公审被锁时只能原地环顾四次操作，模型拒绝移动、UI禁用方向按钮。东线末段晓霜行走时幼帝与花生实际逐格跟随，出口须等待同行者到位。战后照护按care_order先五宝或先千绝，均完成两边照护，绝不数值补血。剧情角色死亡/奖励由campaign事务决定，world只保留局部表现，白痴儿为犬、猴生还、父子为贺陀罗与哈里斯。

投影只在同map且同phase采用历史布景；历史receipt不能覆盖当前读档导航或主控。live spatial只在有显式visible_actor_ids时替换在场表，稀疏战斗视图不清空演员。普通场景即便没有历史receipt，dead/departed仍优先隐藏，防死者跨节点重现。地图与人物位置用手写开发图板表现，不是成品手工像素或完整关卡面积。

本模块验证：125项模型(11路径/非法原子/部分重放/收据/照护分支)，84项实际World投影(8图/碰撞/普通cast/主控/死者与离队过滤)，独立PID57234写22项→PID57244读23项，共254项通过，无ERROR/WARNING/泄漏。首轮projection错误fixture字段导致4断言失败，原日志保留；不是产品GUI缺陷复现。证据见chapter-fifteen-evidence/world-initial.json。主界面全章集成及自然桌面GUI仍由集成与原云端验收完成。
