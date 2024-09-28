# Summary - (draft)
These are the steps I used to deploy a working Tinkerbell stack on Kubernetes to manage bare metal machine imaging.  
Issues and gotchas captured along the way.  

## Host preparating
### The Hardware
The machines used are Minis-forum NUC PCs, with AMD Ryzen 9 7940HS w/ Radeon 780M Graphics, 64GB RAM, 1TB NVMe block storage devices.
The Tink-stack machine has the following network interfaces:
 - Wi-Fi (`/dev/wlp2s0 - Intel Corporation Wi-Fi 6E(802.11ax) AX210/AX1675* 2x2 [Typhoon Peak] (rev 1a)`)
 - Ethernet (`/dev/emp1s0 - Realtek Semiconductor Co., Ltd. RTL8125 2.5GbE Controller (rev 05)`)
Ethernet is used for serving DHCP, iPXE, and related services for installing an OS using the tink-stack.

### OS
Ubuntu 24.04.1 LTS x86_64, Desktop version, Kernel version 6.8.0-45-generic
NAT is configured with ufw. See [this gist](https://gist.github.com/mattsn0w/3421d2942b96e1e6f3113b3d174b7cb0).
OpenSSH Server is installed and enabled.

```
apt install openssh-server && systemctl enable ssh && systemctl start ssh
# Setup ethernet interface.
# copypasta into /etc/netplan/enp1s0.yaml ; netplan generate && netplan apply
network:
  renderer: networkd
  version: 2
  ethernets:
    enp1s0:
      dhcp4: false
      dhcp6: false
      addresses: [ 192.168.1.254/24 ]
      nameservers:
        addresses: [ 1.1.1.1, 1.0.0.1 ]

```

### Before moving forward
Ensure that both ethernet and wireless interfaces are configured and active with link status up. If the ethernet does not have link up state, then the tink-stack will not provision correctly. kube-vip will only bind the IP address to an active/up network interface. Check with `ip a s | grep 192.168` to see which network interface the kube-vip LB_IP is bound to. This should be done on a physical Ethernet interface for DHCP/PXE to work.

## Install k3s
Install a single node k3s (_v1.30.5+k3s1_) cluster. Install without servicelb, traefik, or metrics-server since that is what [the playground quick-start guide does](https://github.com/tinkerbell/playground/blob/main/stack/vagrant/setup.sh#L51).  

This setup used K3s v1.30.5+k3s1 and containerd v1.7.21-k3s2.  

```
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable=servicelb,traefik,metrics-server --token T1nk5tacK" sh -s - 
```

### Kubernetes env config
Copy the k3s.yaml to your own `KUBECONFIG`. In production you should limit scope and use RBAC or setup Dex IdP with OIDC. 
```
mkdir -m700 ~/.kube/
sudo cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
sudo chown ubuntu /home/ubuntu/.kube/config
```
Now setup your shell helper for tab completion to make those long kubectl commands easier and reduce typing fatigue. 
```
# Add to your ~/.bash_aliases
export KUBECONFIG=${HOME}/.kube/config
alias k=kubectl
source <(k completion bash)
complete -F __start_kubectl k
```

## Deploy Tink-stack using helm
See `deploy_tink-stack.sh`.

## Create and apply a Hardware Spec
Create a [Machine](https://tinkerbell.org/docs/concepts/hardware/) manifest for the hardware you are going to provision.  See `machine_nuc2.yaml` for details.

## Create and apply a Template
Create a [Template](https://tinkerbell.org/docs/concepts/templates/).  
A Templates define a collection of Tasks that are executed sequentially.  
A Task is a collection of Actions executed sequentially on a specific worker.  
`template.yaml`



## References
* https://github.com/tinkerbell/playground/tree/main/stack/vagrant
* https://tinkerbell.org/docs/concepts/hardware/
* https://docs.k3s.io/cli/server
* https://docs.k3s.io/installation/configuration
*  - forked to 
