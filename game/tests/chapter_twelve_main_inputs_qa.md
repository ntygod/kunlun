# 第十二章真实 main 输入回归

2026-10-21：Godot 4.6.3 headless 执行 `test_chapter_twelve_main_inputs.gd`，66 checks，0 failures，退出码 0，日志无 `SCRIPT ERROR` / `ERROR:`。测试时共享开发树 HEAD 为 `74b635d6687f72377ff96d4fa3589518a206ea8e`，包含正在集成的第十二章生产文件及主界面失焦路由修复；这不是该 SHA 干净检出的完整验收。

输入是正式第十一章命令回放终档，不是自然实机存档：

- 文件：`/workspace/kunlun-validation/ch12-source/ch12-command-terminal.json`
- SHA256：`2ee4e7e97d8741113c088639300a9fd850719f43745f56bcfb2e3771e45c1cb7`
- 通过正式恢复、注册章节入口和 Flow12 合法前缀到达竹丝夺械；不直接构造世界状态或改写源存档。

测试实际实例化 `main.tscn`，经 `Input.parse_input_event` 注入键盘与鼠标事件，覆盖两次连续原生按钮点击、同阶段按钮实例稳定、键盘移动与 Enter 目标动作、echo、失焦阻断、待释放鼠标取消、菜单暂停和返回、F5 实际写入及 F9 还原输入历史/位置/控制者。失焦期间 F5、菜单返回与 F9 都不能重新启用世界输入；必须收到 FOCUS_IN 后使用新输入。640×360 与 1280×720 检查实际控件矩形，重新实例化 main 后通过 F9 恢复同一文件，源存档字节保持不变。

```sh
CH12_SOURCE=/workspace/kunlun-validation/ch12-source/ch12-command-terminal.json \
XDG_CACHE_HOME=/workspace/kunlun-validation/ch12-main-inputs/cache \
XDG_DATA_HOME=/workspace/kunlun-validation/ch12-main-inputs/data \
XDG_CONFIG_HOME=/workspace/kunlun-validation/ch12-main-inputs/config \
godot --headless --path game --script res://tests/test_chapter_twelve_main_inputs.gd
```

本次原始日志：`/workspace/kunlun-validation/ch12-main-inputs/focus-final.log`。运行与存档均使用隔离 XDG 目录。

边界：自动运行被暂停以隔离输入断言，事件仍经实际 main 路由。该结果不是人工 GUI、截图像素、美术或计时验收；新的 main 实例仍在同一操作系统进程，不冒充跨进程恢复。仅检查进入第十二章及第一个竹丝目标，不覆盖 B08、B09、R05 或全章终态。一次读取日志遭遇 exec-server transport disconnected；随后原会话确认退出 0、日志读取恢复，未重启该未确定测试。
