defmodule FzHttpWeb.SettingLive.SAMLFormComponent do
  @moduledoc """
  Form for SAML configs
  """
  use FzHttpWeb, :live_component

  alias FzHttp.Configurations, as: Conf

  def render(assigns) do
    ~H"""
    <div>
    <.form let={f} for={@changeset} autocomplete="off" id="saml-form" phx-target={@myself} phx-submit="save">
      <div class="field">
        <%= label f, :id, "Config ID", class: "label" %>

        <div class="control">
          <%= text_input f, :id,
              class: "input #{input_error_class(f, :id)}" %>
        </div>
        <p class="help is-danger">
          <%= error_tag f, :id %>
        </p>
        <p class="help">
          ID used for generating auth URLs.
        </p>
      </div>

      <hr>

      <div class="field">
        <%= label f, :label, class: "label" %>

        <div class="control">
          <%= text_input f, :label,
              class: "input #{input_error_class(f, :label)}" %>
        </div>
        <p class="help is-danger">
          <%= error_tag f, :label %>
        </p>
        <p class="help">
          Sign in button text.
        </p>
      </div>

      <hr>

      <div class="field">
        <%= label f, :base_url, "Base URL", class: "label" %>

        <div class="control">
          <%= text_input f, :base_url,
              class: "input #{input_error_class(f, :base_url)}" %>
        </div>
        <p class="help is-danger">
          <%= error_tag f, :base_url %>
        </p>
        <p class="help">
          Base URL for the ACS URL. in most cases this shouldn't be changed.
        </p>
      </div>

      <hr>

      <div class="field">
        <%= label f, :metadata, class: "label" %>

        <div class="control">
          <%= textarea f, :metadata,
              rows: 8,
              class: "textarea #{input_error_class(f, :metadata)}" %>
        </div>
        <p class="help is-danger">
          <%= error_tag f, :metadata %>
        </p>
        <p class="help">
          IdP metadata XML.
        </p>
      </div>

      <hr>

      <div class="field">
        <strong>Sign requests</strong>

        <div class="level">
          <div class="level-left">
            <p class="help">Sign SAML requests with your SAML private key.</p>
            <p class="help is-danger">
              <%= error_tag f, :sign_requests %>
            </p>
          </div>
          <div class="level-right">
            <%= label f, :sign_requests, class: "switch is-medium" do %>
              <%= checkbox f, :sign_requests %>
              <span class="check"></span>
            <% end %>
          </div>
        </div>
      </div>

      <hr>

      <div class="field">
        <strong>Sign metadata</strong>

        <div class="level">
          <div class="level-left">
            <p class="help">Sign SAML metadata with your SAML private key.</p>
            <p class="help is-danger">
              <%= error_tag f, :sign_metadata %>
            </p>
          </div>
          <div class="level-right">
            <%= label f, :sign_metadata, class: "switch is-medium" do %>
              <%= checkbox f, :sign_metadata %>
              <span class="check"></span>
            <% end %>
          </div>
        </div>
      </div>

      <hr>

      <div class="field">
        <strong>Require signed assertions</strong>

        <div class="level">
          <div class="level-left">
            <p class="help">Require assertions from your IdP to be signed.</p>
            <p class="help is-danger">
              <%= error_tag f, :signed_assertion_in_resp %>
            </p>
          </div>
          <div class="level-right">
            <%= label f, :signed_assertion_in_resp, class: "switch is-medium" do %>
              <%= checkbox f, :signed_assertion_in_resp %>
              <span class="check"></span>
            <% end %>
          </div>
        </div>
      </div>

      <hr>

      <div class="field">
        <strong>Require signed envelopes</strong>

        <div class="level">
          <div class="level-left">
            <p class="help">Require envelopes from your IdP to be signed.</p>
            <p class="help is-danger">
              <%= error_tag f, :signed_envelopes_in_resp %>
            </p>
          </div>
          <div class="level-right">
            <%= label f, :signed_envelopes_in_resp, class: "switch is-medium" do %>
              <%= checkbox f, :signed_envelopes_in_resp %>
              <span class="check"></span>
            <% end %>
          </div>
        </div>
      </div>

      <hr>

      <div class="field">
        <strong>Auto-create users</strong>

        <div class="level">
          <div class="level-left">
            <p class="help">Automatically create users when signing in for the first time.</p>
            <p class="help is-danger">
              <%= error_tag f, :auto_create_users %>
            </p>
          </div>
          <div class="level-right">
            <%= label f, :auto_create_users, class: "switch is-medium" do %>
              <%= checkbox f, :auto_create_users %>
              <span class="check"></span>
            <% end %>
          </div>
        </div>
      </div>

    </.form>
    </div>
    """
  end

  def update(assigns, socket) do
    external_url = Application.fetch_env!(:fz_http, :external_url)

    changeset =
      assigns.providers
      |> Map.get(assigns.provider_id, %{})
      |> Map.merge(%{
        "id" => assigns.provider_id,
        "base_url" => Path.join(external_url, "/auth/saml")
      })
      |> FzHttp.Conf.SAMLConfig.changeset()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  def handle_event("save", %{"saml_config" => params}, socket) do
    changeset =
      params
      |> FzHttp.Conf.SAMLConfig.changeset()
      |> Map.put(:action, :validate)

    update =
      case changeset do
        %{valid?: true} ->
          changeset
          |> Ecto.Changeset.apply_changes()
          |> Map.from_struct()
          |> Map.new(fn {k, v} -> {to_string(k), v} end)
          |> then(fn data ->
            {id, data} = Map.pop(data, "id")

            %{
              saml_identity_providers:
                socket.assigns.providers
                |> Map.delete(socket.assigns.provider_id)
                |> Map.put(id, data)
            }
          end)
          |> Conf.update_configuration()

        _ ->
          {:error, changeset}
      end

    case update do
      {:ok, config} ->
        Application.fetch_env!(:samly, Samly.Provider)
        |> FzHttp.SAML.StartProxy.set_identity_providers(config.saml_identity_providers)
        |> FzHttp.SAML.StartProxy.refresh()

        {:noreply,
         socket
         |> put_flash(:info, "Updated successfully.")
         |> redirect(to: socket.assigns.return_to)}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end
end
