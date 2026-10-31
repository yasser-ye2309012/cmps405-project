#!/bin/bash
# =====================================================================
# LogServer.sh  -  CMPS 405 Project, Task [06] (Member 4)
# Purpose : Configure ALPHA as the central syslog server that collects
#           logs from BETA over UDP/TCP port 514.
# Run on  : ALPHA (192.168.153.10)   as root:  sudo ./LogServer.sh [BETA_IP]
# Output  : everything printed is also appended to
#           /var/log/logserver_setup.log
# Safe to run more than once (idempotent): config files are rewritten
# with the same content and ufw skips rules that already exist.
# =====================================================================
# ---------- Settings ---------
BETA_IP="${1:-192.168.153.11}"                 # only this client may send logs
LOG_PORT=514                                   # standard syslog port
REMOTE_DIR="/var/log/remote"                   # where remote logs are stored
RSYSLOG_CONF="/etc/rsyslog.d/10-remote.conf"   # our rsyslog config file
ROTATE_CONF="/etc/logrotate.d/remote"          # our logrotate config file
SETUP_LOG="/var/log/logserver_setup.log"       # this script's own log
# ---------- Must run as root ---------
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: run this script with sudo: sudo $0"
    exit 1
fi
# ---------- Send all output (stdout + stderr) to screen AND setup log ---------
exec > >(tee -a "$SETUP_LOG") 2>&1
echo "=================================================="
echo " LogServer setup started: $(date)"
echo " Host: $(hostname)"
echo "=================================================="
# Small helper to print a numbered step header
step() {
    echo
    echo "---------- [$1] $2 ----------"
}
# --------------------------------------------------------------------
step 1 "Install rsyslog, ufw and logrotate"
# --------------------------------------------------------------------
# apt-get install does nothing if a package is already installed.
apt-get update -qq
apt-get install -y rsyslog ufw logrotate
systemctl enable rsyslog
# --------------------------------------------------------------------
step 2 "Create directory for remote logs: $REMOTE_DIR"
# --------------------------------------------------------------------
# rsyslog runs as user 'syslog' on Ubuntu, so it must own this folder.
mkdir -p "$REMOTE_DIR"
chown syslog:adm "$REMOTE_DIR"
chmod 0755 "$REMOTE_DIR"
ls -ld "$REMOTE_DIR"
# --------------------------------------------------------------------
step 3 "Configure rsyslog to listen on UDP and TCP port $LOG_PORT"
# --------------------------------------------------------------------
# If the main rsyslog.conf already loads imudp/imtcp, loading them again
# in our file is an error, so comment those lines out (no-op if already done).
sed -i -E 's/^(module\(load="im(udp|tcp)"\))/#\1/;
           s/^(input\(type="im(udp|tcp)".*)/#\1/' /etc/rsyslog.conf
# Write our config. Messages arriving on port 514 go to the "remote"
# ruleset, which saves them as /var/log/remote/<hostname>/<hostname>.log
# and stops, so they do not also fill ALPHA's own /var/log/syslog.
cat > "$RSYSLOG_CONF" <<EOF
# Managed by LogServer.sh - central log server (task)
module(load="imudp")
module(load="imtcp")
input(type="imudp" port="$LOG_PORT" ruleset="remote")
input(type="imtcp" port="$LOG_PORT" ruleset="remote")
# One folder and one file per sending host
template(name="RemotePerHost" type="string"
         string="$REMOTE_DIR/%HOSTNAME%/%HOSTNAME%.log")
ruleset(name="remote") {
    action(type="omfile" dynaFile="RemotePerHost"
           createDirs="on" dirCreateMode="0755"
           fileCreateMode="0640" fileOwner="syslog" fileGroup="adm")
    stop
}
EOF
echo "Wrote $RSYSLOG_CONF:"
cat "$RSYSLOG_CONF"
# Check the configuration before restarting; stop if it is invalid.
echo "Validating rsyslog configuration..."
if ! rsyslogd -N1; then
    echo "ERROR: rsyslog configuration is invalid. Fix it and re-run."
    exit 1
fi
systemctl restart rsyslog
systemctl is-active rsyslog
# --------------------------------------------------------------------
step 4 "Configure UFW firewall"
# --------------------------------------------------------------------
# Order matters: allow SSH FIRST so enabling the firewall never locks us out.
ufw allow 22/tcp comment 'SSH'
# Syslog only from BETA (UDP and TCP)
ufw allow from "$BETA_IP" to any port "$LOG_PORT" proto udp comment 'syslog UDP from BETA'
ufw allow from "$BETA_IP" to any port "$LOG_PORT" proto tcp comment 'syslog TCP from BETA'
# Allow loopback traffic to port 514 so that Step 6 network tests via 127.0.0.1 
# do not get blocked by UFW, preventing false-positive WARNING logs.
ufw allow from 127.0.0.1 to any port "$LOG_PORT" comment 'Local loopback test traffic'
# Web traffic: ALPHA's web server must stay reachable once the firewall
# is on, because [09] Remote.sh on BETA downloads index.html from it.
ufw allow 80/tcp comment 'HTTP'
# --force skips the interactive y/n prompt
ufw --force enable
ufw status verbose
# --------------------------------------------------------------------
step 5 "Verify rsyslog is listening on port $LOG_PORT"
# --------------------------------------------------------------------
sleep 1
if ss -tulnp | grep ":$LOG_PORT "; then
    echo "OK: rsyslog is listening on port $LOG_PORT"
else
    echo "WARNING: nothing is listening on port $LOG_PORT"
fi
# --------------------------------------------------------------------
step 6 "Test with logger (send to ourselves over the network)"
# --------------------------------------------------------------------
# -n 127.0.0.1 sends through port 514 so the message goes through the same
# path a message from BETA would; -d = UDP, -T = TCP.
TAG="LogServerTest-$(date +%s)"
logger -n 127.0.0.1 -P "$LOG_PORT" -d "$TAG UDP test message from $(hostname)"
logger -n 127.0.0.1 -P "$LOG_PORT" -T "$TAG TCP test message from $(hostname)"
sleep 2
TEST_FILE="$REMOTE_DIR/$(hostname)/$(hostname).log"
if grep -q "$TAG" "$TEST_FILE" 2>/dev/null; then
    echo "OK: test messages written to $TEST_FILE"
    grep "$TAG" "$TEST_FILE"
else
    echo "WARNING: test messages not found in $TEST_FILE"
fi
echo "Current contents of $REMOTE_DIR:"
ls -lR "$REMOTE_DIR"
# --------------------------------------------------------------------
step 7 "Configure log rotation: $ROTATE_CONF"
# --------------------------------------------------------------------
# Rotate each host's log daily, keep 7 compressed copies, then tell
# rsyslog to reopen its files (rsyslog-rotate sends it a HUP signal).
cat > "$ROTATE_CONF" <<EOF
# Managed by LogServer.sh - rotation for remote host logs
$REMOTE_DIR/*/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    su syslog adm
    create 0640 syslog adm
    sharedscripts
    # Postrotate block must reside INSIDE the closing brace of the directive block
    # otherwise logrotate throws a syntax error and fails to reload rsyslog.
    postrotate
        /usr/lib/rsyslog/rsyslog-rotate 2>/dev/null || systemctl kill -s HUP rsyslog.service
    endscript
}
EOF
echo "Wrote $ROTATE_CONF:"
cat "$ROTATE_CONF"
# -d = debug / dry run: checks the file without rotating anything
echo "Checking logrotate configuration (dry run)..."
logrotate -d "$ROTATE_CONF" 2>&1 | tail -n 15
# --------------------------------------------------------------------
step 8 "Final status"
# --------------------------------------------------------------------
echo "rsyslog service : $(systemctl is-active rsyslog)"
echo "rsyslog on boot : $(systemctl is-enabled rsyslog)"
echo "Port $LOG_PORT       : $(ss -tuln | grep -c ":$LOG_PORT ") socket(s) listening (expect 4: UDP+TCP, IPv4+IPv6)"
echo "Firewall        : $(ufw status | head -n 1)"
echo "Allowed to $LOG_PORT  : $BETA_IP only"
echo "Remote logs     : $REMOTE_DIR/<hostname>/<hostname>.log"
echo "Log rotation    : daily, 7 kept ($ROTATE_CONF)"
echo "Setup log       : $SETUP_LOG"
echo
echo "=================================================="
echo " LogServer setup finished: $(date)"
echo "=================================================="
