defmodule FzHttpWeb.MFALive.Auth do
  @moduledoc """
  Handles MFA LiveViews.
  """
  use FzHttpWeb, :live_view

  import FzHttpWeb.ControllerHelpers
  alias FzHttp.MFA

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:page_title, "Multi-factor Authentication")}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _uri, socket) do
    changeset = id |> MFA.get_method!() |> MFA.change_method()
    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _uri, socket) do
    changeset =
      socket.assigns.current_user
      |> MFA.most_recent_method()
      |> MFA.change_method()

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl Phoenix.LiveView
  def render(%{live_action: :auth} = assigns) do
    ~H"""
    <h3 class="is-3 title"><%= @page_title %></h3>

    <p>
      Authenticate with your configured MFA method.
    </p>

    <hr>

    <div class="block has-text-right">
      <%= live_patch "Other authenticators ->", to: Routes.mfa_auth_path(@socket, :types) %>
    </div>

    <div class="block">
      <.form let={f} for={@changeset} id="mfa-method-form" phx-submit="verify">

        <div class="field">
          <%= label f, :code, class: "label" %>
          <div class="control">
            <%= text_input f, :code, name: "code", placeholder: "123456", required: true, class: "input #{input_error_class(@changeset, :code)}" %>
            <p class="help is-danger">
              <%= error_tag f, :code %>
            </p>
          </div>
        </div>

        <div class="field">
          <div class="control">
            <div class="level">
              <div class="level-left">
                <%= submit "Verify",
                    phx_disable_with: "verifying...",
                    class: "button" %>
              </div>
              <div class="level-right">
                <%= link(to: Routes.auth_path(@socket, :delete), method: :delete) do %>
                  Sign out
                <% end %>
              </div>
            </div>
          </div>
        </div>
      </.form>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def render(%{live_action: :types} = assigns) do
    assigns = Map.put(assigns, :methods, MFA.list_methods(assigns.current_user))

    ~H"""
    <h3 class="is-3 title"><%= @page_title %></h3>

    <p class="block">
      Select your MFA method:
    </p>

    <div class="block">
      <ul>
        <%= for method <- @methods do %>
        <li>
          <%= live_patch "[#{method.type}] #{method.name} ->",
              to: Routes.mfa_auth_path(@socket, :auth, method.id) %>
        </li>
        <% end %>
      </ul>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def handle_event("verify", %{"code" => code}, socket) do
    case MFA.update_method(socket.assigns.changeset.data, %{code: code}) do
      {:ok, _method} ->
        {:noreply,
         push_redirect(socket,
           to: root_path_for_role(FzHttpWeb.Endpoint, socket.assigns.current_user.role)
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end
end
