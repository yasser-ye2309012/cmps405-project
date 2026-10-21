#!/usr/bin/env bash
# setup_repo.sh - run ONCE by Member 1 from the root of the freshly cloned repo.
# Requirements: git, GitHub CLI (gh) logged in with `gh auth login`.
# Run it before any pull request exists, so issue numbers start at #1
# (the "Blocked by #N" references below rely on that order).
set -euo pipefail

# ---- 1. Fill in the four GitHub usernames (leave empty to skip assigning) ----
M1=""
M2=""
M3=""
M4=""

# ---- 2. Folder structure (.gitkeep so git tracks empty folders) ----
mkdir -p scripts/alpha scripts/beta c-program logs report \
         screenshots/alpha screenshots/beta screenshots/c-program
for d in scripts/alpha scripts/beta c-program logs report \
         screenshots/alpha screenshots/beta screenshots/c-program; do
  touch "$d/.gitkeep"
done

# Keep real credentials out of the repo
cat > .gitignore <<'EOF'
config.txt
*.swp
*~
*.pcap
EOF

# Force LF line endings so scripts don't break when a teammate uses Windows
cat > .gitattributes <<'EOF'
*.sh text eol=lf
*.c  text eol=lf
EOF

cat > config.example.txt <<'EOF'
# Copy to config.txt (git-ignored) and fill in. NEVER commit config.txt.
ALPHA_IP=
BETA_IP=
ALPHA_HOST=alpha
BETA_HOST=beta
TEST_USER=user1
# Password is shared privately (chat), not in the repo
ADMIN_EMAIL=
EOF

git add -A
git commit -m "Scaffold folder structure, gitignore, gitattributes, config template" || true
git push origin HEAD

# ---- 3. Labels ----
mk_label() { gh label create "$1" --color "$2" --description "$3" --force; }
mk_label member-1  "1f77b4" "Owned by Member 1"
mk_label member-2  "2ca02c" "Owned by Member 2"
mk_label member-3  "9467bd" "Owned by Member 3"
mk_label member-4  "ff7f0e" "Owned by Member 4"
mk_label alpha     "0e8a16" "Runs on ALPHA (server VM)"
mk_label beta      "fbca04" "Runs on BETA (client VM)"
mk_label c-program "5319e7" "Part 2: C system programming"
mk_label setup     "bfd4f2" "Repo / environment setup"
mk_label qa-report "d93f0b" "QA, screenshots, report, submission"
mk_label blocked   "b60205" "Waiting on another issue"
mk_label demo      "c5def5" "Demo preparation"

# ---- 4. Milestones ----
# Add due dates later in the GitHub UI once the real deadline is confirmed.
for m in "1 Environment ready" "2 Scripts built" "3 Screenshots collected" \
         "4 Report and submission" "5 Demo rehearsal"; do
  gh api "repos/{owner}/{repo}/milestones" -f title="$m" >/dev/null
done

# ---- 5. Issue helper: mk "title" "labels" "assignee" "milestone" <<'EOF' body EOF ----
mk() {
  local title="$1" labels="$2" who="$3" ms="$4" body
  body="$(cat)"
  local args=(--title "$title" --label "$labels" --milestone "$ms" --body "$body")
  [ -n "$who" ] && args+=(--assignee "$who")
  gh issue create "${args[@]}"
}

# ================= SETUP / MEMBER 1 =================
mk "Repo, project board and conventions" "setup,member-1" "$M1" "1 Environment ready" <<'EOF'
- [ ] Repo is private and all 4 members are collaborators
- [ ] README filled in (names, IDs, section, IPs)
- [ ] Project board created (Todo / In progress / Blocked / In review / Done)
- [ ] Everyone has copied config.example.txt to config.txt locally

**Deliverable:** working repo that every member can push to.
EOF

mk "Create VMs, network, hostnames, /etc/hosts" "setup,member-1,alpha,beta" "$M1" "1 Environment ready" <<'EOF'
- [ ] Create ALPHA VM (Ubuntu 26.04 LTS Desktop)
- [ ] Create BETA VM (Ubuntu 26.04 LTS Desktop)
- [ ] Both VMs on the same network; IPs recorded in config.txt
- [ ] Hostnames set to `alpha` and `beta`
- [ ] Both hosts added to /etc/hosts on each VM
- [ ] Ping works by IP and by hostname, both directions
- [ ] Snapshot both VMs

**Deliverable:** reachable VMs + HANDOFF comment to all members (IPs, hostnames). Screenshot of the pings.
**Blocks:** every other issue.
EOF

