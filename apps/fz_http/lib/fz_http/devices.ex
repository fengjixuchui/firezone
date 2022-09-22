defmodule FzHttp.Devices do
  @moduledoc """
  The Devices context.
  """

  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias EctoNetwork.INET
  alias FzHttp.{Devices.Device, Devices.DeviceSetting, Repo, Sites, Telemetry, Users, Users.User}

  require Logger

  def count_active_within(duration_in_secs) when is_integer(duration_in_secs) do
    cutoff = DateTime.add(DateTime.utc_now(), -1 * duration_in_secs)

    Repo.one(
      from d in Device,
        select: count(d.id),
        where: d.latest_handshake > ^cutoff
    )
  end

  def count do
    Repo.one(from d in Device, select: count(d.id))
  end

  def max_count_by_user_id do
    Repo.one(
      from d in Device,
        select: fragment("count(*) AS user_count"),
        group_by: d.user_id,
        order_by: fragment("user_count DESC"),
        limit: 1
    )
  end

  def list_devices do
    Repo.all(Device)
  end

  def list_devices(%User{} = user), do: list_devices(user.id)

  def list_devices(user_id) do
    Repo.all(from d in Device, where: d.user_id == ^user_id)
  end

  def as_settings do
    Repo.all(from(Device))
    |> Enum.map(&setting_projection/1)
    |> MapSet.new()
  end

  def setting_projection(device) do
    DeviceSetting.parse(device)
    |> Map.from_struct()
  end

  def count(user_id) do
    Repo.one(from d in Device, where: d.user_id == ^user_id, select: count())
  end

  def get_device!(id), do: Repo.get!(Device, id)

  def create_device(attrs \\ %{}) do
    # XXX: insert sometimes fails with deadlock errors, probably because
    # of the giant SELECT in queries/inet.ex. Find a way to do this more gracefully.
    {:ok, result} =
      Repo.transaction(fn ->
        %Device{}
        |> Device.create_changeset(attrs)
        |> Repo.insert()
      end)

    case result do
      {:ok, _device} ->
        Telemetry.add_device()

      _ ->
        nil
    end

    result
  end

  def update_device(%Device{} = device, attrs) do
    device
    |> Device.update_changeset(attrs)
    |> Repo.update()
  end

  def delete_device(%Device{} = device) do
    Telemetry.delete_device()
    Repo.delete(device)
  end

  def change_device(%Device{} = device, attrs \\ %{}) do
    Device.update_changeset(device, attrs)
  end

  @doc """
  Builds ipv4 / ipv6 config string for a device.
  """
  def inet(device) do
    ips =
      if ipv6?() do
        ["#{device.ipv6}/128"]
      else
        []
      end

    ips =
      if ipv4?() do
        ["#{device.ipv4}/32" | ips]
      else
        ips
      end

    Enum.join(ips, ",")
  end

  def to_peer_list do
    vpn_duration = Sites.vpn_duration()

    Repo.all(
      from d in Device,
        preload: :user
    )
    |> Enum.filter(fn device ->
      !device.user.disabled_at && !Users.vpn_session_expired?(device.user, vpn_duration)
    end)
    |> Enum.map(fn device ->
      %{
        public_key: device.public_key,
        inet: inet(device),
        preshared_key: device.preshared_key
      }
    end)
  end

  def new_device(attrs \\ %{}) do
    change_device(
      %Device{},
      Map.merge(
        %{
          "name" => Device.new_name(),
          "preshared_key" => FzCommon.FzCrypto.psk()
        },
        attrs
      )
    )
  end

  def allowed_ips(device), do: config(device, :allowed_ips)
  def endpoint(device), do: config(device, :endpoint)
  def dns(device), do: config(device, :dns)
  def mtu(device), do: config(device, :mtu)
  def persistent_keepalive(device), do: config(device, :persistent_keepalive)

  defp config(device, key) do
    if Map.get(device, String.to_atom("use_site_#{key}")) do
      Map.get(Sites.wireguard_defaults(), key)
    else
      Map.get(device, key)
    end
  end

  def defaults(changeset) do
    ~w(
      use_site_allowed_ips
      use_site_dns
      use_site_endpoint
      use_site_mtu
      use_site_persistent_keepalive
    )a
    |> Map.new(&{&1, get_field(changeset, &1)})
  end

  def as_encoded_config(device), do: Base.encode64(as_config(device))

  def as_config(device) do
    wireguard_port = Application.fetch_env!(:fz_vpn, :wireguard_port)
    server_public_key = Application.get_env(:fz_vpn, :wireguard_public_key)

    if is_nil(server_public_key) do
      Logger.error(
        "No server public key found! This will break device config generation. Is fz_vpn alive?"
      )
    end

    """
    [Interface]
    PrivateKey = REPLACE_ME
    Address = #{inet(device)}
    #{mtu_config(device)}
    #{dns_config(device)}

    [Peer]
    #{psk_config(device)}
    PublicKey = #{server_public_key}
    #{allowed_ips_config(device)}
    Endpoint = #{endpoint(device)}:#{wireguard_port}
    #{persistent_keepalive_config(device)}
    """
  end

  def decode(nil), do: nil
  def decode(inet), do: INET.decode(inet)

  defp psk_config(device) do
    if device.preshared_key do
      "PresharedKey = #{device.preshared_key}"
    else
      ""
    end
  end

  defp mtu_config(device) do
    m = mtu(device)

    if field_empty?(m) do
      ""
    else
      "MTU = #{m}"
    end
  end

  defp allowed_ips_config(device) do
    a = allowed_ips(device)

    if field_empty?(a) do
      ""
    else
      "AllowedIPs = #{a}"
    end
  end

  defp persistent_keepalive_config(device) do
    pk = persistent_keepalive(device)

    if field_empty?(pk) do
      ""
    else
      "PersistentKeepalive = #{pk}"
    end
  end

  defp dns_config(device) when is_struct(device) do
    dns = dns(device)

    if field_empty?(dns) do
      ""
    else
      "DNS = #{dns}"
    end
  end

  defp field_empty?(nil), do: true

  defp field_empty?(0), do: true

  defp field_empty?(field) when is_binary(field) do
    len =
      field
      |> String.trim()
      |> String.length()

    len == 0
  end

  defp field_empty?(_), do: false

  defp ipv4? do
    Application.fetch_env!(:fz_http, :wireguard_ipv4_enabled)
  end

  defp ipv6? do
    Application.fetch_env!(:fz_http, :wireguard_ipv6_enabled)
  end
end
