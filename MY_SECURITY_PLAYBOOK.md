## My Personal Security Playbook

| **Document ID:** | SEC-PLAYBOOK-001 | **Version:** | 1.0 |
| :--- | :--- | :--- | :--- |
| **Purpose:** | To provide a systematic guide for securing my development environment, responding to incidents, and managing infrastructure safely. |

### Guiding Principle

Security is not a one-time action; it is a continuous process. This document transforms security from a source of anxiety into a manageable, systematic process. When in doubt, consult this playbook.

---

### Section 1: The Local Machine (Your Laptop)

**Principle:** Your laptop is your castle keep. It's where your keys (credentials) are stored. Its security is paramount.

**Threats:** Physical theft, malware/ransomware, phishing attacks that steal your credentials.

#### Checklist for a Secure Laptop:

*   **[ ] Full Disk Encryption is ON:** This is your most important defense against physical theft. If someone steals your laptop, they cannot access your data without your password.
    *   **Windows:** Search for "BitLocker" and ensure it is turned on for your main drive.
    *   **Mac:** Go to System Settings -> Privacy & Security -> "FileVault" and ensure it is on.

*   **[ ] I Use a Password Manager:** You must not reuse passwords. A password manager creates and stores unique, strong passwords for every website.
    *   **Action:** Install and use a reputable password manager.
    *   **Recommended:** Bitwarden (free, open-source), 1Password (paid, excellent user experience).
    *   **Your New Habit:** Every time you sign up for a new service, you use the password manager to generate and save the password.

*   **[ ] My Main SSH Key is Protected with a Passphrase:** Your SSH key is the key to your servers. A passphrase encrypts the key file itself.
    *   **Why?** If a hacker steals your `ssh-key-2024-10-19.key` file, they *still* cannot use it without knowing the passphrase you set.
    *   **How to check/add:** You can change or add a passphrase to an existing key by running `ssh-keygen -p -f ~/.ssh/your_key_file` in your terminal.

*   **[ ] System Updates are Installed Regularly:** Your operating system (Windows/macOS) and web browser will prompt you to install security updates. Do not ignore them.
    *   **Action:** When you see an update notification, install it.

*   **[ ] My Laptop's Firewall is ON:** Both Windows and macOS have built-in firewalls that are on by default. Just verify they haven't been turned off.

---

### Section 2: The Code Repository (GitHub)

**Principle:** Your code is your intellectual property, but more importantly, it can be a source of leaked secrets.

**Threats:** Leaking API keys or passwords, unauthorized access to your code.

#### Checklist for Secure GitHub Usage:

*   **[ ] I NEVER Commit Secrets to Git:** This is the #1 rule. Never, ever save passwords, API keys, or secret files in your code.
    *   **Action:** Use a `.env` file to store secrets locally, and add `.env` to your `.gitignore` file.
    *   **Example `.gitignore` entry:**
        ```
        # Ignore environment files
        .env
        
        # Ignore secrets directories
        secrets/
        ```

*   **[ ] Two-Factor Authentication (2FA) is ENABLED on my GitHub Account:** This is mandatory. It means that even if someone steals your password, they cannot log in without a second code from your phone.
    *   **Action:** Go to your GitHub Settings -> Password and authentication -> Enable two-factor authentication. Use an app like Google Authenticator or Authy.

*   **[ ] My Repositories are PRIVATE:** Unless you are intentionally creating an open-source project, your repositories should be private by default.

---

### Section 3: The Cloud Infrastructure (OCI)

**Principle:** Your cloud instances are your fortresses on the internet. They must have strong walls and guarded gates.

**Threats:** Unauthorized access, data breaches, resource hijacking (e.g., for crypto mining).

#### Checklist for Secure OCI Instances:

*   **[ ] I Have a Firewall SOP:** You have already created this! It is your `SECURITY_SOP.md` document.
    *   **Action:** When creating a **new instance**, follow the `SECURITY_SOP.md` procedure exactly.
    *   **Action:** When you need to **open a new port**, follow the "Procedure for Modifying Existing Rules" in the SOP to avoid locking yourself out.

*   **[ ] I ONLY Use SSH Keys for Access:** Password authentication for cloud servers is insecure and should be disabled. OCI instances do this by default, which is good.
    *   **Action:** Always use `ssh -i <your_key_file> ...`. Never configure password login.

*   **[ ] I Have a Non-Admin User for Daily Tasks (Best Practice):**
    *   **Why?** The `opc` user has `sudo` (administrator) privileges. For enhanced security, you can create a separate user with fewer permissions for running your applications. (This is an advanced topic, but good to be aware of).

*   **[ ] I Have a Backup Plan:** Security also means being able to recover from disaster (like accidental data deletion or ransomware).
    *   **Action:** In the OCI console, navigate to Block Storage -> Block Volumes. Find the boot volumes for your instances and set up a scheduled backup policy (e.g., once a week).