mk "Users.sh (ALPHA Task 1)" "member-1,alpha" "$M1" "2 Scripts built" <<'EOF'
- [ ] Loop creating user1..user10 with home directories and passwords
- [ ] Report "already exists" instead of failing
- [ ] Add every user to the sudo group
- [ ] Display accounts and group memberships
- [ ] Run twice (second run shows "already exists")
- [ ] Screenshots of both runs + verification

**Deliverable:** scripts/alpha/Users.sh + screenshots. HANDOFF to Member 4: username user1 and where the password is shared.
**Blocked by:** #2
EOF

mk "Install.sh (ALPHA Task 2)" "member-1,alpha" "$M1" "2 Scripts built" <<'EOF'
- [ ] apt update/upgrade
- [ ] Install MySQL, restart, print the "system will be reloaded" message
- [ ] Install SSH, FTP (vsftpd), Apache
- [ ] Enable MySQL, SSH, Apache at boot; display each status
- [ ] Errors go to Installation.log; display the log
- [ ] Screenshots

**Deliverable:** scripts/alpha/Install.sh, logs/Installation.log, screenshots. HANDOFF to Member 4: SSH + Apache running, http://alpha/ loads.
**Blocked by:** #2
EOF

mk "Connectivity.sh (BETA Task 1)" "member-1,beta" "$M1" "2 Scripts built" <<'EOF'
- [ ] Ping ALPHA with timestamp, append to /tmp/SecondVM.txt
- [ ] Schedule every 5 minutes with cron (*/5 * * * *)
- [ ] Prepare demo explanation of the 5 cron fields
- [ ] Wait 10+ min; screenshot file with several entries and `crontab -l`

**Deliverable:** scripts/beta/Connectivity.sh, screenshots.
**Blocked by:** #2
EOF

mk "QA pass on all scripts and screenshots" "member-1,qa-report,blocked" "$M1" "3 Screenshots collected" <<'EOF'
- [ ] Every script run twice from a clean state, errors reported to owner
- [ ] Inline comments present, file names match the spec exactly
- [ ] Every screenshot: caption (VM, script, task), hostname prompt visible, full capture
- [ ] Sample outputs copied to logs/

**Deliverable:** QA checklist signed off in a comment.
**Blocked by:** #3 #4 #5 #9 #10 #11 #12 #13 #14 #15 #16 #17 #18
EOF

mk "Build the Word report" "member-1,qa-report" "$M1" "4 Report and submission" <<'EOF'
- [ ] Cover page (names, IDs, section)
- [ ] Task distribution table with contribution percentages
- [ ] Screenshots only in the body, captioned by VM / script / task
- [ ] No source code pasted

**Deliverable:** report/CMPS405_Report.docx
**Blocked by:** #6
EOF

mk "Zip and submit on Blackboard" "member-1,qa-report" "$M1" "4 Report and submission" <<'EOF'
- [ ] Zip named Name1_Name2_Name3_Name4.zip (report + all scripts)
- [ ] Uploaded on Blackboard before the deadline (confirm 14 Oct vs 31 Oct with the instructor)
- [ ] Submission receipt screenshot saved

**Blocked by:** #7
EOF

# ================= MEMBER 2 =================
mk "Search.sh (ALPHA Task 3)" "member-2,alpha" "$M2" "2 Scripts built" <<'EOF'
- [ ] find files > 1M in the home directory
- [ ] Write results to bigfile with the date and number of files
- [ ] Configure msmtp (Gmail/Live app password)
- [ ] If bigfile is not empty, email its contents to a personal address
- [ ] Screenshot the run and the received email

**Deliverable:** scripts/alpha/Search.sh, logs/bigfile, screenshots.
**Blocked by:** #2
EOF

mk "Network.sh (ALPHA Task 4)" "member-2,alpha" "$M2" "2 Scripts built" <<'EOF'
- [ ] Install missing tools first (net-tools, dnsutils, traceroute)
- [ ] Show network config, routing table, hostname
- [ ] Test DNS, traceroute google.com, ping google.com
- [ ] Output to network.log and the screen

**Deliverable:** scripts/alpha/Network.sh, logs/network.log, screenshots.
**Blocked by:** #2
EOF

mk "SysInfo.sh (BETA Task 3)" "member-2,beta" "$M2" "2 Scripts built" <<'EOF'
- [ ] Disk, CPU, memory, installed applications, NIC info
- [ ] One timestamped report file
- [ ] Screenshots

**Deliverable:** scripts/beta/SysInfo.sh, sample report in logs/, screenshots. HANDOFF to Member 4: report file name pattern and location (needed by Remote.sh upload).
**Blocked by:** #2
EOF

