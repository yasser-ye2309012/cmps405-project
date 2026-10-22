# CMPS405 Project: Team Checklist (v2)

Repo (private): https://github.com/yasser-ye2309012/cmps405-project
Every step below is a GitHub issue whose title starts with its step number, e.g. `[09] Remote.sh`. **Do the steps in that order** (the `#` number GitHub shows is just an ID; the `[NN]` tag is the order).

## Who owns what

| Member | Steps |
|---|---|
| Member 1 | [01] repo, [02] VMs and network, [03] Users.sh, [04] Install.sh, [05] Connectivity.sh |
| Member 2 | [07] SysInfo.sh, [10] Search.sh, [11] Network.sh, [16] QA, [17] Word report, [18] submission |
| Member 3 | [12]-[13] FileSystem.sh, [14]-[15] C program |
| Member 4 | [06] LogServer.sh, [08] LogClient.sh, [09] Remote.sh |
| All | [19] demo rehearsal |

---

## 0. Everyone: get started

- [ ] Accept the GitHub invitation (check your email)
- [ ] Install Git for Windows (includes Git Bash) and VS Code
- [ ] Clone: `git clone https://github.com/yasser-ye2309012/cmps405-project.git`
- [ ] Copy `config.example.txt` to `config.txt` and fill it in (git-ignored, never commit it)
- [ ] VS Code: set line endings to **LF** for `.sh`/`.c` files (click `CRLF` in the bottom bar); install the **ShellCheck** extension; use **Git Bash** as terminal on Windows
- [ ] Find your issues: Issues tab, filter by label `member-1` ... `member-4`
- [ ] Confirm the real submission deadline with the instructor (the spec says both 14 Oct and 31 Oct)

**Where to work:** write code on your PC (VS Code + git); **run, test and screenshot only inside the VMs** (Ubuntu). Windows cannot run `apt`, `systemctl`, `ufw`, `useradd`. Get scripts onto the VM with `git clone` / `git pull` (HTTPS + GitHub personal access token) or `scp`.

## 1. How we work

1. Take an issue, drag it to **In progress** on the board.
2. Branch: `git checkout -b m2/search-sh`
3. Write the script: header comment, inline comments on every logical block, file name exactly as in the spec.
4. Run it **twice** on the VM; the second run must also be error-free.
5. Screenshots: full window, prompt with hostname visible, taken inside the VM. Name: `<VM>_<Script>_Task<N>_<what>.png` (e.g. `ALPHA_Users.sh_Task1_run2.png`) in `screenshots/alpha`, `screenshots/beta` or `screenshots/c-program`. Copy sample outputs (logs, bigfile) into `logs/`.
6. Commit, push, open a pull request with `Closes #<issue>`.
7. Reviewer reads it and must be able to explain it. Merge.
8. If someone is waiting on you, post a handoff comment on the issue:
   ```
   HANDOFF -> Member X
   Done: what works and how to run it
   You need: IPs, usernames, file paths, commands
   Watch out for: known issues
   ```
9. Move the issue to **Done**. If you are waiting on someone, move yours to **Blocked** and say who.

**Reviewers:** M1 reviewed by M3, M2 by M4, M3 by M2, M4 by M1.
**Passwords** go in private chat, never in the repo. Only Member 2 edits the Word report; everyone else commits screenshots.

### Who waits on whom
```
[02] VMs ─────────────► everything else (testing)
[03] Users, [04] Install ─► [09] Remote
[07] SysInfo ─────────► [09] Remote
[06] LogServer ───────► [08] LogClient
[03]..[15] all done ──► [16] QA ─► [17] Report ─► [18] Submit
```
You can **draft** scripts before the VMs exist; only the testing waits.

---

## 2. Member 1: foundation and early scripts

### [01] Finish repo setup
- [ ] All members added and invitations accepted
- [ ] README team table and owners updated
- [ ] Project board created; all issues added
- [ ] `setup_repo.sh` and `new_issues.sh` removed from the repo
- **Deliverable:** everyone can push and sees the board.

