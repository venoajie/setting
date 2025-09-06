## SOP: OCI Instance Security Baseline

| **Document ID:** | SEC-SOP-001 | **Version:** | 1.0 |
| :--- | :--- | :--- | :--- |
| **Title:** | Standard Operating Procedure: OCI Compute Instance Security Baseline | **Author:** | Cloud Security Engineer |
| **Status:** | **Approved** | **Last Updated:** | 2024-10-20 |

### 1.0 Objective

This document provides the standard procedure for establishing a secure network baseline for any new Oracle Cloud Infrastructure (OCI) compute instance. The primary goal is to minimize the network attack surface by implementing a "deny by default, allow by exception" firewall policy at both the cloud and host levels.

### 2.0 Security Principles

This procedure is built on three core security principles:

1.  **Defense-in-Depth:** We will configure two independent firewalls (OCI Security List and Host `firewalld`). If one layer fails or is misconfigured, the other provides continued protection.
2.  **Principle of Least Privilege:** We will only open the specific ports required for a service to function, and only to the specific IP addresses that require access.
3.  **Attack Surface Reduction:** By default, the instance is invisible to the public internet. We only expose what is absolutely necessary.

### 3.0 Prerequisites

Before starting, ensure you have the following:

*   The Public IP of the new OCI instance.
*   SSH access to the instance is confirmed to be working.
*   The OCI CLI is installed and configured on the instance.
*   The `jq` command-line JSON processor is installed (`sudo dnf install jq`).
*   Your local machine's public IP address. You can get this by running `curl ifconfig.me` on your local terminal.

---

### 4.0 Initial Setup Procedure for a New Instance

Follow these steps immediately after provisioning a new instance.

#### 4.1 Define Required Services

First, define which ports need to be accessible from your IP.

*   **SSH (Required):** Port `22`
*   **PostgreSQL (Example):** Port `5432`
*   **Web Server (Example):** Port `8000`

#### 4.2 Configure the Cloud Firewall (OCI Security List)

This is the most critical step. We will **replace** the default, overly permissive rules with a strict, custom ruleset.

**Step 4.2.1: Get Network Identifiers**
Run this script on your OCI instance to gather the necessary OCIDs.

```bash
# Run ON YOUR OCI SERVER
INSTANCE_OCID=$(curl -s -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/id)
VNIC_OCID=$(oci compute instance list-vnics --instance-id $INSTANCE_OCID --query "data[0].id" --raw-output)
SUBNET_OCID=$(oci network vnic get --vnic-id $VNIC_OCID --query "data.\"subnet-id\"" --raw-output)
SECLIST_OCID=$(oci network subnet get --subnet-id $SUBNET_OCID --query "data.\"security-list-ids\"[0]" --raw-output)

echo "Your Security List OCID is: $SECLIST_OCID"
```

**Step 4.2.2: Create the Complete Ruleset File**
Create a JSON file that defines **ALL** the ingress rules you need. This prevents accidental lockouts.

```bash
# Run ON YOUR OCI SERVER
# IMPORTANT: Replace 203.0.113.55/32 with YOUR local IP address followed by /32

cat << EOF > ~/new_ruleset.json
[
  {
    "direction": "INGRESS",
    "protocol": "6",
    "source": "203.0.113.55/32",
    "tcpOptions": { "destinationPortRange": { "max": 22, "min": 22 }},
    "description": "Allow SSH from my home IP"
  },
  {
    "direction": "INGRESS",
    "protocol": "6",
    "source": "203.0.113.55/32",
    "tcpOptions": { "destinationPortRange": { "max": 5432, "min": 5432 }},
    "description": "Allow Postgres from my home IP"
  }
]
EOF
```
> **Note:** To add more rules, simply copy one of the blocks inside the `[...]` and change the port number and description.

**Step 4.2.3: Apply the New Ruleset**
This command will **REPLACE** all existing ingress rules with the ones defined in your file.