# ================= MEMBER 3 =================
mk "FileSystem.sh: function 1 (reports + Phase1.tar.bz2)" "member-3,alpha" "$M3" "2 Scripts built" <<'EOF'
- [ ] /tmp/Disk_Usage.txt (home usage in KB, reverse sorted)
- [ ] /tmp/cpu_info.txt (Architecture, CPU(s), Model name, Vendor ID only)
- [ ] /tmp/Messages_Log.txt (memory + disk kernel lines only; use sudo dmesg)
- [ ] /tmp/Message_count.txt (word counts of memory and disk lines)
- [ ] Phase1.tar.bz2 copied into a directory named by time (ddHHMMSS)

**Deliverable:** function 1 of scripts/alpha/FileSystem.sh + screenshots of each file.
**Blocked by:** #2
EOF

mk "FileSystem.sh: functions 2 and 3 (backup + verification)" "member-3,alpha" "$M3" "2 Scripts built" <<'EOF'
- [ ] Create test files with owner r-x only
- [ ] Copy them into a directory named yymmddHHMMSS; make them read-only for owner
- [ ] Verify: count non-read-only files (must be 0), report each as an error
- [ ] Print total files backed up, backup directory size, end message with time
- [ ] Script calls all three functions; run twice

**Deliverable:** complete scripts/alpha/FileSystem.sh + screenshots.
**Blocked by:** #12
EOF

mk "C program: cores, fork, CLI arguments" "member-3,c-program,alpha" "$M3" "2 Scripts built" <<'EOF'
- [ ] Get core count (sysconf); use half (minimum 1)
- [ ] Parse all arguments from the command line
- [ ] Parent creates the log file before forking
- [ ] fork() loop; parent waits for all children

**Deliverable:** compiling skeleton in c-program/, screenshot.
**Blocked by:** #2
EOF

mk "C program: six tasks, random assignment, logging" "member-3,c-program,alpha" "$M3" "2 Scripts built" <<'EOF'
- [ ] Random task per sibling: create, delete, copy, file info, search word, list directory
- [ ] Each sibling appends a success line with the time to the log
- [ ] Parent prints the log at the end
- [ ] Compile with gcc -Wall, zero warnings; inline comments
- [ ] Several runs showing different random assignments

**Deliverable:** c-program/*.c, screenshots of compile, runs, printed log.
**Blocked by:** #14
EOF

# ================= MEMBER 4 =================
mk "LogServer.sh (ALPHA Task 6)" "member-4,alpha" "$M4" "2 Scripts built" <<'EOF'
- [ ] Install/enable rsyslog; receive on UDP + TCP 514
- [ ] Per-host files: /var/log/remote/<hostname>/<hostname>.log
- [ ] Firewall: allow SSH first, then 514 from BETA only, then enable
- [ ] Restart; confirm listening on 514
- [ ] logger test message shown in the log
- [ ] Logrotate: daily, 7 kept
- [ ] Output saved to /var/log/logserver_setup.log; final status printed

**Deliverable:** scripts/alpha/LogServer.sh, logs/logserver_setup.log, screenshots. HANDOFF note: ALPHA accepts logs from BETA only.
**Blocked by:** #2
EOF

mk "LogClient.sh (BETA Task 4)" "member-4,beta" "$M4" "2 Scripts built" <<'EOF'
- [ ] Check ALPHA:514 reachable, otherwise exit with a clear error
- [ ] Set hostname; install rsyslog; forward all messages to ALPHA:514; restart
- [ ] Event 1: sudo command on BETA
- [ ] Event 2: failed SSH login INTO BETA (from ALPHA)
- [ ] Event 3: manual logger message
- [ ] Verify all three in /var/log/remote/ on ALPHA
- [ ] Test the "unreachable" error path once

**Deliverable:** scripts/beta/LogClient.sh, screenshots from both VMs.
**Blocked by:** #16
EOF

mk "Remote.sh (BETA Task 2)" "member-4,beta" "$M4" "2 Scripts built" <<'EOF'
- [ ] ssh-keygen on BETA; ssh-copy-id to user1@alpha
- [ ] SSH and SFTP both work with no password prompt
- [ ] Run a remote command over SSH
- [ ] Fetch index.html from the ALPHA web server and save it
- [ ] SFTP upload of the sysinfo report (batch mode)
- [ ] Confirm the file arrived on ALPHA

**Deliverable:** scripts/beta/Remote.sh, saved index.html, screenshots.
**Blocked by:** #3 #4 #11
EOF

# ================= ALL =================
mk "Demo rehearsal: explain every line" "demo" "" "5 Demo rehearsal" <<'EOF'
- [ ] Each member explains one other member's script line by line
- [ ] Each member can re-run any task live from a clean VM snapshot
- [ ] Cron fields, UFW order, rsyslog template, fork/wait explained without notes
- [ ] VMs snapshotted in a working state

**Blocked by:** #6
EOF

echo "Done. Open the repo on GitHub and create the Project board (Projects tab -> Board layout)."
