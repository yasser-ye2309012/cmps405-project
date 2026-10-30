#!/bin/bash
# =====================================================================
# LogClient.sh  -  CMPS 405 Project, Task [08] (Member 4)
# Purpose : Configure BETA to forward all of its syslog messages to the
#           central log server on ALPHA (set up by [06] LogServer.sh).
# Run on  : BETA (192.168.153.11)  as root:  sudo ./LogClient.sh
# Output  : printed to screen and appended to /var/log/logclient_setup.log
# Safe to run more than once (config file is rewritten each time).
# =====================================================================
# ---------- Settings ---------
SERVER_IP="192.168.153.10"                      # ALPHA
LOG_PORT=514
FWD_CONF="/etc/rsyslog.d/90-forward-to-alpha.conf"
SETUP_LOG="/var/log/logclient_setup.log"
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: run this script with sudo: sudo $0"
    exit 1
fi
exec > >(tee -a "$SETUP_LOG") 2>&1
echo "=================================================="
echo " LogClient setup started: $(date)  on $(hostname)"
echo "=================================================="
step() {
    echo
    echo "---------- [$1] $2 ----------"
}
# --------------------------------------------------------------------
step 0a "Check ALPHA is reachable on TCP $LOG_PORT (must pass before anything else)"
# --------------------------------------------------------------------
# Same /dev/tcp test as step 3, but here a failure stops the script.
if timeout 3 bash -c "echo > /dev/tcp/$SERVER_IP/$LOG_PORT" 2>/dev/null; then
    echo "OK: $SERVER_IP:$LOG_PORT is reachable"
else
    echo "ERROR: cannot reach ALPHA at $SERVER_IP:$LOG_PORT."
    echo "       Make sure LogServer.sh was run on ALPHA and that rsyslog and the firewall allow port $LOG_PORT from BETA."
    exit 1
fi
# --------------------------------------------------------------------
step 0b "Set a clear hostname for BETA"
# --------------------------------------------------------------------
# The hostname appears in every forwarded message and names the folder
# /var/log/remote/<hostname>/ on ALPHA.
hostnamectl set-hostname beta
# Keep /etc/hosts in sync so sudo does not complain about the new name.
if grep -q '^127\.0\.1\.1' /etc/hosts; then
    sed -i 's/^127\.0\.1\.1.*/127.0.1.1 beta/' /etc/hosts
else
    echo "127.0.1.1 beta" >> /etc/hosts
fi
echo "Hostname is now: $(hostname)"
# --------------------------------------------------------------------
step 1 "Install and enable rsyslog"
# --------------------------------------------------------------------
apt-get update -qq
apt-get install -y rsyslog
systemctl enable rsyslog
# --------------------------------------------------------------------
step 2 "Forward all logs to ALPHA ($SERVER_IP:$LOG_PORT over TCP)"
# --------------------------------------------------------------------
# TCP is used so messages are not silently lost. The disk-assisted queue
# keeps messages while ALPHA is down and sends them when it comes back.
# Logs are still written locally on BETA as normal.
cat > "$FWD_CONF" <<EOF
# Managed by LogClient.sh - forward everything to ALPHA (task)

# Ensure the working directory for disk-assisted queues exists and is explicitly defined
global(workDirectory="/var/spool/rsyslog")

*.* action(type="omfwd" target="$SERVER_IP" port="$LOG_PORT" protocol="tcp"
           queue.type="LinkedList" queue.filename="fwd_alpha"
           queue.maxDiskSpace="100m" queue.saveOnShutdown="on"
           action.resumeRetryCount="-1")
EOF
echo "Wrote $FWD_CONF:"
cat "$FWD_CONF"
echo "Validating rsyslog configuration..."
if ! rsyslogd -N1; then
    echo "ERROR: rsyslog configuration is invalid."
    exit 1
fi
systemctl restart rsyslog
echo "rsyslog: $(systemctl is-active rsyslog)"
# --------------------------------------------------------------------
step 3 "Check ALPHA is reachable on TCP $LOG_PORT"
# --------------------------------------------------------------------
# bash's /dev/tcp opens a TCP connection; success means port is open.
if timeout 3 bash -c "echo > /dev/tcp/$SERVER_IP/$LOG_PORT" 2>/dev/null; then
    echo "OK: $SERVER_IP:$LOG_PORT is reachable"
else
    echo "WARNING: cannot reach $SERVER_IP:$LOG_PORT (is LogServer.sh done on ALPHA?)"
fi
# --------------------------------------------------------------------
step 4 "Send a test message"
# --------------------------------------------------------------------
TAG="LogClientTest-$(date +%s)"
logger -t logclient "$TAG test message from $(hostname)"
echo "Sent: '$TAG test message from $(hostname)'"
echo "Verify on ALPHA with:"
echo "  sudo grep $TAG /var/log/remote/$(hostname)/$(hostname).log"
# --------------------------------------------------------------------
step 5 "Generate the remaining test events on BETA"
# --------------------------------------------------------------------
# The failed SSH login must be made INTO BETA, so BETA needs an SSH server.
apt-get install -y openssh-server
systemctl enable --now ssh
# Event 1: a sudo command on BETA (sudo writes it to the auth log, which is forwarded).
sudo echo "sudo-event-$TAG" > /dev/null
echo "Event 1 (sudo) sent: sudo echo sudo-event-$TAG"
echo "Event 3 (logger) already sent in step 4: $TAG"
# Event 2 has to be done by hand from ALPHA.
BETA_IP=$(hostname -I | awk '{print $1}')
echo
echo "Event 2 (failed SSH login INTO BETA) - run this on ALPHA with a wrong user/password:"
echo "  ssh wronguser@$BETA_IP"
echo
echo "Then verify all three events on ALPHA with:"
echo "  sudo grep -E \"$TAG|sshd\" /var/log/remote/$(hostname)/$(hostname).log"
echo
echo "=================================================="
echo " LogClient setup finished: $(date)"
echo "=================================================="
