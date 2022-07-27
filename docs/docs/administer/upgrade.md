---
title: Upgrade
sidebar_position: 3
---

Upgrading Firezone will disconnect all VPN sessions and require shutting
down the Web UI. We recommend a maintenance window of about an hour in case
anything goes wrong during the upgrade.

To upgrade Firezone, follow these steps:

1. If not setup already, install our package repository based on your distro's
    package format:
    - [deb packages](https://cloudsmith.io/~firezone/repos/firezone/setup/#formats-deb)
    - [rpm packages](https://cloudsmith.io/~firezone/repos/firezone/setup/#formats-rpm)
1. Upgrade the `firezone` package using your distro's package manager.
1. Run `firezone-ctl reconfigure` to pick up the new changes.
1. Run `firezone-ctl restart` to restart services.

Occasionally problems arise. If you hit any, please let us know by [filing an
issue](https://github.com/firezone/firezone/issues/new/choose).

## Upgrading from < 0.5.0 to >= 0.5.0

### Overlapping egress rule destinations

Firezone 0.5.0 removes the ability to add rules with overlapping destinations.
When upgrading to 0.5.0, our migration script will automatically detect these
cases and **keep only the rules whose destination encompasses the other rule**.
If this is OK, **there is nothing you need to do**.

Otherwise, we recommend modifying your ruleset to eliminate these cases before
upgrading.

### Preconfigured Okta and Google SSO

Firezone 0.5.0 removes support for the old-style Okta and Google SSO
configuration in favor of the new, more flexible OIDC-based configuration.
If you have any configuration under the
`default['firezone']['authentication']['okta']` or
`default['firezone']['authentication']['google']` keys, **you need to migrate
these to our OIDC-based configuration using the guide below.**

#### Existing Google OAuth configuration

Remove these lines containing the old Google OAuth configs from your configuration
file located at `/etc/firezone/firezone.rb`

```rb
default['firezone']['authentication']['google']['enabled']
default['firezone']['authentication']['google']['client_id']
default['firezone']['authentication']['google']['client_secret']
default['firezone']['authentication']['google']['redirect_uri']
```

Then, follow the instructions [here](../authenticate/google) to configure Google
as an OIDC provider.

#### Existing Okta OAuth configuration

Remove these lines containing the old Okta OAuth configs from your configuration
file located at `/etc/firezone/firezone.rb`

```rb
default['firezone']['authentication']['okta']['enabled']
default['firezone']['authentication']['okta']['client_id']
default['firezone']['authentication']['okta']['client_secret']
default['firezone']['authentication']['okta']['site']
```

Then, follow the instructions [here](../authenticate/okta) to configure Okta as
an OIDC provider.

## Upgrading from 0.3.x to >= 0.3.16

Follow the instructions below based on your current version and setup:

### I have an existing OIDC integration

Upgrading to >= 0.3.16 requires the `offline_access` scope for some OIDC providers
to obtain a refresh token.
This ensures Firezone syncs with the identity provider and VPN access is terminated
once the user is removed. Previous versions of Firezone do not have this capability.
Users who are removed from your identity provider will still have active VPN sessions
in some cases.

For OIDC providers that support the `offline_access` scope, you will need to add
`offline_access` to the `scope` parameter of your OIDC config. The
Firezone configuration file can be found at `/etc/firezone/firezone.rb` and requires
running `firezone-ctl reconfigure` to pick up the changes.

If Firezone is able to successfully retrieve the refresh token, you will see
the **OIDC Connections** heading in the user details page of the web UI for
users authenticated through your OIDC provider.

![OIDC Connections](https://user-images.githubusercontent.com/52545545/173169922-b0e5f2f1-74d5-4313-b839-6a001041c07e.png)

If this does not work, you will need to delete your existing OAuth app
and repeat the OIDC setup steps to
[create a new app integration](../authenticate/) .

### I have an existing OAuth integration

Prior to 0.3.11, Firezone used pre-configured OAuth2 providers. Follow the
instructions [here](../authenticate/) to migrate
to OIDC.

### I have not integrated an identity provider

No action needed. You can follow the instructions
[here](../authenticate/)
to enable SSO through an OIDC provider.

## Upgrading from 0.3.1 to >= 0.3.2

The configuration option `default['firezone']['fqdn']` has been removed in favor
of `default['firezone']['external_url']`. Please set this to the
publicly-accessible URL of your Firezone web portal. If left unspecified it will
default to `https://` + the FQDN of your server.

Reminder, the configuration file can be found at `/etc/firezone/firezone.rb`.
For an exhaustive list of configuration variables and their descriptions, see the
[configuration file reference](../reference/configuration-file).

## Upgrading from 0.2.x to 0.3.x

Starting with version 0.3.0, Firezone no longer stores device private
keys on the Firezone server. Any existing devices should continue to function
as-is, but you will not be able to re-download or view these configurations in
the Firezone Web UI.

## Upgrading from 0.1.x to 0.2.x

Firezone 0.2.x contains some configuration file changes that will need to be
handled manually if you're upgrading from 0.1.x. Run the commands below as root
to perform the needed changes to your `/etc/firezone/firezone.rb` file.

```bash
cp /etc/firezone/firezone.rb /etc/firezone/firezone.rb.bak
sed -i "s/\['enable'\]/\['enabled'\]/" /etc/firezone/firezone.rb
echo "default['firezone']['connectivity_checks']['enabled'] = true" >> /etc/firezone/firezone.rb
echo "default['firezone']['connectivity_checks']['interval'] = 3_600" >> /etc/firezone/firezone.rb
firezone-ctl reconfigure
firezone-ctl restart
```
