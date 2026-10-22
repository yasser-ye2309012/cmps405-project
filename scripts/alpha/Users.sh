#!/bin/bash
# =============================================================
# Users.sh - ALPHA VM, Task 1: User and Group Management
# Creates user1..user10 with passwords and home directories,
# gives each one sudo (root) privileges, then verifies the result.
# If a user already exists the script reports it instead of failing.
# Usage: sudo ./Users.sh
# =============================================================

# --- Settings -------------------------------------------------
PASSWORD="Lab@12345"     # lab-only password given to every user (change if you like)
TOTAL=10                 # how many users to create
created=0                # counter: users created in this run
skipped=0                # counter: users that already existed

# --- Must run as root (useradd/chpasswd/usermod need it) ------
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: run this script with sudo:  sudo ./Users.sh"
    exit 1
fi

echo "===== Creating $TOTAL users ====="

# --- Loop over user1 .. user10 --------------------------------
for i in $(seq 1 "$TOTAL"); do
    user="user$i"

    # 'id' succeeds only if the account exists; output is discarded
    if id "$user" &>/dev/null; then
        echo "[SKIP] $user already exists"
        skipped=$((skipped + 1))
        continue                      # go to the next user
    fi

    # -m creates the home directory, -s sets the login shell
    if useradd -m -s /bin/bash "$user"; then
        # chpasswd reads "name:password" lines from stdin
        echo "$user:$PASSWORD" | chpasswd
        # add the user to the sudo group = root privileges
        usermod -aG sudo "$user"
        echo "[OK]   $user created (home: /home/$user, group: sudo)"
        created=$((created + 1))
    else
        echo "[ERROR] could not create $user"
    fi
done

# --- Verification ---------------------------------------------
echo
echo "===== Verification: accounts and group memberships ====="
for i in $(seq 1 "$TOTAL"); do
    user="user$i"
    if id "$user" &>/dev/null; then
        getent passwd "$user"         # passwd entry (shows UID and home directory)
        groups "$user"                # groups the user belongs to (must include sudo)
        echo "---"
    else
        echo "[MISSING] $user does not exist"
    fi
done

# --- Summary --------------------------------------------------
echo
echo "Summary: $created created, $skipped already existed."
echo "Members of the sudo group:"
getent group sudo
