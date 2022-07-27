defmodule FzVpn.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FzVpn.Supervisor]
    Supervisor.start_link(children(), opts)
  end

  defp children do
    Application.fetch_env!(:fz_vpn, :supervised_children)
  end
end
