# 第八章机关局部验证

2026-10-14。对应批准合同 `10cac89deeebb2e9437b5190c88e731fe788b7d8` 的三题、PZ03-A、PZ03-B；本模块不授XP、不改永久人物/物品，不替代整章验收。

## 实现边界

- `numbers_ch08_ranya`：七曜有限周期、渠池守恒搬水、十二尺梯料三个实际输入阶段。已验前题不可回退；渠池接受非最短合法解。
- `dam_ch08_submerged`：施工棋盘岸上三人四邻路径/工位、三船独立宽度与泊位、同拍并行逐边记录、共同沉船、配重剖面、梁开闸、尖木沿主流逐格撞桥。棋盘坐标不冒充世界地图坐标。世界仅可投影合法结果。
- `cannon_ch08_calibration`：轻弹/重弹两套试射记录；有理数整数除法，660÷30=22；仅计划校准，未实际毁弩或前移。
- 所有proof绑定冻结上下文、动作日志、前后hash及重放终态；外来complete/success不授权。日志上限重试保留已验证前缀和辅助标记，拒绝将已有assisted降级。
- 面板棋盘/剖面始终单独可见，完整规则位于正常可滚动正文。大窗图自动放大；小窗正文无横向截断。语义按钮ID固定。单步/连续本题协助使用同一模型合法输入，停止、隐藏、暂停及旧token事件受控。

## 已执行（仅无头）

隔离环境：`XDG_CACHE_HOME=/tmp/kunlun-eight-pz/cache`，`XDG_DATA_HOME=/tmp/kunlun-eight-pz/data`，`XDG_CONFIG_HOME=/tmp/kunlun-eight-pz/config`。

- `godot --headless --path game --script res://tests/test_chapter_eight_puzzles.gd`：602 checks / 0 failures。含非法输入类型/上下文、无瞬移与每拍三条人物边、错误施工/配重、实际木路径、炮整数边界、JSON重放、篡改proof/context、前缀保留与辅助不可下调。
- `test_chapter_eight_puzzle_panel.gd`：93 checks / 0 failures。含568×290最小布局、1000宽自适应、真实输入信号完成三个模型、停止/隐藏、旧button/board/timer与旧题回调、点源池/目标池、点人物目标路径。
- `test_chapter_eight_puzzle_main.gd`：39 checks / 0 failures。真实第7自然档进入第8并合法推进到三面板，实际main的640×360 body/棋盘/关键footer均在可视区，真实hint信号路由与main停止hook通过（无GUI）。
- `chapter_eight_puzzles_process_driver.gd -- write` 和独立Godot进程 `-- read`：三个中途快照均恢复、保留assisted、真实继续至完成并重放最终proof。
- 旧模型回归：第七30320、第六5686、第五3436、第四3027、第三4543、第二1150 checks，全部0 failures。

类型先验测试最初找到type:Array与String比较会报SCRIPT ERROR，已在公共输入入口前置类型判定；修复后上述602项无SCRIPT ERROR。第一次UI导入同时看到其他工人尚在编辑的main缩进错误，已报告集成人员；之后全工程import重新通过，无SCRIPT ERROR/ERROR。

## 尚未执行

本批不做GUI、视觉像素验收、真实鼠标手感、导出或发布；面板图由运行时几何绘制作教学示意，不称最终像素资产。本批实际main停止hook无头已验；真实菜单/F9交互手感与世界/战役联测仍由集成门禁另验。