*   **[ ] I Have a Budget Alert:** A common attack is for hackers to use your server to mine cryptocurrency, running up a huge bill. A budget alert is your early warning system.
    *   **Action:** In the OCI console, go to Billing & Cost Management -> Budgets. Create a budget for a small amount (e.g., $10/month) and set an alert to email you when you reach 80% of it. If you get that email unexpectedly, it's a red flag to investigate immediately.

---

### Section 4: IN CASE OF EMERGENCY - Incident Response Plan

**Principle:** Don't panic. Follow a calm, logical checklist.

If you suspect a security breach (e.g., you see strange activity, get a budget alert, can't log in when you should be able to):

*   **[ ] Step 1: Isolate the System.** Your first priority is to stop the potential damage.
    *   **For a Cloud Instance:** The fastest way is to use the **OCI Web Console**. Navigate to your instance and click **"Stop"**. This is like pulling the power cord. The attacker is immediately cut off.
    *   **For your Laptop:** Disconnect it from the internet (turn off Wi-Fi, unplug the network cable).

*   **[ ] Step 2: Rotate All Credentials.** Assume your keys have been stolen. You must change the locks.
    1.  **Change your OCI Console Password.**
    2.  **Change your GitHub Password.**
    3.  **Generate a NEW SSH key pair.** Delete the old public key from your OCI instances and upload the new one. This invalidates the old, potentially stolen key.

*   **[ ] Step 3: Assess the Situation.** Once the immediate threat is contained, you can investigate.
    *   Restart the stopped instance and immediately check the system logs (`/var/log/secure` or `/var/log/auth.log`) for suspicious login attempts.
    *   Review your `SECURITY_SOP.md` log files. Compare the *current* firewall rules (`sudo firewall-cmd --list-all`) with what they *should* be according to your setup log. Has anything changed?

 Excellent. You are making a conscious, risk-based decision. The most important principle in security is to **have a plan and document it**. You've decided to implement a temporary IP whitelist and revisit the more secure SSH tunnel later. This is a perfectly valid operational decision.

Let's address your two points: fixing the command and documenting the action.

---

### Part 1: Fixing the Technical Error

You've encountered a common and subtle shell error.

**The Problem:**
The error message `-bash: warning: here-document at line 6 delimited by end-of-file (wanted \`EOF')` means that the shell could not find the closing `EOF` tag to finish the command.

**The Reason:**
The closing delimiter of a `here-document` (the `EOF` at the end) **must be on a new line, by itself, with no spaces or tabs before it.** In your pasted command, it was indented.

**The Correct Command:**

Here is the corrected, copy-paste-ready version.

```bash
# IMPORTANT: First, get your current IP from your VPN
# Run this command and copy the IP address:
curl ifconfig.me

# Now, use that IP address in the command below
# Replace 203.0.113.55/32 with YOUR VPN's IP address followed by /32

cat << EOF > ~/postgres_rule.json
[
  {
    "direction": "INGRESS",
    "protocol": "6",
    "source": "203.0.113.55/32",
    "tcpOptions": {
      "destinationPortRange": {
        "max": 5432,
        "min": 5432
      }
    },
    "description": "Allow Postgres access from my VPN IP (Temporary)"
  }
]
EOF
```
Notice how the final `EOF` has no indentation. This will now work correctly. After creating this file, you would proceed with the `jq` merge and `oci network security-list update` commands from our SOP.

---

### Part 2: How to Document This Action

This is the most important part of your request. You need a formal record of the decision and the action taken. The perfect place for this is a new section in your `MY_SECURITY_PLAYBOOK.md` document.

We will call this section the **"Operational Security Log."**

This log is not for procedures; it's for recording significant *events* and *changes*. It's your system's diary.

**Action:**
Open your `MY_SECURITY_PLAYBOOK.md` file and add the following section to the end of the document. I have pre-filled the first entry for the action you are taking right now.

---

### Section 5: Operational Security Log

*This log records all significant security-related changes made to the infrastructure. Each entry must be dated and include the justification for the change.*

---
**Log Entry: #001**

*   **Date:** `Sat Sep  6 02:15:37 AM GMT 2025`
*   **System(s) Affected:**
    *   OCI Prod Instance (`130.61.246.120`)
*   **Change Description:**
    Implemented a temporary firewall rule to allow PostgreSQL access (TCP port 5432) from my personal laptop, which is actively using a VPN with a dynamic IP address/OCI Dev Instance.
*   **Action Taken:**
    1.  Identified my current home public IP address using `curl ifconfig.me`.
    2.  Created a new OCI Security List rule to allow ingress traffic on TCP port 5432 from the identified source IP.
    3.  Safely merged this new rule with the existing rules (preserving SSH access) using the `jq` command.
    4.  Applied the updated ruleset using the `oci network security-list update` command.
    5.  Added a corresponding rule to the host `firewalld` service.
*   **Justification & Context:**
    My primary work environment uses a VPN, making the original static IP whitelisting strategy ineffective. This temporary rule is a stop-gap measure to enable development. I acknowledge this is less secure than an SSH tunnel because the trusted IP will change frequently, requiring manual updates.
*   **Follow-Up Action:**
    I will revisit and implement the more secure **SSH Tunnel solution (Playbook Option 1)** at a later date to provide a permanent, IP-agnostic, and more secure access method.
*   **Verification:**
    Confirmed that after applying the rule, I could successfully connect to the PostgreSQL database from my laptop. `nmap -p 5432 [INSTANCE_IP]` showed the port as OPEN from my VPN IP.





### The Two Firewalls: A Critical Concept

A cloud instance is protected by **two** firewalls, and we must configure both for a robust security posture:
---

### Part 1: Configuring the Cloud Firewall (OCI Security List)

#### Step 1: Get Your Public IP Address

From your **local machine** (your home or office computer, not the server), get your public IP. This is the IP we will grant access to.

```bash
# Run this on your LOCAL machine
curl ifconfig.me
```
Let's assume your IP is `203.0.113.55`. We will use this in the next steps.

#### Step 2: Identify Your Server's Network Details

On your **OCI server**, we need to find the OCID (Oracle Cloud Identifier) of the Security List that is governing your instance's network traffic.

```bash
# Run these commands ON YOUR OCI SERVER

# First, get your instance's OCID
INSTANCE_OCID=$(curl -s -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/id)

# Next, get the OCID of the network interface attached to your instance
VNIC_OCID=$(oci compute instance list-vnics --instance-id $INSTANCE_OCID --query "data[0].id" --raw-output)

# Finally, find the Security List OCID associated with that network interface
# NOTE: This assumes you are using Security Lists, not Network Security Groups (NSGs).
# This is the default for most basic setups.
SUBNET_OCID=$(oci network vnic get --vnic-id $VNIC_OCID --query "data.\"subnet-id\"" --raw-output)
SECLIST_OCID=$(oci network subnet get --subnet-id $SUBNET_OCID --query "data.\"security-list-ids\"[0]" --raw-output)

echo "Your Security List OCID is: $SECLIST_OCID"
```
Keep the output `SECLIST_OCID` handy.

#### Step 3: Add the Firewall Rule

We will now instruct OCI to add a new rule to this Security List. We'll create a small JSON file to define the rule.

1.  Create the rule definition file:
    ```bash
    # Run ON YOUR OCI SERVER
    # Replace 203.0.113.55/32 with YOUR local IP address followed by /32
    
    cat << EOF > ~/postgres_rule.json
    [
      {
        "direction": "INGRESS",
        "protocol": "6",
        "source": "203.0.113.55/32",
        "tcpOptions": {
          "destinationPortRange": {
            "max": 5432,
            "min": 5432
          }
        },
        "description": "Allow Postgres access from my home IP"
      }
    ]
    EOF
    ```

2.  **Get the existing rules and append our new rule.** This is crucial to avoid overwriting existing rules (like your SSH access).
    ```bash
    # Get all existing ingress rules
    oci network security-list get --security-list-id $SECLIST_OCID --query "data.\"ingress-security-rules\"" > ~/existing_rules.json

    # Combine the existing rules with our new rule using the 'jq' tool
    jq -s '.[0] + .[1]' ~/existing_rules.json ~/postgres_rule.json > ~/combined_rules.json
    ```

3.  **Apply the new, combined set of rules.**
    ```bash
    oci network security-list update --security-list-id $SECLIST_OCID --ingress-security-rules file://~/combined_rules.json --force
    ```

You have now configured the cloud firewall. Traffic on port 5432 from any IP other than your own will be dropped before it ever reaches your server.

---

### Part 2: Configuring the Host Firewall (`firewalld`)

Now for the second layer of defense on the server itself.

#### Step 1: Check the Status of `firewalld`

```bash
# Run ON YOUR OCI SERVER
sudo firewall-cmd --state
```
It should return `running`.

#### Step 2: Add the Rule to `firewalld`

We will add a "rich rule" that is very specific.

```bash
# Run ON YOUR OCI SERVER
# Again, replace 203.0.113.55 with YOUR local IP address

sudo firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="203.0.113.55" port protocol="tcp" port="5432" accept'
```

#### Step 3: Make the Rule Permanent

The command above only adds a temporary rule. We need to make it survive a reboot.

```bash
# Run ON YOUR OCI SERVER
sudo firewall-cmd --runtime-to-permanent
# You should see a "success" message.
```

#### Step 4: Verify the `firewalld` Rules

```bash
# Run ON YOUR OCI SERVER
sudo firewall-cmd --list-all
```
In the output, under `rich rules:`, you should now see the rule you just added.

---

### Final Verification

From your **local machine**, you should now be able to connect to the database. A simple test is to use `nmap` or `telnet`.

```bash
# Run this on your LOCAL machine
# Replace <your_server_ip> with your instance's public IP
nmap -p 5432 <your_server_ip>
```
The output should show the port as `OPEN`. If you try this from any other network (e.g., your phone's hotspot), it will show as `FILTERED` or `CLOSED`.