```bash
oci network security-list update --security-list-id $SECLIST_OCID --ingress-security-rules file://~/new_ruleset.json --force
```

#### 4.3 Configure the Host Firewall (`firewalld`)

This second layer of defense runs on the server itself.

```bash
# Run ON YOUR OCI SERVER
# Replace 203.0.113.55 with YOUR local IP address

# Add rule for SSH
sudo firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="203.0.113.55" port protocol="tcp" port="22" accept'

# Add rule for PostgreSQL
sudo firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="203.0.113.55" port protocol="tcp" port="5432" accept'

# Make the rules permanent so they survive a reboot
sudo firewall-cmd --runtime-to-permanent
```

### 5.0 Verification

After applying the rules, verify that they are working as expected.

1.  **Check OCI Rules:** In the OCI Web Console, navigate to your Security List and confirm the new rules are present and the old permissive rules are gone.
2.  **Check Host Rules:** Run `sudo firewall-cmd --list-all` on the server and confirm your rich rules are listed.
3.  **Test Connectivity (Allowed):** From your local machine (with the whitelisted IP), test the connection.
    ```bash
    # Test SSH
    ssh -i <your_key> opc@<your_server_ip>

    # Test Postgres
    nmap -p 5432 <your_server_ip> # Should show OPEN
    ```
4.  **Test Connectivity (Denied):** From a different network (e.g., your phone's hotspot), try to connect. The connection should time out or be refused.

---

### 6.0 Troubleshooting

| Problem | Probable Cause | Solution |
| :--- | :--- | :--- |
| **I am locked out of SSH.** (`Connection reset by peer` or `Connection timed out`) | The SSH rule (port 22) was accidentally removed from the OCI Security List. | **Use the OCI Web Console as your master key.** Log in, navigate to Networking -> VCNs -> Security Lists, and manually add the ingress rule for TCP port 22 from source `0.0.0.0/0`. |
| My application cannot connect, but SSH works. | The port for your application is blocked at one of the two firewall layers. | 1. Check the OCI Security List rules in the web console. Is the port listed? Is the source IP correct? <br> 2. Run `sudo firewall-cmd --list-all` on the server. Is the rule for your application's port present? |
| I changed my home IP and now I'm locked out. | The firewall rules are still configured for your old IP address. | Use the OCI Web Console to update the source IP in the Security List rules. If you can't access the console, you may need to connect from a location with the old IP or contact support. |

---

### 7.0 Procedure for Modifying Existing Rules

To **add a new rule** to an already secured instance without locking yourself out, follow this safe procedure.

1.  **Get the latest ruleset from OCI:**
    ```bash
    # Run ON YOUR OCI SERVER
    # (Get SECLIST_OCID from step 4.2.1 if you don't have it)
    oci network security-list get --security-list-id $SECLIST_OCID --query "data.\"ingress-security-rules\"" > ~/existing_rules.json
    ```
2.  **Create a file with ONLY the new rule you want to add:**
    ```bash
    # Example for adding a web server on port 8000
    cat << EOF > ~/new_single_rule.json
    [
      {
        "direction": "INGRESS",
        "protocol": "6",
        "source": "203.0.113.55/32",
        "tcpOptions": { "destinationPortRange": { "max": 8000, "min": 8000 }},
        "description": "Allow Web App from my home IP"
      }
    ]
    EOF
    ```
3.  **Safely merge the old and new rules:**
    ```bash
    jq -s '.[0] + .[1]' ~/existing_rules.json ~/new_single_rule.json > ~/combined_rules.json
    ```
4.  **Visually inspect the combined file** to ensure your SSH rule and all other rules are present:
    ```bash
    cat ~/combined_rules.json
    ```
5.  **Apply the combined ruleset:**
    ```bash
    oci network security-list update --security-list-id $SECLIST_OCID --ingress-security-rules file://~/combined_rules.json --force
    ```
6.  **Remember to also add the rule to `firewalld`** on the host.
