defmodule FzHttpWeb.ConnectivityCheckLive.IndexTest do
  use FzHttpWeb.ConnCase, async: true

  describe "authenticated/connectivity_checks list" do
    setup :create_connectivity_checks

    test "show connectivity checks", %{
      admin_conn: conn,
      connectivity_checks: connectivity_checks
    } do
      path = ~p"/diagnostics/connectivity_checks"
      {:ok, _view, html} = live(conn, path)

      for connectivity_check <- connectivity_checks do
        assert html =~ DateTime.to_iso8601(connectivity_check.inserted_at)
      end
    end
  end

  describe "unauthenticated/connectivity_checks list" do
    test "mount redirects to session path", %{unauthed_conn: conn} do
      path = ~p"/diagnostics/connectivity_checks"
      expected_path = ~p"/"
      assert {:error, {:redirect, %{to: ^expected_path}}} = live(conn, path)
    end
  end
end
