That's the perfect question to ask. This is the mindset of a proactive SRE: "How do I prevent this from ever happening again?"

The lesson you quoted is the most important one from this incident. Cloud providers offer images as a convenience, but they are not always perfectly configured for every use case, especially for public internet traffic.

Here is a practical, repeatable checklist you should use every time you start a new VPS. This "Day 0 Sanity Check" will take you less than five minutes and can save you hours or days of future debugging.

---

### Your "Day 0" Sanity Checklist for Any New VPS

#### 1. Verify Critical Network Configuration (The #1 Priority)

This is what caused your last incident. Never skip this.

*   **Action:** Check the MTU (Maximum Transmission Unit).
*   **Command:** `ip a`
*   **What to Look For:** Find your main network interface (e.g., `enp0s6`, `eth0`). Look for `mtu 1500`. If you see `mtu 9000` (Jumbo Frames) or anything other than 1500 on an internet-facing VM, it's a red flag.
*   **Fix (if needed):**
    1.  Find the connection name: `nmcli connection show`
    2.  Set the permanent MTU: `sudo nmcli connection modify "Connection Name" mtu 1500`. for instance:
        [opc@instance-20250523-1627 ~]$ nmcli connection show
        NAME              UUID                                  TYPE      DEVICE
        Wired Connection  cf550dea-5926-49f5-8bf0-6550d203318c  ethernet  enp0s6
        docker0           bf20720c-00d5-4db1-83ec-0aed73b0737e  bridge    docker0
        lo                7a1b25eb-7a1a-4861-8cb2-092437cf241e  loopback  lo
        System enp0s6     e2669b02-93e0-840a-dc31-c2ec39c7ce27  ethernet  --
        [opc@instance-20250523-1627 ~]$ sudo nmcli connection modify "Connection Name" mtu 1500
        Error: unknown connection 'Connection Name'.
        [opc@instance-20250523-1627 ~]$ sudo ip link set dev enp0s6 mtu 1500
        [opc@instance-20250523-1627 ~]$ sudo nmcli connection modify "Wired Connection" mtu 1500

*   **Action:** Check basic internet connectivity and DNS resolution.
*   **Command:** `ping -c 3 google.com`
*   **What to Look For:** A successful reply. If this fails, your VM can't resolve domain names or reach the outside world, which means you won't be able to install or update anything.

#### 2. Verify System Resources and OS

Confirm you got what you paid for and know what you're working with.

*   **Action:** Check the OS version.
*   **Command:** `cat /etc/os-release`
*   **What to Look For:** The `PRETTY_NAME` field will tell you exactly which OS you're running (e.g., "Oracle Linux Server 9.4").

*   **Action:** Check CPU and Memory.
*   **Commands:**
    ```bash
    lscpu | grep '^CPU(s):'
    free -h
    ```
*   **What to Look For:** Make sure the number of CPUs and the total memory match the specifications of the VPS you provisioned.

*   **Action:** Check Disk Space.
*   **Command:** `df -h`
*   **What to Look For:** Check the `Size` and `Avail` columns for your root filesystem (usually `/`). This confirms your primary disk is mounted and has the expected capacity.

#### 3. Check the Default Security Posture

Don't assume the defaults are secure or configured how you expect.

*   **Action:** Check the firewall status.
*   **Commands:**
    *   For Oracle/Red Hat/CentOS: `sudo firewall-cmd --state` and `sudo firewall-cmd --list-all`
    *   For Debian/Ubuntu: `sudo ufw status`
*   **What to Look For:** Is the firewall running? What services/ports are already allowed? Often, only SSH (port 22) is open by default, which is good.

*   **Action:** Check for listening network services.
*   **Command:** `ss -tuln`
*   **What to Look For:** This shows all the processes listening for connections on your server. Look for anything unexpected. In a fresh VM, you should typically only see `sshd` listening on port 22 and some local services on `127.0.0.1`.

#### 4. Perform Initial System Update

Always start from a fully patched system.

*   **Action:** Update all packages to their latest versions.
*   **Commands:**
    *   For Oracle/Red Hat/CentOS: `sudo dnf update -y`
    *   For Debian/Ubuntu: `sudo apt update && sudo apt upgrade -y`
*   **What to Look For:** This process should complete without errors, ensuring your system has the latest security patches and bug fixes before you install anything else.

---

### Putting It All Together: A Simple Sanity-Check Script

You can even save this as a simple shell script on your local machine and run it on every new server to automate the process.

```bash
#!/bin/bash

echo "============================================="
echo "      VPS Day 0 Sanity Check"
echo "============================================="
echo ""

echo "--- 1. Network Configuration ---"
echo "[INFO] Checking MTU on all interfaces..."
ip a | grep mtu
echo ""
echo "[INFO] Checking DNS and Internet connectivity..."
ping -c 3 google.com
echo ""

echo "--- 2. System Resources & OS ---"
echo "[INFO] OS Version:"
cat /etc/os-release | grep PRETTY_NAME
echo ""
echo "[INFO] CPU and Memory:"
lscpu | grep '^CPU(s):'
free -h
echo ""
echo "[INFO] Disk Usage:"
df -h
echo ""

echo "--- 3. Security Posture ---"
echo "[INFO] Firewall Status:"
# Using firewall-cmd as an example
if command -v firewall-cmd &> /dev/null; then
    sudo firewall-cmd --state
    sudo firewall-cmd --list-ports
else
    echo "firewalld not found. Check for ufw or iptables."
fi
echo ""
echo "[INFO] Listening Network Services:"
ss -tuln
echo ""

echo "============================================="
echo "      Check Complete"
echo "============================================="
```

By running through this checklist, you are taking control of your environment. You are verifying the foundation before you build on it, which is the essence of good Site Reliability Engineering.
