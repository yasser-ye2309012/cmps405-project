#!/bin/bash
# =============================================================
# Script Name: Search.sh
# Target Environment: ALPHA VM
# Project Phase: Task 3 - File Search and Administrator Notification
# Purpose: Finds files in the user's home account larger than 1MB.
#          Saves details into "bigfile" along with a timestamp and file count.
#          E-mails the report to the administrator using msmtp if files exist.
# Prerequisites: msmtp client must be installed and configured in ~/.msmtprc
# Usage: ./Search.sh
# =============================================================

# --- Section: Variables Definition ---------------------------------------------

# ADMIN: Stores the administrator's destination email address (the project mail account)
ADMIN="ma.cmpsdemo@gmail.com"                 

# BIGFILE: The filename required by the task constraints to store the final report
BIGFILE="bigfile"                           

# TMP: A temporary file to hold the raw search results before formatting them
TMP="bigfile.tmp"                           

# MAIL: A temporary file used to construct the full email structure (headers + body)
MAIL="mail.tmp"                             

# SEARCH_DATE: Captures the precise current timestamp using the format (YYYY-MM-DD HH:MM:SS)
SEARCH_DATE=$(date '+%Y-%m-%d %H:%M:%S')    


# --- Section 1: Find Files Larger Than 1M in Home Directory ------------------

# Break down of the 'find' command parameters:
# find "$HOME"       -> Initiates the search starting from the current user's home directory.
# -type f            -> Restricts the search strictly to files (ignores folders/directories).
# -size +1M          -> Filters the results to include ONLY files strictly larger than 1 Megabyte.
# -exec ls -lh {} \; -> For every matching file, executes 'ls -lh' to fetch details (human-readable size, owner, date, name).
# 2>/dev/null        -> Redirects Standard Error (stderr) to the null device. This hides "Permission Denied" errors cleanly.
# > "$TMP"           -> Overwrites and saves the successful search results inside our temporary file.
find "$HOME" -type f -size +1M -exec ls -lh {} \; 2>/dev/null > "$TMP"


# --- Section 2: Count the Files Found ------------------------------------------

# wc -l: Counts the number of lines inside the temporary file.
# Since 'find' prints exactly one line per file, the total line count equals the total file count.
# The result is captured and stored inside the 'COUNT' variable.
COUNT=$(wc -l < "$TMP")


# --- Section 3: Format and Write the Report File (bigfile) --------------------

# If Statement: Checks if the counted files variable (COUNT) is Greater Than (-gt) zero.
if [ "$COUNT" -gt 0 ]; then
    
    # '>' operator creates or overwrites bigfile, inserting the timestamp as the very first line.
    echo "Search date: $SEARCH_DATE" > "$BIGFILE"
    
    # '>>' operator appends the total file count into the second line without erasing the previous text.
    echo "Number of files larger than 1M: $COUNT" >> "$BIGFILE"
    
    # Appends an empty line to act as a clean visual spacer between metadata and the list.
    echo "" >> "$BIGFILE"
    
    # Reads the raw list from the temporary file and appends it directly underneath.
    cat "$TMP" >> "$BIGFILE"

else
    # Else: If no files are found (COUNT is 0), the '>' operator truncates bigfile, leaving it completely empty.
    > "$BIGFILE"                            
fi

# Clean up: Permanently deletes the temporary file from the disk since data is now copied.
rm -f "$TMP"                                

# Console feedback: Prints the summary straight to the terminal screen for the operator to see immediately.
echo "Search date : $SEARCH_DATE"
echo "Files found : $COUNT"


# --- Section 4: Email the Administrator (If Report is Not Empty) ------------

# '-s' Operator: Checks if the report file exists and has a file size greater than zero (i.e., not empty).
if [ -s "$BIGFILE" ]; then
    
    # Safety Check: 'which' verifies if the msmtp binary is available in the system execution path.
    if ! which msmtp > /dev/null; then
        # If msmtp is missing, prints a helpful error message and stops execution with an error status (exit 1).
        echo "ERROR: msmtp is not installed (sudo apt install msmtp)"
        exit 1
    fi

    # Building the formal RFC-compliant email structure inside the 'MAIL' temporary file:
    # Inserts the recipient destination header
    echo "To: $ADMIN" > "$MAIL"
    # Inserts the sender source header
    echo "From: $ADMIN" >> "$MAIL"
    # Inserts the email subject line, dynamically fetching the server's identity using $(hostname)
    echo "Subject: Big files report from $(hostname)" >> "$MAIL"
    # CRITICAL STEP: Appends a completely empty line. Mail protocols strictly require this blank line to separate headers from the message body.
    echo "" >> "$MAIL"
    # Injects the entire contents of the bigfile report into the body section of the email.
    cat "$BIGFILE" >> "$MAIL"

    # Execution Step: Feeds the formatted mail file into the msmtp application to process and send it out.
    msmtp "$ADMIN" < "$MAIL"
    
    # Smart Status Check: '$?' captures the return exit status code of the immediate previous command (msmtp).
    # An exit status of 0 (-eq 0) means the command succeeded flawlessly with no network errors.
    if [ $? -eq 0 ]; then
        echo "E-mail sent to $ADMIN"
    else
        # Any code other than 0 indicates a failure (e.g., wrong SMTP configuration or lack of internet connectivity).
        echo "ERROR: the e-mail could not be sent (check ~/.msmtprc)"
        # Secure deletion of the temporary mail file to avoid stale data leftovers on failure.
        rm -f "$MAIL"
        exit 1
    fi
    # Deletes the temporary mail draft file after a successful transmission to keep the directory clean.
    rm -f "$MAIL"
else
    # Else block: Executed if bigfile is completely empty, noting that no notifications are needed.
    echo "bigfile is empty: no e-mail sent."
fi

# Exit 0: Terminates the script successfully, signaling to the OS that everything ran without errors.
exit 0
