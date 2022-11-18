defmodule FzHttpWeb.Authentication.ErrorHandler do
  @moduledoc """
  Error Handler module implementation for Guardian.
  """

  use FzHttpWeb, :controller
  alias FzHttpWeb.Authentication
  import FzHttpWeb.ControllerHelpers, only: [root_path_for_role: 1]
  require Logger

  @behaviour Guardian.Plug.ErrorHandler

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {:already_authenticated, _reason}, _opts) do
    user = Authentication.get_current_user(conn)

    conn
    |> redirect(to: root_path_for_role(user.role))
  end

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {:unauthenticated, _reason}, _opts) do
    conn
    |> redirect(to: ~p"/")
  end

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {type, reason}, opts) do
    Logger.warn("""
      ErrorHandler.auth_error: Could not validate user.
      Type: #{type}
      Reason: #{reason}
      Opts: #{opts}
    """)

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(401, to_string(type))
  end
end
