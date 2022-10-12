---
title: Troubleshoot
sidebar_position: 5
---

For any problems that arise, a good first bet is to check the Firezone logs.
Firezone logs are stored in `/var/log/firezone` and can be viewed with
`sudo firezone-ctl tail`.

## Debugging Portal Websocket Connectivity Issues

The portal UI requires a secure websocket connection to function. To facilitate
this, the Firezone phoenix service checks the `Host` header for inbound
websocket connections and only permits the connection if it matches the host
portion of your `default['firezone']['external_url']` variable.

If a secure websocket connection can't be established, you'll see a red dot
indicator in the upper-right portion of the Firezone web UI and a corresponding
message when you hover over it:

```text
Secure websocket not connected! ...
```

If you're accessing Firezone using the same URL defined in your
`default['firezone']['external_url']` variable from above, the issue is likely
to be in your reverse proxy configuration.

In most cases, you'll find clues in one or more of the following locations:

* Your browser's developer tool logs, specifically the `Network` tab.
* `sudo firezone-ctl tail nginx`
* `sudo firezoen-ctl tail phoenix`

If the websocket connection is successful, you should see output in the
`phoenix` service logs similar the following:

```text
2022-09-23_15:05:47.29158 15:05:47.291 [info] CONNECTED TO Phoenix.LiveView.Socket in 24µs
2022-09-23_15:05:47.29160   Transport: :websocket
2022-09-23_15:05:47.29160   Serializer: Phoenix.Socket.V2.JSONSerializer
2022-09-23_15:05:47.29161   Parameters: %{"_csrf_token" => "XFEFCHQ2fRQABQwtKQdCJDlFAzEcCCJvn7LqDsMXE4eGZtsBzuwVRCJ6", "_mounts" => "0", "_track_static" => %{"0" => "https://demo.firez.one/dist/admin-02fabe0f543c64122dbf5bc5b3451e51.css?vsn=d", "1" => "https://demo.firez.one/dist/admin-04e75c78295062c2c07af61be50248b0.js?vsn=d"}, "vsn" => "2.0.0"}
2022-09-23_15:05:47.33655 15:05:47.336 [info] CONNECTED TO FzHttpWeb.UserSocket in 430µs
2022-09-23_15:05:47.33657   Transport: :websocket
2022-09-23_15:05:47.33658   Serializer: Phoenix.Socket.V2.JSONSerializer
2022-09-23_15:05:47.33658   Parameters: %{"token" => "SFMyNTY.g2gDYQFuBgB6HeJqgwFiAAFRgA.qKoC2bi9DubPkE0tfaRSPERWUFyQQPQV5n4nFKVppxc", "vsn" => "2.0.0"}
2022-09-23_15:05:47.35063 15:05:47.350 [info] JOINED notification:session in 636µs
2022-09-23_15:05:47.35065   Parameters: %{"token" => "SFMyNTY.g2gDYQFuBgB6HeJqgwFiAAFRgA.zSG7pefm-Vgf_zvduxa5E9VK4s8PKqzc0xBDGNx5FQE", "user_agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:106.0) Gecko/20100101 Firefox/106.0"}
```

## Debugging WireGuard Connectivity Issues

Most connectivity issues with Firezone are caused by other `iptables` or
`nftables` rules which interfere with Firezone's operation. If you have rules
active, you'll need to ensure these don't conflict with the Firezone rules.

### Internet Connectivity Drops when Tunnel is Active

If your Internet connectivity drops whenever you activate your WireGuard
tunnel, you should make sure that the `FORWARD` chain allows packets
from your WireGuard clients to the destinations you want to allow through
Firezone.

If you're using `ufw`, this can be done by making sure the default routing
policy is `allow`:

```text
ubuntu@fz:~$ sudo ufw default allow routed
Default routed policy changed to 'allow'
(be sure to update your rules accordingly)
```

A `ufw` status for a typical Firezone server might look like this:

```text
ubuntu@fz:~$ sudo ufw status verbose
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), allow (routed)
New profiles: skip

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW IN    Anywhere
80/tcp                     ALLOW IN    Anywhere
443/tcp                    ALLOW IN    Anywhere
51820/udp                  ALLOW IN    Anywhere
22/tcp (v6)                ALLOW IN    Anywhere (v6)
80/tcp (v6)                ALLOW IN    Anywhere (v6)
443/tcp (v6)               ALLOW IN    Anywhere (v6)
51820/udp (v6)             ALLOW IN    Anywhere (v6)
```

## Need additional help?

Try asking on one of our community-powered support channels:

* [Discussion Forums](https://discourse.firez.one/): ask questions, report bugs,
and suggest features
* [Public Slack Group](https://join.slack.com/t/firezone-users/shared_invite/zt-111043zus-j1lP_jP5ohv52FhAayzT6w):
join discussions, meet other users, and meet the contributors

We highly recommend considering [priority support](https://firezone.dev/pricing)
if you're deploying Firezone in a production capacity.
