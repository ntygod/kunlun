# Chapter 9 independent puzzle/world review

Audited frozen 2eb2544 via git archive into /tmp/nine-review; no production files or shared index edited. Latest f5b9579 differs in runtime restore-navigation only among reviewed puzzle/world files.

## Verified
- Read AGENTS, README/game README/development-plan, chapter-nine-content/source-decisions, relevant V3 06 PZ04/L05 and 07 progression/skills/equipment.
- Independent wood test covers three assistance states, partial construction reaching 512, legal retry preserving unknown/assisted attribution, no fabricated construction prefix, same-id prepared-to-flight, half-rail retry to trusted prepared state, malformed action atomic rejection, JSON restore at every flight stage, no final receipt until drifted/both safe. Zero failures.
- Independently reran existing puzzle model, puzzle panel, and world suites: 1422/108/1214 respectively, zero failures; no ERROR/SCRIPT ERROR in logs. These are regression runs, not extra original coverage.
- Actual natural source hash remains 41299aae21511c4a3913c9d15ec124b098c07470ab59fb6bc24d266606adf42e.
- Additional real campaign test: natural source to L05 A; 80 legal actions escorted physician and returned box; no L05 award. JSON campaign restore succeeded. Pause/reopen preserved returned_box and allowed continuation. Pause again and finish main story succeeded; L05 missed with no reward. This was a partial-state test, NOT the 4096 limit.

## Reproduced low-priority boundary
At world_actions/chapter_nine_world_actions.gd:191, the 4096-input limit rejects every further input. A real 80-action A escort/return followed by 4016 legal waits reaches this boundary. The next correct move is rejected; retry is unsupported. Writing the model snapshot and loading it in an independent Godot process preserves returned_box=true but still rejects the next correct move and retry. This is not an illegal-input overflow. It does not establish a whole-chapter blocker; the full-campaign boundary test is pending.

Reproduction: copy test_ch09_l05_limit_review.gd to the frozen checkout game/tests, then run Godot headless with -- write and -- read. Log is nr-limit.log. No reward was granted by model. Do not solve this by clearing physician/raider/branch facts or replaying another method. Root-approved scope is only rejecting/deduplicating provably ineffective inputs, not checkpoint architecture changes and not deduplicating waits that advance actors or time.

## Boundaries
No GUI, visual signoff, exported build, or release verification. F5/F9 callback behavior was read and existing headless panel test rerun; not a fresh manual keyboard workflow. No claim of all historical combinations. Full-campaign 4096 pause/return/main completion remains pending in /tmp/nr-campaign.log. A transient exec-server transport disconnect occurred; connection recovered and evidence files were verified retained.

## Narrow fix recheck at 1407e033be048332478fc79df1808b4212d6e02f
The static-idle limit issue is CLOSED by an independent reproduction on the committed fix. Real A escort/return used 80 actions; 4100 StringName `wait` inputs while nobody moved left the log at 80. A correct next move succeeded. Saved to disk and loaded in a new Godot process, returned_box remained true and the next move succeeded. Continued with formal inputs through the three actual raider exits, treatment, aftermath and archive; complete=true and full receipt replay validated. See nr-patched.log and test_ch09_idle_recheck.gd. No architecture/checkpoint weakening was introduced. The 4096 real-action limit remains a separate residual boundary.

Old-SHA full campaign limit test has now actually reached 4096 and rejected the next correct action. Its full campaign JSON restoration is still running; no final exit result is claimed yet.

## Full campaign cap result (completed)
The existing old-2eb2544 test completed successfully (exit 0). Real natural-source campaign, A escort/return, then 4096 total legal inputs: next correct input rejected. Full campaign JSON restore returned an empty error string, retained returned_box=true, and still rejected the correct next input. pause_sidequest succeeded; reopening succeeded and preserved returned_box with the cap still active. Pausing again and advancing the main story completed chapter 9. L05 ended missed, without its 300 XP award. Thus the cap blocks completing the optional sidequest from that saturated record, not the main chapter. This supersedes the earlier pending status. The patched static-idle regression remains separately closed at 1407e03; real-action saturation remains an acknowledged residual limit.

Evidence: nr-campaign.log and test_ch09_campaign_review.gd. This full-campaign stress run took about 12 minutes including command-history replay on the shared headless test environment; no performance guarantee is inferred.
