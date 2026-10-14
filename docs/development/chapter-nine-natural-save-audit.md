# 第09章自然GUI原始存档只读审计

2026-10-14；正式恢复引擎基准 `d9e13583c1cd19c2df0bdd47a18d29bf416bb0eb`。独立headless进程调用Campaign.restore_persisted，隔离XDG，不推进GUI、不编辑任何入口或结果文件。GUI亲见范围与刷新期间操作缺口另见GUI操作者报告，本审计仅证明原始存档可正式重放与其实际状态。

## 最终档

`output/cache/chapter_nine_gui/manual_natural_final.json`，48141字节，SHA256 `e70144a3feb471293a5ec3cd47988cbbd4cc5b9db5f7ec387aa2d4acd9f9b06d`。正式restore后第9章finished，69检查/0失败：

- 20795XP，Lv47，3050铜。梁1404/1404HP、122/151MP；柳919/1130HP、83/127MP；阿雪Lv23、236/480HP、75/75MP。
- 相对原第8自然终档，所有旧items Dictionary等价，梁柳标准装备不变。王可、赵山、杨榷为dead；李庭、囊古歹、土土哈alive。
- 松针500、木鸟500、血井300、L05 300各单次账项；L05归档，铜钥匙及蛇眼魔钻各1。
- 朝廷将军印、袍、军功甲、独立赏银箱均owner=camp、location=linan_tent_rack。共用钱与旧装备保留。
- 大木鸟最终state=completed、location=river_drifted_away、portable=false。首版审计误将“drifted阶段”当最终归档字段，修正夹具后69/0；没有修改生产或原档。
- 原第8自然档仍39290字节，SHA256 `41299aae21511c4a3913c9d15ec124b098c07470ab59fb6bc24d266606adf42e`。

可复用审计 `game/tests/chapter_nine_natural_save_audit.gd`；需保留实际0/8/9工程内容与上述两份自然测试夹具。日志 `/tmp/ch09-final-gui-audit-final.log`。

## 原始部分态核验

- wood_prepared：57091B，690387a78afc2dfe203d0015499fdaf3e9e127235435e00389d89c4cdd37b1b1。assembled :01，checkpoint prepared/manual/hint0/未辅助，六件与四连接/真实双人工位齐全；18445XP/2450铜，木鸟500未发。
- wood_rail_index1：57765B，b3fca894138199d7700e86690f419ca716ed946b5ab8a09a4a3d361f9cade730。cloud_escape :00，rail_moving/index1，双乘客/cranks2，18545XP/2450铜，500未发。
- wood_cloud_exit：58626B，0a7c54041cfb3529e22e06b296dbc084e630f7410c22409c08fbcb5b0ed60d92。实际cloud_exit，仍在同一个flight事件。
- wood_drifted：58916B，3d4e0b7396a1e2414206c3e42336c9039fe3b48408cf247bd38154146acd1a77。完整flight已drifted，进入事后阶段叙述 :01；木鸟500此时仍未接账，后续proof_complete才发。
- l05_physician_escort_partial：70598B，84dc8937ae248218f20ab326d9fad66b7f41c0a92f0563188ede9c39f5e8b6ce。L05:00/A，医生与梁416,144；医生实际112→128→144三点，escorting=true但未还箱/治疗/归档。
- l05_refresh_observed：79366B，921d1bb3caddffcf5e00c3f2f7b3d0887defd9e2ede0dded5ca9068a1d64d1b8。前207事件完整不变，新57条=41move+13wait+return_box/interact/disarm各1，全部正式重放合法。医生128,160已返箱，第一贼368,176卸刀退场中但尚未departed。该57条只有原始存档证据，不能补写成操作者亲见。
- l05_archived：87612B，c7b817c525dff3112255f8799cc0d9ff8647501cca0ed0848d28b735e43cf80b。已回main/window :01，19805XP/2450铜，L05 archived、单300与钥匙；三贼完整逐格路径至416272/432272/448272并不可见，医生救回已治疗。
- well_observe_partial：200465B，de8019b66d11ae5ceef92810025ea000bf922c3fff3a084daa12e1557d808ef1。blood_well :01，两兵事件history仅observe soldier1；round2/revision2/pressure2，无退休者，1376/1376HP、122/149MP。
- well_disarm_one_partial：204537B，83c2b6c5bd6f01b4dfee98c19bc2d5e131e9a87f942400fb92470143a48a3634。history只有observe/disarm soldier1，第一兵完整12点路径到560240退休，第二兵未动；原scope仍两兵事件。

以上原字节分别独立restore成功，不依赖文件名判阶段。图片和最终自然线路亲见情况由独立GUI报告记录；不能把自动化/部分态重放替代视觉验收，也不把本章自然路线当全部历史分支。