### [02] VMs, network, hostnames
- [ ] Create ALPHA and BETA VMs (Ubuntu 26.04 LTS Desktop)
- [ ] Same network; IPs recorded in `config.txt`
- [ ] Hostnames `alpha` / `beta`; both in `/etc/hosts` on each VM
- [ ] Ping by IP and by hostname, both directions; snapshot both VMs
- **Deliverable:** reachable VMs + handoff comment with IPs and hostnames; ping screenshots. **Blocks everyone's testing.**

### [03] `Users.sh` (ALPHA Task 1)
- [ ] Loop creating `user1`..`user10` with home directories and passwords
- [ ] Report "already exists" instead of failing
- [ ] Add all to `sudo`; display accounts and groups
- [ ] Run twice; screenshot both runs
- **Deliverable:** `scripts/alpha/Users.sh`, screenshots. Handoff to M4: `user1` login.

### [04] `Install.sh` (ALPHA Task 2)
- [ ] `apt update`/`upgrade`; install MySQL, restart, print "system will be reloaded"
- [ ] Install SSH, FTP (`vsftpd`), Apache
- [ ] Enable MySQL, SSH, Apache at boot; display each status
- [ ] Errors to `Installation.log`; display the log
- **Deliverable:** `scripts/alpha/Install.sh`, `logs/Installation.log`, screenshots. Handoff to M4: SSH + Apache running, `http://alpha/` loads.

### [05] `Connectivity.sh` (BETA Task 1)
- [ ] Ping ALPHA with timestamp, append to `/tmp/SecondVM.txt`
- [ ] Schedule with cron `*/5 * * * *`; prepare the cron-fields explanation
- [ ] Wait 10+ min; screenshot the file with several entries and `crontab -l`
- **Deliverable:** `scripts/beta/Connectivity.sh`, screenshots.

---

## 3. Member 2: SysInfo, Search, Network, then QA, report, submission

### [07] `SysInfo.sh` (BETA Task 3)
- [ ] Disk, CPU, memory, installed apps, NIC info
- [ ] One timestamped report file
- **Deliverable:** `scripts/beta/SysInfo.sh`, sample report in `logs/`, screenshots. Handoff to M4: report file name pattern and location.

### [10] `Search.sh` (ALPHA Task 3)
- [ ] Find files > 1M in your account; write to `bigfile` with date and count
- [ ] Configure `msmtp` (Gmail/Live app password)
- [ ] If `bigfile` is non-empty, email its contents to a personal address
- [ ] Screenshot the run and the received email
- **Deliverable:** `scripts/alpha/Search.sh`, `logs/bigfile`, screenshots.

### [11] `Network.sh` (ALPHA Task 4)
- [ ] Install missing tools first (`net-tools`, `dnsutils`, `traceroute`)
- [ ] Show network config, routing table, hostname; test DNS, `traceroute google.com`, `ping google.com`
- [ ] Output to `network.log` and the screen
- **Deliverable:** `scripts/alpha/Network.sh`, `logs/network.log`, screenshots.

### [16] QA pass
- [ ] Every script run twice from a clean snapshot; errors sent to the owner
- [ ] Inline comments present; names match the spec exactly
- [ ] Every screenshot: caption (VM, script, task), hostname prompt visible, full capture
- **Deliverable:** signed-off QA comment.

### [17] Word report
- [ ] Cover page (names, IDs, section)
- [ ] Task distribution table with honest contribution percentages
- [ ] Screenshots only in the body, captioned; no source code
- Tip: build the skeleton early, add screenshots as they are merged.
- **Deliverable:** `report/CMPS405_Report.docx`

### [18] Zip and submit
- [ ] `Name1_Name2_Name3_Name4.zip` (report + all scripts) uploaded to Blackboard; receipt screenshot saved

---

