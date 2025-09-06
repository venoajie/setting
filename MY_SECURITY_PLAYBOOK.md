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

---


*This log records all significant security-related changes made to the infrastructure. Each entry must be dated and include the justification for the change.*

---Log Entry: #001

Date: Sat Sep  6 10:29:02 AM GMT 2025

System(s) Affected:

OCI Prod Instance (instance-20250707-0704)
PostgreSQL Database (Docker container: central_postgres_server)
Security List: ocid1.securitylist.oc1.eu-frankfurt-1.aa****a
Change Description:
Implemented network-level security restrictions for PostgreSQL database and recovered from a PostgreSQL configuration error that caused a service outage.

Actions Taken:

Network Security Implementation (SUCCESSFUL):
Restricted PostgreSQL port 5432 access via OCI Security List
Updated ingress rules to allow only:
My laptop public IP: 1***8/32
Dev subnet CIDR: 10.0.0.0/24
SSH remained open on port 22 from 0.0.0.0/0
Used script psql_port.sh to automate the security list update
PostgreSQL SSL Configuration Attempt (FAILED):
Attempted to enable SSL encryption by adding to postgresql.conf:
text
ssl = on
logging_collector = on
log_connections = on
PostgreSQL entered restart loop with error: FATAL: could not load server certificate file "server.crt"
Container continuously restarting, database inaccessible
Recovery Actions:
Tried multiple approaches to fix configuration:
Attempted to edit config inside container (failed - container restarting)
Used alpine container to remove SSL settings from config files
Discovered PostgreSQL data directory was corrupted/empty
Final solution: Complete volume reset
bash
docker compose down -v
docker compose up -d postgres
PostgreSQL successfully reinitialized with default configuration
Service restored at 10:07:43 UTC
Justification & Context:

Network restrictions: Essential first layer of security to prevent unauthorized database access
SSL attempt: Tried to implement defense-in-depth but failed due to lack of certificate files
Decision: Network firewall provides sufficient security for current use case; SSL can be deferred
Lessons Learned:

Always test configuration changes in dev before prod
SSL in Docker requires certificate files to be present before enabling
Network-level security (firewall rules) is the most critical layer
Keep backups before making PostgreSQL configuration changes
Current Security Status:

✅ Network Access: Restricted to authorized IPs only
✅ PostgreSQL: Running with default configuration
⚠️ SSL/TLS: Not implemented (deferred)
⚠️ Database Users: Still using default postgres user
❌ Previous Data: Lost during recovery (no production data existed)
Follow-Up Actions Required:

Change default postgres user password
Create application-specific database users with limited privileges
Implement automated backup strategy
Document recovery procedures for future reference
Consider OCI Bastion Service for more secure access pattern
Verification:

PostgreSQL accessible from authorized IPs: psql -h [OCI_IP] -U postgres -p 5432 ✓
Unauthorized IPs cannot connect (timeout) ✓
Container stable and running: STATUS: Up About a minute ✓
No SSL errors in logs ✓
Commands for Future Reference:

bash
# Check current security rules
oci network security-list get --security-list-id [SL_ID] --query 'data."ingress-security-rules"[*]'

# Test PostgreSQL connectivity
docker exec -it central_postgres_server psql -U postgres -c "SELECT 1;"

# Emergency rollback to open access (if locked out)
oci network security-list update --security-list-id [SL_ID] --ingress-security-rules '[{"protocol":"6","source":"0.0.0.0/0","tcpOptions":{"destinationPortRange":{"min":5432,"max":5432}}}]' --force
This log entry now accurately reflects what happened today, including both the successful network security implementation and the PostgreSQL SSL configuration issue and recovery.
