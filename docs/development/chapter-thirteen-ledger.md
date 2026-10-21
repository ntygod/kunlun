# 第13章候选与验证台账

本章独立于第12冻结候选5bb6efcd3a6ad4f676f91105bff25892e41aaab1。第11已通过功能门槛合入main d9436e5681e2f3866c72fc06466c624a5874e865，第12正在原云端真实GUI；父线程明确解除此前禁止13的临时协调限制，但本章候选后不启动14。本章未合main，也未宣称自然GUI通过。

## 实现与取舍

26场、90步骤、114对白、8图/空间流程、4机关及B10完整接入。崖山救童、船鲸交替、分水守夜、鲸息与新内功、荒岛造船、至少五轮断后、返航和朝云离别均可按正常输入推进。事务预算4030XP/800铜；快雪死亡与其他宠物存活分别投影，柳生还自主离队保留归队资格。来源冲突与技能边界见[source review](chapter-thirteen-source-review.md)、[preflight](chapter-thirteen-preflight.md)。场景和角色仍是开发像素，不能称成品手工美术。

## 已执行证据

开发集成正常243、最低226、另一选择243、摘要防伪11检查通过。两次依赖集成失败及修复后的通过日志均保留在[campaign清单](chapter-thirteen-evidence/campaign-integration.json)，不把失败历史改写为通过。

最低合法路线实际B10入口33550XP，梁1682/2279HP、42/230MP，ATK297/DEF206/SPD56；五轮实际起锚100，战斗receipt1253HP/134MP。独立战斗按既有规则补满开局MP，多阶段中间不再补。终态最低35595XP、正常38945XP；这些是自动命令工件，不是原云端自然终档。

独立模块验证及跨进程重放见本章evidence清单。实际main使用Input.parse_input_event与真实Control布局，仍属于headless合成输入，不能称桌面原生焦点或像素验收。

## 真实GUI与产品边界

[实机执行单](chapter-thirteen-gui-acceptance.md)从第12未经编辑的自然终档接续。需实际完成主线、船/鲸主控和角色投影、四机关、B10、至少一处部分态及终态独立进程恢复、640控制区与记事。旧存档保护和证据哈希须记录；未经执行的项保持未测。

第11最终索引只由父线程报告：[来源记录](chapter-eleven-evidence/final-gui-index.json)，本环境未下载或查看其截图。第12尚在验收，本章不抢先合入。完整技能查阅/可见内部字符串统一打磨、全部战术及分支、成品手工像素、音画、导出与全产品QA仍未关闭。

## 冻结干净回归

dcf643b027e78ea9ce9dc8a0bfa7a5c83d025ee9通过git archive重建，隔离三个XDG目录：21次执行、1322项检查，全部exit0，无ERROR/WARNING/泄漏。涵盖本章完整合法主线、模型/实际main/摘要、机关与战斗独立进程恢复，以及第12实际main、旧窗口焦点/菜单/保存提示/滚动和基础476项。原53份历史证据逐一大小及SHA256不变。清单[frozen-dcf643b.json](chapter-thirteen-evidence/frozen-dcf643b.json)，原始日志在/workspace/kunlun-validation/ch13-freeze-dcf643b。这是针对本次变更的干净回归，不是重跑所有历史章节全量，也不是GUI。


同步第12 R05重复确认修复ae07797为6a79777，并合入第12后续文档/历史。只改变已完成R05且已确认的第二次弹窗衔接，不改13流程、协议或奖励。6a79777干净归档import/第12新回归46/第13actualmain38/startup全部通过，无错误警告，清单r05-confirm-sync-6a79777.json。未重复全量；本章仍未GUI。
