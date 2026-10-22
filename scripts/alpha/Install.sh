#!/bin/bash
# =============================================================
# Install.sh - ALPHA VM, Task 2: Service Installation and Error Logging
# Updates the system, installs MySQL, SSH, FTP (vsftpd) and Apache,
# enables MySQL/SSH/Apache at boot, shows the status of each service
# and saves every error to Installation.log.
# Usage: sudo ./Install.sh      (Installation.log is created in the
#        folder you run the script from)
# =============================================================

# --- Must run as root (apt and systemctl need it) --------------
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: run this script with sudo:  sudo ./Install.sh"
    exit 1
fi

LOG="Installation.log"                 # all errors are saved here
export DEBIAN_FRONTEND=noninteractive  # stop apt from asking questions
errors=0                               # counts failed steps

# Start a new section in the log file so each run is easy to tell apart
echo "===== Installation run started: $(date '+%F %T') =====" >> "$LOG"

# --- Helper: run a command, send its error output to the log ----
# $1 = short description, the rest = the command to run
run() {
    local desc="$1"; shift
    echo ">> $desc"
    "$@" 2>>"$LOG"                     # stdout stays on screen, stderr goes to the log
    local rc=$?                        # exit code of the command
    if [ $rc -ne 0 ]; then
        echo "   [ERROR] $desc failed (exit code $rc) - see $LOG"
        echo "$(date '+%F %T') ERROR: $desc failed (exit code $rc)" >> "$LOG"
        errors=$((errors + 1))
    else
        echo "   [OK]"
    fi
    return $rc
}

# Wait up to 60 s if Ubuntu's background updater holds the apt lock
APT="apt-get -y -qq -o DPkg::Lock::Timeout=60"

echo "===== 1. Updating the system ====="
run "Updating package lists"        $APT update
run "Upgrading installed packages"  $APT upgrade

echo "===== 2. MySQL ====="
run "Installing MySQL server"       $APT install mysql-server
run "Restarting MySQL"              systemctl restart mysql
echo "NOTE: the system will be reloaded now (systemd configuration reload)..."
run "Reloading systemd"             systemctl daemon-reload

echo "===== 3. SSH, FTP and Apache ====="
run "Installing SSH server"         $APT install openssh-server
run "Installing FTP server"         $APT install vsftpd
run "Installing Apache web server"  $APT install apache2

echo "===== 4. Start automatically on boot ====="
# Required: mysql, ssh, apache2. vsftpd is enabled too so FTP survives a reboot.
for svc in mysql ssh apache2 vsftpd; do
    run "Enabling $svc at boot"     systemctl enable "$svc"
done

echo "===== 5. Service status ====="
for svc in mysql ssh apache2 vsftpd; do
    echo "---- $svc: enabled=$(systemctl is-enabled "$svc" 2>/dev/null)  active=$(systemctl is-active "$svc" 2>/dev/null) ----"
    systemctl status "$svc" --no-pager --lines=0   # short status without the log lines
done

echo
echo "===== Finished with $errors failed step(s) ====="
echo "===== Last 20 lines of $LOG (full file: $LOG) ====="
tail -n 20 "$LOG"

# Exit code 1 if anything failed, 0 if everything worked
[ "$errors" -eq 0 ]
