#!/bin/bash
# =====================================================================
# Remote.sh  -  CMPS 405 Project, Task [09] (Member 4)
# Purpose : From BETA, set up password-less SSH/SFTP to user1@alpha,
#           run a remote command, download ALPHA's index.html, and
#           upload the sysinfo report to ALPHA with SFTP (batch mode).
# Run on  : BETA (192.168.134.11) as a NORMAL user (NOT sudo):
#              ./Remote.sh
#           Optionally pass the path of the sysinfo report:
#              ./Remote.sh ~/sysinfo_report.txt
# Needs   : ALPHA has user1, an SSH server, and a web server on port 80
#           (tasks [03], [04], [07]). The only password prompt is the
#           one-time ssh-copy-id in step 2 (user1's password on ALPHA).
# Output  : printed to screen and appended to ~/remote_log.txt
# =====================================================================
# ---------- Settings ---------
REMOTE_USER="user1"
REMOTE_HOST="alpha"                       # resolved through /etc/hosts
TARGET="$REMOTE_USER@$REMOTE_HOST"
KEY="$HOME/.ssh/id_ed25519"               # SSH key used for login
WORK_DIR="$HOME/remote_task"              # where downloads are saved
REPORT="${1:-$(ls -t "$HOME"/SysInfo_beta_*.txt | head -n 1)}"
REPORT="${REPORT:-$HOME/sysinfo_report.txt}"
RUN_LOG="$HOME/remote_log.txt"
# Options for every non-interactive ssh/sftp call:
# BatchMode=yes -> never ask for a password (fails instead), which
#                  proves the key login really works.
SSH_OPTS=(-i "$KEY" -o BatchMode=yes -o ConnectTimeout=5)
# ---------- Must NOT be root (keys must belong to the normal user) ---------
if [ "$EUID" -eq 0 ]; then
    echo "ERROR: run as a normal user, without sudo: ./Remote.sh"
    exit 1
fi
# ---------- Send all output to screen AND run log ---------
exec > >(tee -a "$RUN_LOG") 2>&1
echo "=================================================="
echo " Remote.sh started: $(date)  on $(hostname) as $USER"
echo "=================================================="
step() {
    echo
    echo "---------- [$1] $2 ----------"
}
mkdir -p "$WORK_DIR"
# --------------------------------------------------------------------
step 1 "Generate SSH key on BETA (only if it does not exist yet)"
# --------------------------------------------------------------------
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
if [ -f "$KEY" ]; then
    echo "Key already exists: $KEY (keeping it)"
else
    # -N "" = empty passphrase so logins need no typing at all
    ssh-keygen -t ed25519 -N "" -f "$KEY" -C "$USER@$(hostname)"
fi
ls -l "$KEY" "$KEY.pub"
# --------------------------------------------------------------------
step 2 "Copy public key to $TARGET (ssh-copy-id)"
# --------------------------------------------------------------------
# If key login already works, skip; otherwise ssh-copy-id asks for
# user1's password ONE time and installs the key on ALPHA.
if ssh "${SSH_OPTS[@]}" "$TARGET" true 2>/dev/null; then
    echo "Key already installed on $REMOTE_HOST - skipping ssh-copy-id"
else
    ssh-copy-id -i "$KEY.pub" -o StrictHostKeyChecking=accept-new "$TARGET" || {
        echo "ERROR: ssh-copy-id failed. Is SSH running on ALPHA and does $REMOTE_USER exist?"
        exit 1
    }
fi
# --------------------------------------------------------------------
step 3 "Check SSH and SFTP work with NO password prompt"
# --------------------------------------------------------------------
if ssh "${SSH_OPTS[@]}" "$TARGET" 'echo "SSH OK: logged in to $(hostname) as $(whoami)"'; then
    :
else
    echo "ERROR: SSH still asks for a password / cannot connect."
    exit 1
fi
# sftp -b - reads commands from stdin; batch mode never prompts.
if echo "pwd" | sftp "${SSH_OPTS[@]}" -b - "$TARGET"; then
    echo "SFTP OK: no password needed"
else
    echo "ERROR: SFTP login failed."
    exit 1
fi
# --------------------------------------------------------------------
step 4 "Run a remote command over SSH"
# --------------------------------------------------------------------
ssh "${SSH_OPTS[@]}" "$TARGET" 'echo "Host: $(hostname)"; echo "Uptime: $(uptime -p)"; echo "Disk:"; df -h /'
# --------------------------------------------------------------------
step 5 "Fetch index.html from the ALPHA web server and save it"
# --------------------------------------------------------------------
if curl -fsS "http://$REMOTE_HOST/index.html" -o "$WORK_DIR/index.html" 2>/dev/null ||
   wget -q "http://$REMOTE_HOST/index.html" -O "$WORK_DIR/index.html"; then
    echo "Saved: $WORK_DIR/index.html ($(wc -c < "$WORK_DIR/index.html") bytes)"
    echo "First lines:"
    head -n 10 "$WORK_DIR/index.html"
else
    echo "ERROR: could not download http://$REMOTE_HOST/index.html (is the web server up and port 80 open?)"
fi
# --------------------------------------------------------------------
step 6 "Upload sysinfo report to ALPHA with SFTP (batch mode)"
# --------------------------------------------------------------------
# If the report from the earlier sysinfo task is missing, create a
# small one so the upload can still be shown.
if [ ! -f "$REPORT" ]; then
    echo "Report $REPORT not found - generating a basic one"
    {
        echo "System info report - $(hostname) - $(date)"
        echo "Kernel : $(uname -r)"
        echo "Uptime : $(uptime -p)"
        echo "IP     : $(hostname -I)"
        echo; free -h; echo; df -h /
    } > "$REPORT"
fi
REPORT_NAME=$(basename "$REPORT")
# Batch file with the SFTP commands to run
BATCH="$WORK_DIR/sftp_batch.txt"
cat > "$BATCH" <<EOF
put $REPORT
ls -l $REPORT_NAME
EOF
echo "SFTP batch commands:"
cat "$BATCH"
if sftp "${SSH_OPTS[@]}" -b "$BATCH" "$TARGET"; then
    echo "SFTP upload finished"
else
    echo "ERROR: SFTP upload failed"
    exit 1
fi
# Confirm on ALPHA itself that the file arrived
echo "Checking on $REMOTE_HOST:"
if ssh "${SSH_OPTS[@]}" "$TARGET" "ls -l ~/$REPORT_NAME"; then
    echo "OK: $REPORT_NAME arrived in $REMOTE_USER's home on $REMOTE_HOST"
else
    echo "ERROR: $REPORT_NAME not found on $REMOTE_HOST"
fi
echo
echo "=================================================="
echo " Remote.sh finished: $(date)"
echo " index.html : $WORK_DIR/index.html"
echo " Run log    : $RUN_LOG"
echo "=================================================="