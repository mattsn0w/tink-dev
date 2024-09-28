#!/bin/bash
# Date : September 28th, 2024
# This is copied from a combinate of two sources:
#  - https://tinkerbell.org/docs/setup/install/#tldr
#  - https://github.com/tinkerbell/playground/blob/main/stack/vagrant/setup.sh#L76-L86

trusted_proxies=$(kubectl get nodes -o jsonpath='{.items[*].spec.podCIDR}' | tr ' ' ',')
echo "Trusted Proxies network is $trusted_proxies"

# Etherenet interface
interface=enp1s0
# Extra IP address for kube-vip to use on the ethernet interface.
LB_IP=192.168.1.250

STACK_CHART_VERSION=0.4.5

helm install tink-stack oci://ghcr.io/tinkerbell/charts/stack \
	--version "$STACK_CHART_VERSION" \
	--create-namespace \
	--namespace tink-system \
	--wait \
	--set "smee.trustedProxies={${trusted_proxies}}" \
	--set "hegel.trustedProxies={${trusted_proxies}}" \
	--set "stack.loadBalancerIP=$LB_IP" \
	--set "stack.kubevip.interface=$interface" \
	--set "stack.relay.sourceInterface=$interface" \
	--set "stack.loadBalancerIP=$LB_IP" \
	--set "smee.publicIP=$LB_IP"
