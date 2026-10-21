# 第十二章战斗独立进程存档检查

脚本：`game/tests/chapter_twelve_battle_process_driver.gd`。参数必须是 `-- write` 或 `-- read`，分两次Godot启动；读进程核对PID不同。write要求环境变量`CH12_SOURCE`指向可由正式恢复接口验证、已归档的第11章终档。没有默认旧档或假章号兜底。

两次调用共享三个独立XDG目录。write按Flow12真实对白、选择、谜题和世界输入走到韩、雷、楚、蚩尤四场战斗；每场由真实session.set_command编排一条self_guard，调用save_objective_checkpoint和prepare_persisted_save保存。继续前往下一场也使用合法战斗驱动与收据，不编辑HP、进度或通关状态。

输出只写专用`user://chapter_twelve_battle_process/`：四个以战斗ID命名的JSON，以及manifest.json。清单包含来源SHA256、writer PID、每档哈希/字节数、token、scene、位置、完整pending session快照。write开始将清单标为incomplete，四档均成功才置为完整。read验证路径白名单和文件哈希，通过Campaign.restore_persisted重建，核对位置/token/session，再以Battle.run继续、保存真实结算检查点并accept_objective；旧收据不得重复推进，结算后的状态还须能prepare_persisted_save。

运行示例（从仓库根目录；两个命令必须是不同进程）：

```sh
CH12_SOURCE=/absolute/path/chapter11-terminal.json XDG_CACHE_HOME=/tmp/ch12-battle-process/cache XDG_DATA_HOME=/tmp/ch12-battle-process/data XDG_CONFIG_HOME=/tmp/ch12-battle-process/config godot --headless --path game --script res://tests/chapter_twelve_battle_process_driver.gd -- write
XDG_CACHE_HOME=/tmp/ch12-battle-process/cache XDG_DATA_HOME=/tmp/ch12-battle-process/data XDG_CONFIG_HOME=/tmp/ch12-battle-process/config godot --headless --path game --script res://tests/chapter_twelve_battle_process_driver.gd -- read
```

## 本轮真实结果

2026-10-21，战斗冻结依据363390b。来源`/workspace/kunlun-validation/ch12-source/ch12-command-terminal.json`，SHA256 `2ee4e7e97d8741113c088639300a9fd850719f43745f56bcfb2e3771e45c1cb7`；调用前后未改动。它是先前通过正规命令生成的第11终档，不称自然GUI终档。

- write PID24842：105检查，0失败；四场pending guard存档成功。
- read PID24898：52检查，0失败；四档精确恢复、合法续战、检查点和一次推进全部通过。
- 韩`ch12_duel_han:01→02`；雷`ch12_duel_lei:02→03`；楚`ch12_duel_chu:01→02`；蚩尤`ch12_chiyou_b09:07→08`。
- 两份临时原始日志`/tmp/ch12-battle-process-write.log`与`/tmp/ch12-battle-process-read.log`均无SCRIPT ERROR或ERROR。输出位于上述独立XDG_DATA_HOME的Godot user目录。

此项证明跨OS进程的真实pending battle存读档和合法续战，不证明键鼠F5/F9事件路由、实机画面、自然游玩节奏或导出包验收。
