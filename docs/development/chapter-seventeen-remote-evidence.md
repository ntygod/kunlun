# 第17章远端发布验证 · 2026-10-23

## 冻结版本与来源

- 源基线：`00995d57b968744fea6c7b412e7d6b0fea5de334`。
- 经过校验的完整候选树（不含一次性发布工作流）：`52d2269e40ed4576ff6ca060205e153201bdba05`。
- 验证运行：GitHub Actions `39901532276`，作业 `120243993177`，全部步骤completed/success。
- 该运行先重建并核对候选树，然后实际执行测试，最后非强制提交到develop：`45fb15fb151df749bbc3044d3f80023f4f475067`。此提交暂含原样保留的一次性发布工作流；Actions令牌没有修改工作流权限或绕过权限限制。
- 原始artifact：`12479496078`；ZIP SHA256 `feda5013bbbf7af36a09b9483926c7a050eb1062e52ce9a0ca49d7c9c834f9cd`。已下载检查summary.json、publication.json、两个capture-report.json及全部38个日志的SHA256，不是仅查看状态。

## 实际结果

38次执行全部通过，含数据校验、Godot4.6.3干净导入、公共系统和第14—16章受影响回归、第17两条主线与可选任务窗口、战斗、机关、事务、主场景控件、跨进程保存与原生渲染。

非图形脚本实际输出4952 checks / 0 failures；原生X11另681 checks / 0 failures（第16章361，第17章320）。原生检查包含与headless重复的路径，不将累计断言当作独立功能数。第16入口生成器输出64 steps，不把这些步骤额外计作checks。

第17章本轮战斗为138项，包含新增实际败局、败局严格恢复、空奖励收据及战前原资源重试；并非沿用本地早一轮118项的结果。

截图34张：chapter16目录16张，chapter17目录18张；两章报告独立，640×360和1280×720各有覆盖。第17包括六证勘查板、新屋图板、三人B13与四页记事，图板和地图仍是开发资源。9类跨进程状态均由合法模型输入生成，不手改成功标志。

仅原生Xvfb/Mesa出现已记录的精确告警：`Could not set V-Sync mode, as changing V-Sync mode is not supported by the graphics driver.` 该环境告警单列，其余SCRIPT ERROR/ERROR/WARNING仍判失败。不声称所有日志零告警。

## 清理与持续验证

随后通过连接的GitHub接口清理两个临时工作流（source snapshot及chapter17 publication），保留只读持续验证；将章节台账纳入持续验证的路径触发。该清理不改变game/或tools/生产代码、数据或测试。清理提交的持续验证以PR17当前提交真实运行结果为准，不能在运行结束前声称通过。

main仍为`7298b2d89c50a45009f8dd1665b12597712e034c`，只保留main/develop，未自动合并主干。

## 验收边界

这些是模型命令、应用控件和原生渲染证据，不是第14—17章完整OS键鼠自然通关。历史自然档、全部战术/选择组合、持续保存性能、最终像素人物地图动作、音频、Windows导出及策划时长仍未验。第18—20章没有实现。源策划未改，来源冲突及未实现的R07数值回响见chapter-seventeen-source-review.md。
