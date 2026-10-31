#!/bin/bash
# =============================================================
# Network.sh - ALPHA VM, Task 4: Network Configuration and Diagnostics
#
# What this script does:
#   0. checks that the network tools are installed (installs them if not)
#   1. shows the network configuration      (ifconfig)
#   2. shows the routing table              (route -n)
#   3. shows the host name                  (hostname)
#   4. tests the local DNS server           (resolv.conf + nslookup)
#   5. traces the route to google.com       (traceroute)
#   6. pings google.com                     (ping)
# Everything is shown on the screen AND saved in the file network.log
#
# Usage: ./Network.sh      (needs internet access and sudo rights)
# =============================================================

# --- Variable --------------------------------------------------
LOG="network.log"            # name of the log file required by the task

# --- Function 1: install a tool only if it is missing ----------
# It receives two arguments:
#   $1 = the command we need     (example: ifconfig)
#   $2 = the package that has it (example: net-tools)
check_tool () {
    # "command -v" looks for the command; > /dev/null hides its output,
    # we only care if it was found (exit status 0) or not
    if command -v "$1" > /dev/null; then
        echo "$1 is already installed"
    else
        echo "$1 is NOT installed, installing the package $2 ..."
        sudo apt-get update                # refresh the list of packages
        sudo apt-get install -y "$2"       # -y = answer "yes" automatically
    fi
}

# --- Function 2: do all the work (everything it prints is logged)-
run_all () {
    # Title with the date and time of this report
    echo "===== Network report - $(date) ====="

    # ---------- Step 0: make sure the tools exist ----------
    echo
    echo "===== 0. Checking the network tools ====="
    check_tool ifconfig  net-tools         # ifconfig comes from net-tools
    check_tool route     net-tools         # route also comes from net-tools
    check_tool nslookup  bind9-dnsutils    # nslookup comes from bind9-dnsutils
    check_tool traceroute traceroute       # traceroute has its own package

    # ---------- Step 1: network configuration ----------
    echo
    echo "===== 1. Network configuration (ifconfig) ====="
    ifconfig                               # network cards, IP addresses, masks

    # ---------- Step 2: routing table ----------
    echo
    echo "===== 2. Routing table (route -n) ====="
    route -n                               # -n = show numbers, not names

    # ---------- Step 3: host name ----------
    echo
    echo "===== 3. Host name ====="
    hostname                               # the name of this machine (alpha)

    # ---------- Step 4: test the local DNS server ----------
    echo
    echo "===== 4. Local DNS server ====="
    echo "--- DNS server used by this machine (/etc/resolv.conf) ---"
    cat /etc/resolv.conf                   # the "nameserver" lines
    echo "--- Asking the DNS server for google.com (nslookup) ---"
    nslookup google.com                    # if it prints an address, DNS works

    # ---------- Step 5: route to google.com ----------
    echo
    echo "===== 5. Route to google.com (traceroute) ====="
    # The task does not give any options. We add two limits ONLY so the trace
    # cannot run for minutes if some routers do not answer:
    #   -m 15 = maximum of 15 hops (the default is 30)
    #   -w 2  = wait at most 2 seconds for each answer (the default is 5)
    traceroute -m 15 -w 2 google.com

    # ---------- Step 6: ping google.com ----------
    echo
    echo "===== 6. Ping google.com (4 packets) ====="
    # Without -c, ping never stops by itself, so the script would hang and the
    # rest of the report would never be saved. -c 4 sends 4 packets then stops.
    # "if ping ..." tests the exit status of ping directly: 0 = success.
    if ping -c 4 google.com; then
        echo "RESULT: google.com is reachable"
    else
        echo "RESULT: google.com is NOT reachable"
    fi

    echo
    echo "===== End of the report ====="
}

# --- Run the work ----------------------------------------------
# 2>&1 sends error messages to the same place as normal output, so errors
# are also saved in the log. The "|" (pipe) sends everything to "tee".
# tee does two jobs: it shows the text on the screen AND saves it in $LOG.
run_all 2>&1 | tee "$LOG"

echo
echo "The report was saved in the file $LOG"
exit 0
