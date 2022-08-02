defmodule FzHttp.Repo.NotifierTest do
  use FzHttp.DataCase, async: false

  alias FzHttp.Repo.Notifier
  alias FzHttp.Events

  setup do
    on_exit(fn ->
      :sys.replace_state(Events.vpn_pid(), fn _state -> %{} end)

      :sys.replace_state(Events.wall_pid(), fn _state ->
        %{users: MapSet.new(), devices: MapSet.new(), rules: MapSet.new()}
      end)
    end)
  end

  describe "users changed" do
    setup :create_user

    test "adds user to wall state", %{user: user} do
      Notifier.handle_event("users", %{op: "INSERT", row: user})

      expected_state = %{
        users: MapSet.new([user.id]),
        rules: MapSet.new([]),
        devices: MapSet.new([])
      }

      assert :sys.get_state(Events.wall_pid()) == expected_state
    end

    test "user delete removes user from wall state", %{user: user} do
      Notifier.handle_event("users", %{op: "INSERT", row: user})
      Notifier.handle_event("users", %{op: "DELETE", row: user})

      expected_state = %{
        users: MapSet.new([]),
        rules: MapSet.new([]),
        devices: MapSet.new([])
      }

      assert :sys.get_state(Events.wall_pid()) == expected_state
    end
  end

  describe "rules changed" do
    setup :create_rule

    test "rule insert adds rule to wall state", %{rule: rule} do
      Notifier.handle_event("rules", %{op: "INSERT", row: rule})

      expected_state = %{
        users: MapSet.new([]),
        rules:
          MapSet.new([%{action: rule.action, destination: "10.10.10.0/24", user_id: rule.user_id}]),
        devices: MapSet.new([])
      }

      assert :sys.get_state(Events.wall_pid()) == expected_state
    end

    test "rule delete removes rule from wall state", %{rule: rule} do
      Notifier.handle_event("rules", %{op: "INSERT", row: rule})
      Notifier.handle_event("rules", %{op: "DELETE", row: rule})

      expected_state = %{
        users: MapSet.new([]),
        rules: MapSet.new([]),
        devices: MapSet.new([])
      }

      assert :sys.get_state(Events.wall_pid()) == expected_state
    end
  end

  describe "devices changed" do
    setup :create_rule_with_user_and_device

    test "device insert adds device to vpn and wall state", %{device: device, user: user} do
      Notifier.handle_event("devices", %{op: "INSERT", row: device})

      expected_vpn_state = %{
        "1" => %{
          allowed_ips: "10.3.2.2/32,fd00::3:2:2/128",
          preshared_key: nil
        }
      }

      expected_wall_state = %{
        users: MapSet.new([]),
        rules: MapSet.new([]),
        devices: MapSet.new([%{ip: "10.3.2.2", ip6: "fd00::3:2:2", user_id: user.id}])
      }

      assert :sys.get_state(Events.vpn_pid()) == expected_vpn_state
      assert :sys.get_state(Events.wall_pid()) == expected_wall_state
    end

    test "device delete removes device from vpn and wall state", %{device: device} do
      Notifier.handle_event("devices", %{op: "INSERT", row: device})
      Notifier.handle_event("devices", %{op: "DELETE", row: device})

      expected_vpn_state = %{}

      expected_wall_state = %{
        users: MapSet.new([]),
        rules: MapSet.new([]),
        devices: MapSet.new([])
      }

      assert :sys.get_state(Events.vpn_pid()) == expected_vpn_state
      assert :sys.get_state(Events.wall_pid()) == expected_wall_state
    end
  end
end