## 4. Member 3: FileSystem.sh and the C program

### [12] `FileSystem.sh` function 1
- [ ] `/tmp/Disk_Usage.txt` (home usage in KB, reverse sorted)
- [ ] `/tmp/cpu_info.txt` (Architecture, CPU(s), Model name, Vendor ID only)
- [ ] `/tmp/Messages_Log.txt` (memory + disk kernel lines only; `sudo dmesg`)
- [ ] `/tmp/Message_count.txt` (word counts of memory and disk lines)
- [ ] `Phase1.tar.bz2` copied into a directory named `ddHHMMSS`
- **Deliverable:** function 1 + screenshots of each file.

### [13] `FileSystem.sh` functions 2 and 3 (after [12])
- [ ] Create test files with owner read+execute only
- [ ] Copy to a directory named `yymmddHHMMSS`; make read-only for owner
- [ ] Verify: count non-read-only files (must be 0), report each as an error
- [ ] Print total files, backup size, end message with time; run twice
- **Deliverable:** complete `scripts/alpha/FileSystem.sh`, screenshots.

### [14] C program: cores, fork, arguments
- [ ] Core count with `sysconf`; use half (minimum 1)
- [ ] All arguments from the CLI; parent creates the log before forking
- [ ] `fork()` loop; parent waits for all children
- **Deliverable:** compiling skeleton in `c-program/`, screenshot.

### [15] C program: six tasks and logging (after [14])
- [ ] Random task per sibling: create, delete, copy, file info, search word, list directory
- [ ] Each sibling appends a success line with the time to the log; parent prints the log
- [ ] `gcc -Wall` with zero warnings; inline comments; several runs showing different assignments
- **Deliverable:** `c-program/*.c`, screenshots of compile, runs, printed log.

---

## 5. Member 4: logging and remote access

### [06] `LogServer.sh` (ALPHA Task 6)
- [ ] Install/enable rsyslog; receive on UDP + TCP 514
- [ ] Per-host files `/var/log/remote/<hostname>/<hostname>.log`
- [ ] Firewall: allow SSH first, then 514 from BETA only, then enable
- [ ] Restart; confirm listening on 514; `logger` test message shown
- [ ] Logrotate daily, 7 kept; output to `/var/log/logserver_setup.log`; final status printed
- **Deliverable:** `scripts/alpha/LogServer.sh`, `logs/logserver_setup.log`, screenshots.

### [08] `LogClient.sh` (BETA Task 4, after [06])
- [ ] Check ALPHA:514 reachable, else exit with a clear error (test once)
- [ ] Set hostname; install rsyslog; forward all messages to ALPHA:514; restart
- [ ] Events: `sudo` command, failed SSH login INTO BETA (from ALPHA), manual `logger` message
- [ ] Verify all three in `/var/log/remote/` on ALPHA
- **Deliverable:** `scripts/beta/LogClient.sh`, screenshots from both VMs.

### [09] `Remote.sh` (BETA Task 2, after [03], [04], [07])
- [ ] `ssh-keygen` on BETA; `ssh-copy-id` to `user1@alpha`
- [ ] SSH and SFTP with no password prompt; run a remote command
- [ ] Fetch `index.html` from the ALPHA web server and save it
- [ ] SFTP upload of the sysinfo report (batch mode); confirm it arrived
- **Deliverable:** `scripts/beta/Remote.sh`, saved `index.html`, screenshots.

---

## 6. Everyone

### [19] Demo rehearsal (after [16])
- [ ] Each member explains one other member's script line by line
- [ ] Each member can re-run any task live from a clean snapshot
- [ ] Cron fields, UFW order, rsyslog template, fork/wait explained without notes

## Final checks
- [ ] Every script runs twice with no errors; inline comments; exact spec names
- [ ] Every task has a screenshot with VM, script, task number and hostname prompt
- [ ] No source code in the report; distribution table honest
- [ ] Zip named correctly and uploaded to Blackboard
