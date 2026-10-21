# 第13章四机关与交互合同

来源：03第13章孤舟、鲸息、荒岛与归航场次；06 MQ13及PZ05。分配、计数与格数是可玩化的有限图示，不冒充原著逐项数值、真实医理或航海仪器。鲸息三步长度1/2/3循环是离散游戏节律，不是现实呼吸训练。程序绘制图板为开发示意，不是成品像素场景。

|模型ID|场次|可操作流程|
|---|---|---|
|pz_ch13_water_watch|ch13_water_council|按既有分水选择a/b分配仅两筒水；三夜按公开险情安排前/后/中舱守望并确认。实际水量守恒，无计时自动推进|
|pz_ch13_whale_breath|ch13_thirteen_breaths|十三段各吸/停/吐三步，依据鲸歌图选择拍数；错拍保留既有段落，不扣人物血气或跳段|
|pz_ch13_decoy_ship|ch13_hidden_ship|4工作日；3朽木明伪、7铁力木暗真，梁设计/柳造声/霜封舱/花生转轮；每次潮声遮掩，水轮2:1、五舱依次封闭与伪船暗销，完成后检验登船|
|pz_ch13_star_navigation|ch13_star_navigation|晨夕等长影3/3、指北0、牵星4指，昼夜互校后选择北向归航；必须实际调整初始错误指北与航向|

world负责到场、取叉、撑船与取材等空间动作，此resolver不直接改变全局人物资源、物品或授予技能。分水context.water_method由上游选择转为a（幼帝/哈里斯）或b（花生/晓霜）；b的花生转让幼帝由后续剧情表达。context须chapter13/current_token/对应scene/actors，分水期间只要求柳/霜/生存活，不把梁萧落海误判永久死亡。

保持前章session接口：begin/apply_input/get_view/snapshot/restore/receipt/replay_receipt/next_demo_action。严格schema拒绝额外字段、布尔冒充整数、伪造完成、过期context或直接内部reset命令；partial由真实输入重放而非信任state。输入上限1024，重试保留assist/unknown来源，不洗白手工标记。三层提示后才允许显式协助或演示，协助按每个真实合法命令推进。

UI使用持久按钮/数值输入/选项和共享滚动区，同一题重绘保留滚动；新题重建置顶。640侧栏可滚动，鼠标点击与Return同走input_submitted。示意图显示水量/守望、浪形/13段、四日木料轮轴五舱及晷星刻线；数值调整不默认自动完成。演示在Esc/F5/F9、隐藏/菜单、暂停、应用失焦及窗口focus_exited时停止，不自动恢复。桌面窗口焦点在发送动作与演示tick再次检查；headless工具只能验证控件/通知边界，不冒称OS焦点GUI通过。

验证：test_chapter_thirteen_puzzles.gd 88项通过（每一步partial JSON重放、有限资源/工序、非法操作原子性、assist重试标记、实际640鼠标合成事件/Return分发/滚动和停止边界）；独立进程writer32项PID43633、reader9项PID43643通过，读取后原部分态文件哈希不变。日志无SCRIPT ERROR/ERROR/WARNING。新测试初写时缩进混用及Panel常量遮蔽原生类的作者错误已纠正，初始日志保留于/workspace/kunlun-validation/ch13-puzzles；共享首次import曾因并行world文件未生成失败，不计本轮产品通过。最终证据清单见chapter-thirteen-evidence/puzzles-initial.json。

尚未验：原云端完整自然GUI、真实桌面长时间焦点/菜单/尺寸切换、实际人物场景投影及跨章终档；由集成后验收，不把上述129项当成第13全章验收。
