# 第15章B12医理破贺陀罗

## 来源与输入契约

以07 B12和06 MQ15三轮医武闭环为准：晓霜/花生出战，梁萧不在东线，萧千绝仅场外点拨。enc_ch15_medical_disarm → ch15_he_disabled；基础敌人5500HP/310ATK/240DEF/50SPD，逆血阶段4800/345/200/55，60%魔功护体、1回合韧性保护。任何伤害渠道不能杀敌或跳过两阶段封功。

推荐X四槽HXS_A01/A02/A07/A04，HS四槽HS_A01/A06/A02/A04；HS_A06必须战前已经授予。备用X最后A04换A03、HS最后A04换A05，其他配置由实际四槽严格校验。HXS_N02、HS_N02面板由战役应用一次，HS_N02额外DEF20%转ATK只在战斗伤害中计算，不再次烘焙。试用CO04在第3轮编排前加入技能并补协力至2，胜利固化交给战役事务。

## 战斗行为

每阶段望诊+实际金刚护持、龙须+曲直、合招构成两组可交互流程。HS_N02下一招加速可能让曲直先出手，仍按本轮已实际执行的望诊标记、龙须与曲直组合记医理证据，不改变真实行动顺序。望诊不凭空发协力；实际护持和有效破招按全队每轮最多1格。CO04同时预留双方行动/2格协力，替换或取消恰好退款；保护期封功是任务进度，不取消敌动作或发破招协力。两阶段都封功且双方存活才非致命获胜。阶段不恢复我方HP/MP/CD。普通伤害压到1HP不会提前完成目标。

HS_A01实际准备为guard，75%/90%分担、35%护体、一次反震；HS_P03预测正常分担仍会击倒受护者时才单次全代受，消耗免死额度且无额外协力/回气；HXS_P03仅无其他护卫时低血同伴受单体重击的单次应急分担。捻针/回春/复苏使用现行技能数据与额度。仅晓霜实际装配HXS_P01时胜利全队恢复20%HP一次，不结算MP；没有该被动则不回血。独立开战满MP是统一规则，重试回原战前HP。

保存保留完整输入和待结算指令，恢复及收据严格重新运行并全字段比较；不接受只改HP、封功、阶段或奖励。世界投影由X主控，地图默认map_ch15_duel。B12 UI为开发候选、不是成品像素或合招动画；真实桌面GUI仍待验。

## 已执行验证

独立构造合法基础面板：combat50项（含实际Control鼠标/Return信号和640边界）、boundaries39项、阶段2未结算指令独立进程writer1/reader2，通过；没有ERROR/WARNING/泄漏。最低真实合法命令入口另combat50项+新进程3项通过。该入口为/workspace/kunlun-validation/ch15-campaign/minimum-b12-entry.json，SHA256 f84a65aec41da1d7b9fa5e41f881933060e755f5d13e9379192ba9a15a2f1bbb。X入口2022/2028HP、26/238MP；HS2810/3823HP、13/147MP；按统一规则开局满MP，标准6轮两段获胜后X2028HP/138MP、HS3253HP/129MP，含已装P01合法一次恢复。不是编辑存档补血，不冒称自然GUI。

最初6轮断言失败，查明kind初始skill后Dictionary.merge未overwrite导致护持没生效，改为显式覆盖后实际分担/协力与6轮闭环通过；初始test.log/test2.log/test3.log保留。最终日志在/tmp/ch15-combat，版本归属为本模块提交，不能与未来改动混称全量。全部装备、所有高阶被动组合、死亡重试真人操作及成品QA未做全覆盖。

|日志|SHA256|
|---|---|
| test-final.log | cfe9d1ed27a05fe8e48fc3f61b92ec1646f2df3b60e05ace10a70717093db7b0 |
| boundaries-last.log | cfbabbc7920e627a4507325231e17a292de4fb43e801cbb574e941d37e3cf3eb |
| process-final-writer.log | 3b43a588a8a7c20d4363f5949b3142a4ec3de16ac3aabd3b8e3f05d4ad3cfe8b |
| process-final-reader.log | 48a10a7dadb917c975d5a7e1f1aa621eb7a07ed51f51bf3d3adc06b287893805 |
| minimum.log | 68c9b79167dd85d45dd1dc0a1430a45efeab829279e0bb2c9af482c6f49346ad |
| minimum-process-writer.log | 5aca9b459f4205f1fa3721338857e08c6ad32289d2883ca757839c2ce4a233d8 |
| minimum-process-reader.log | f3e95c277fd472fc08904b73bc424297092580bd0125c2e1fb324931d2aae936 |
