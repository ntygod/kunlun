# 序章运行ID与来源边界

来源基线：仓库 main `3e459accc55739b8440ef5bfd6c7c7979518c48f` 的 V3。原始策划未改写。

| 运行ID | 02逐场来源 | 06任务步骤 | 实施状态 |
|---|---|---|---|
| shenxian_crossing | SC-00-01 / MAP-01-A 神仙度 | 序幕前置 | 原主对白、双局部选择；临时舞台 |
| bashan_inn | SC-00-02 / MAP-01-B 巴山客栈 | Step1 | 原主对白、三处勘查、双选择 |
| sancai_lesson | 无独立SC编号 | Step2 公羊羽授艺 | 任务摘要改编、有限教学；待完整剧本 |
| yinping_path | SC-00-03 / MAP-01-C 阴平 | Step2后 | 原主对白、观刀/香囊选择；接刀演出待制 |
| hezhou_patrol | 无独立SC编号 | Step3 巡防 | 任务摘要改编、巡防先后选择 |
| hezhou_prison | 无独立SC编号 | Step3 石牢 | 任务摘要改编、双回应 |
| diaoyu_wall | SC-00-04 / MAP-02-A 城头 | Step4 | 原主对白、双选择；丧父动作未制 |
| canglong_rescue | 无独立SC编号 | Step5 藏龙寺 | 任务摘要过场；战斗/挡刀演出未制 |
| poshan_calibration | SC-00-04 A分支意向的后续 | Step6 | 三架弩独立校准8成/3格 |
| siege_aftermath | SC-00-05背景前因 | Step6 | 任务摘要过场；白朴/端木同归于尽仅交代 |
| jialing_dock | SC-00-05 / MAP-02-B 江畔 | Step6终幕 | 原主对白、双选择、玉令回收与记事 |

02和06的排序不完全一致：02的SC-00-04 A分支描写当场校准破山弩，而06把藏龙寺救妻置于发机之前。本轮采用06六步骤的顺序，以02长对白承载已有场次；SC-00-04 A分支反馈先承接“扶上绞盘、确认江风”的意向，真正三弩交互置于Step6。此为显式临时整合，不是用户已批准的剧本修订，后续须进行叙事审校。

02的MAP-01-A为神仙度，而08的同号为钓鱼城；运行地图不直接绑定编号资源。JSON的 `source_map` 只能与 `source_document` 联读。补场 `source_map=unresolved`，`map_mapping_status=temporary_layout_pending_design`。本轮临时路线采用32px网格，已有原场名义宽高保留在数据，但只有核心行走带搭建，不声称整张设计地图已完成。

`source_scene=MQ-00 supplement` 是实施标记，绝非新编的官方SC编号；补场对白为06摘要的开发改编，字段 `adaptation_status` 明示 pending。现有原场主对白从02提取，局部选择反馈有压缩。无擅自改写不可逆生死、无恋爱数值、无随机剧情分流。

保留的分支回响均写入可读记事/标记，后续章节的触发消费尚未实现。剧情事务结束只记序章 `MEM_MQ00_WENJING_MERCY`，不发成长XP。
