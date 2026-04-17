Run 7 rerun OOM evidence.

Source
- `oom-journal.txt`
- captured from the GMK Nucbox G5 host after the rerun ended

Key lines
- `Apr 05 20:07:07 gmk kernel: oom-kill: ... task=kaspad,pid=888844,uid=1000`
- `Apr 05 20:07:07 gmk kernel: Out of memory: Killed process 888844 (kaspad) total-vm:34347924kB, anon-rss:11262924kB, file-rss:128kB, shmem-rss:0kB, UID:1000 pgtables:49440kB oom_score_adj:0`
- `Apr 05 20:07:07 gmk systemd[1]: session-461.scope: A process of this unit has been killed by the OOM killer.`

Meaning
- Final run termination was a kernel OOM kill.
- This was not a graceful stop and not a wrapper-driven shutdown.
- The wrapper later observed process exit and finalized the run artifacts.
