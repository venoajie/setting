```bash
#!/bin/bash

# ==============================================================================
# OCI INSTANCE SECURITY BASELINE SCRIPT
# Version: 1.0
#
# This script configures the OCI Security List and host firewalld for a new
# instance. It logs all actions and verification steps to a timestamped file.
# ==============================================================================

# --- Configuration ---
# IMPORTANT: EDIT THIS VARIABLE WITH YOUR ACTUAL IP ADDRESS
MY_HOME_IP="203.0.113.55" 

# --- Log File Setup ---
LOG_FILE="security_setup_$(date +%Y-%m-%d_%H-%M-%S).log"
touch $LOG_FILE
echo "OCI Security Baseline Setup Log - $(date)" | tee -a $LOG_FILE
echo "=================================================" | tee -a $LOG_FILE

# --- Function to log commands and their output ---
log_exec() {
    echo "" | tee -a $LOG_FILE
    echo "COMMAND: $@" | tee -a $LOG_FILE
    echo "--------------------------" | tee -a $LOG_FILE
    # Execute command, redirecting stderr to stdout, and append to log
    "$@" 2>&1 | tee -a $LOG_FILE
    echo "--------------------------" | tee -a $LOG_FILE
}

# --- Phase 1: OCI Cloud Firewall ---
echo "" | tee -a $LOG_FILE
echo "### PHASE 1: CONFIGURING OCI SECURITY LIST ###" | tee -a $LOG_FILE

log_exec echo "Step 1.1: Gathering Network Identifiers..."
INSTANCE_OCID=$(curl -s -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/id)
VNIC_OCID=$(oci compute instance list-vnics --instance-id $INSTANCE_OCID --query "data[0].id" --raw-output)
SUBNET_OCID=$(oci network vnic get --vnic-id $VNIC_OCID --query "data.\"subnet-id\"" --raw-output)
SECLIST_OCID=$(oci network subnet get --subnet-id $SUBNET_OCID --query "data.\"security-list-ids\"[0]" --raw-output)

echo "Discovered Security List OCID: $SECLIST_OCID" | tee -a $LOG_FILE

log_exec echo "Step 1.2: Creating new ruleset file (new_ruleset.json)..."
cat << EOF > ./new_ruleset.json
[
  {
    "direction": "INGRESS",
    "protocol": "6",
    "source": "${MY_HOME_IP}/32",
    "tcpOptions": { "destinationPortRange": { "max": 22, "min": 22 }},
    "description": "Allow SSH from my home IP"
  },
  {
    "direction": "INGRESS",
    "protocol": "6",
    "source": "${MY_HOME_IP}/32",
    "tcpOptions": { "destinationPortRange": { "max": 5432, "min": 5432 }},
    "description": "Allow Postgres from my home IP"
  }
]
EOF

echo "--- Contents of new_ruleset.json ---" | tee -a $LOG_FILE
cat ./new_ruleset.json | tee -a $LOG_FILE
echo "------------------------------------" | tee -a $LOG_FILE

log_exec echo "Step 1.3: Applying the new ruleset to OCI..."
log_exec oci network security-list update --security-list-id $SECLIST_OCID --ingress-security-rules file://./new_ruleset.json --force

# --- Phase 2: Host Firewall ---
echo "" | tee -a $LOG_FILE
echo "### PHASE 2: CONFIGURING HOST FIREWALL (firewalld) ###" | tee -a $LOG_FILE

log_exec echo "Step 2.1: Adding rich rules..."
log_exec sudo firewall-cmd --zone=public --add-rich-rule="rule family=\"ipv4\" source address=\"${MY_HOME_IP}\" port protocol=\"tcp\" port=\"22\" accept"
log_exec sudo firewall-cmd --zone=public --add-rich-rule="rule family=\"ipv4\" source address=\"${MY_HOME_IP}\" port protocol=\"tcp\" port=\"5432\" accept"

log_exec echo "Step 2.2: Making rules permanent..."
log_exec sudo firewall-cmd --runtime-to-permanent

# --- Phase 3: Verification ---
echo "" | tee -a $LOG_FILE
echo "### PHASE 3: VERIFICATION ###" | tee -a $LOG_FILE

log_exec echo "Step 3.1: Verifying OCI Security List rules..."
log_exec oci network security-list get --security-list-id $SECLIST_OCID --query "data.\"ingress-security-rules\""

log_exec echo "Step 3.2: Verifying host firewalld rules..."
log_exec sudo firewall-cmd --list-all

echo "" | tee -a $LOG_FILE
echo "=================================================" | tee -a $LOG_FILE
echo "Security baseline script finished. Please review the log file: ${LOG_FILE}" | tee -a $LOG_FILE
```

### How to Use This Script

1.  **Save the Code:** Save the script above as `secure_instance.sh` in your home directory on the OCI server.
2.  **Configure:** Open the file and **change the `MY_HOME_IP` variable** at the top to your actual local IP address.
3.  **Make it Executable:** `chmod +x secure_instance.sh`
4.  **Run it:** `sudo ./secure_instance.sh` (You need `sudo` because `firewall-cmd` requires it).

### Where the Values are Stored and Shown

After running, you will have a new file in your directory, for example: `security_setup_2024-10-20_14-30-00.log`.

This log file is your **permanent record**. It will contain:

*   The exact time the script was run.
*   The **Security List OCID** that was discovered and modified.
*   The **exact JSON content** of the firewall rules that were applied.
*   The success/failure output from the `oci ... update` command.
*   The success/failure output from each `firewall-cmd` command.
*   A final **verification block** showing the complete list of rules as seen by OCI and `firewalld` at the end of the process.

### Where to Store This Log File

For a single server, keeping this log file in the `/home/opc/` directory is fine.

For professional projects, the best practice is to **commit this log file to a private Git repository** for your project's infrastructure. This provides:
*   **Version Control:** You can see exactly how the configuration has changed over time.
*   **Centralization:** Anyone on your team can see the setup log for any server.
*   **Backup:** The configuration record is not lost if the server is terminated.

By adopting this script-and-log approach, you have elevated your process from a manual task to a documented, verifiable, and professional security procedure.
