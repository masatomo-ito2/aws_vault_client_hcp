#!/bin/bash
# Script to deploy a very simple web application.
# The web app has a customizable image and some text.

set -x 
exec > >(tee /tmp/tf-user-data.log|logger -t hashicat ) 2>&1

curl -o /tmp/vault.zip https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip

sudo apt-get install unzip

unzip -q -d /usr/local/bin /tmp/vault.zip
chmod 0755 /usr/local/bin/vault

echo "set -o vi" >> /etc/profile
echo "export VAULT_ADDR=${VAULT_ADDR}" >> /etc/profile
echo "export VAULT_NAMESPACE=${VAULT_NAMESPACE}" >> /etc/profile

vault status 

# SSH OTP

curl -o /tmp/vault-ssh-helper.zip https://releases.hashicorp.com/vault-ssh-helper/${VAULT_SSH_HELPER_VERSION}/vault-ssh-helper_${VAULT_SSH_HELPER_VERSION}_linux_amd64.zip
unzip -q -d /usr/local/bin /tmp/vault-ssh-helper.zip
chmod 0755 /usr/local/bin/vault-ssh-helper.zip
chown root:root /usr/local/bin/vault-ssh-helper

mkdir /etc/vault-ssh-helper.d

tee /etc/vault-ssh-helper.d/config.hcl <<EOF
vault_addr = "${VAULT_ADDR}"
tls_skip_verify = false
ssh_mount_point = "ssh"
namespace = "admin"
allowed_roles = "*"
EOF

cp /etc/pam.d/sshd /etc/pam.d/sshd.orig

tee /etc/pam.d/sshd <<EOF
# Standard Un*x authentication.
#@include common-auth
auth requisite pam_exec.so quiet expose_authtok log=/var/log/vault-ssh.log /usr/local/bin/vault-ssh-helper -dev -config=/etc/vault-ssh-helper.d/config.hcl
auth optional pam_unix.so not_set_pass use_first_pass nodelay

# Disallow non-root logins when /etc/nologin exists.
account    required     pam_nologin.so

# Uncomment and edit /etc/security/access.conf if you need to set complex
# access limits that are hard to express in sshd_config.
# account  required     pam_access.so

# Standard Un*x authorization.
@include common-account

# SELinux needs to be the first session rule.  This ensures that any
# lingering context has been cleared.  Without this it is possible that a
# module could execute code in the wrong domain.
session [success=ok ignore=ignore module_unknown=ignore default=bad]        pam_selinux.so close

# Set the loginuid process attribute.
session    required     pam_loginuid.so

# Create a new session keyring.
session    optional     pam_keyinit.so force revoke

# Standard Un*x session setup and teardown.
@include common-session

# Print the message of the day upon successful login.
# This includes a dynamically generated part from /run/motd.dynamic
# and a static (admin-editable) part from /etc/motd.
session    optional     pam_motd.so  motd=/run/motd.dynamic
session    optional     pam_motd.so noupdate

# Print the status of the user's mailbox upon successful login.
session    optional     pam_mail.so standard noenv # [1]

# Set up user limits from /etc/security/limits.conf.
session    required     pam_limits.so

# Read environment variables from /etc/environment and
# /etc/security/pam_env.conf.
session    required     pam_env.so # [1]
# In Debian 4.0 (etch), locale-related environment variables were moved to
# /etc/default/locale, so read that as well.
session    required     pam_env.so user_readenv=1 envfile=/etc/default/locale

# SELinux needs to intervene at login time to ensure that the process starts
# in the proper default security context.  Only sessions which are intended
# to run in the user's context should be run after this.
session [success=ok ignore=ignore module_unknown=ignore default=bad]        pam_selinux.so open

# Standard Un*x password updating.
@include common-password
EOF

cp /etc/ssh/sshd_config /etc/ssh/sshd_config.orig

sed -e 's/^\(ChallengeResponseAuthentication\) .*$/\1 yes/g' /etc/ssh/sshd_config
sed -e 's/^\(UsePAM\) .*$/\1 yes/g' /etc/ssh/sshd_config
sed -e 's/^\(PasswordAuthentication\) .*$/\1 no/g' /etc/ssh/sshd_config

systemctl restart sshd

nohup vault-ssh-helper -verify-only -dev -config /etc/vault-ssh-helper.d/config.hcl &

echo "Script complete."
