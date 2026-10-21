# 第13章南海双线空间流程

新增8个紧凑480×320语义地图：崖山、孤舟、鲸背、残船、荒岛、断后礁石、归航楼船、惠州朝云墓。320×180像素视口由现有World承载，所有图形为明确标注的开发像素原语，不是成品手工像素资产；未声称GUI或全尺寸地图完成。

8个真实空间session：梁萧救童，柳莺莺扣缆守后舱，花生搬梁撑船，晓霜护童/虚构包扎换水，梁萧系缆拔幼鲸残叉，梁萧夺艇抱童并等同伴登艇，花生分运明滩3份朽木/暗谷7份铁力木，柳莺莺留书与晓霜告别后牵马自主离开。淡水配给/守夜、鲸息节奏、四日造船/五舱机括、牵星导航属于独立谜题，不在本模型重复结算。

动作仅move/interact/inspect/wait，严格键集合与整步方向；脚底16单位网格与World碰撞一致。实际走到锚点才可交互；搬运先取后放；救童先抱后登艇；同伴、犬猴胭脂按路径实际移向小艇，到位前需等候。状态包含主控/脚底、携带物、演员位置/姿态/可见列表、路径、局部机关与阶段收据。死亡、加入/离队、技能、奖励和全局物资仍由campaign事务处理，空间receipt不自行写原存档。

梁萧失散只从孤舟可见列表排除，不标为死亡。快雪在沉船流程不可重显；犬猴及胭脂保留且实际登艇。共享历史投影不会改读档脚底或主控，实时projection才拥有移动；dead_actor_ids/departed_actor_ids始终高于旧visible列表。视图只渲染受验证位置与命令结果，不伪造已完成机关。

正式接口与第12相同：begin/apply_input/snapshot/restore/receipt/replay_receipt/get_view/next_demo_action，map_hash绑定地图与冻结上下文，所有恢复重放原始输入而非接受伪造位置。main使用已有受控世界UI输入分发；World注册ChapterThirteenWorldPresentation.NAMES/project/sync/draw。地图action键包括8world、4puzzle和enc_ch13_island_departure；剧情补充action由内容集成负责人按语义添加，不按旧MAP数字猜绑定。

验证：test_chapter_thirteen_world.gd 80项通过；test_chapter_thirteen_world_projection.gd 48项通过。前者覆盖每条空间路线真实命令、非法输入原子、JSON部分态/收据重放、分线/宠物/材料边界；后者运行实际World与Player，检查注册、模型/物理碰撞、实时主控、历史投影和死亡/离队过滤。无界面运行，不代表真实鼠标/像素验收。最初文件未写完导入和模型229行缩进错误已修，旧日志保留在独立/tmp/ch13-world，不冒称首次检查通过。待主场景自然输入/独立进程恢复及原云端GUI验收。
