## Run 6 OOM Evidence

Source:
- read-only system journal query on `ubuntu@10.0.3.27`
- window: `2026-04-05 08:20:00` to `2026-04-05 08:26:00` local time
- captured after the run to confirm final kill cause

Relevant lines:

```text
Apr 05 08:24:14 kaspa-devnet kernel: systemd-tmpfile invoked oom-killer: gfp_mask=0x140cca(GFP_HIGHUSER_MOVABLE|__GFP_COMP), order=0, oom_score_adj=0
Apr 05 08:24:14 kaspa-devnet kernel: [  pid  ]   uid  tgid total_vm      rss rss_anon rss_file rss_shmem pgtables_bytes swapents oom_score_adj name
Apr 05 08:24:14 kaspa-devnet kernel: [1297859]  1000 1297859 11628452  6472862  6472862        0         0 77496320        0             0 kaspad
Apr 05 08:24:14 kaspa-devnet kernel: oom-kill:constraint=CONSTRAINT_NONE,nodemask=(null),cpuset=/,mems_allowed=0,global_oom,task_memcg=/user.slice/user-1000.slice/session-689.scope,task=kaspad,pid=1297859,uid=1000
Apr 05 08:24:14 kaspa-devnet kernel: Out of memory: Killed process 1297859 (kaspad) total-vm:46513808kB, anon-rss:25891448kB, file-rss:0kB, shmem-rss:0kB, UID:1000 pgtables:75680kB oom_score_adj:0
Apr 05 08:24:14 kaspa-devnet systemd[1]: session-689.scope: A process of this unit has been killed by the OOM killer.
Apr 05 08:24:21 kaspa-devnet systemd[1]: session-689.scope: Deactivated successfully.
Apr 05 08:24:21 kaspa-devnet systemd[1]: session-689.scope: Consumed 15h 5min 35.515s CPU time.
```

Interpretation:
- the final termination was not a mystery process exit
- the kernel killed `kaspad` for memory pressure
- this does not by itself prove the exact code path that caused memory growth
- taken together with the run artifacts, the stronger operational story is:
  - node fell behind near prune / recovery
  - entered a bad stuck state
  - RSS kept climbing
  - kernel OOM killer delivered the final kill
