defmodule FzHttp.Notifications do
  @moduledoc """
  Notification state for notifications live view.
  """
  use GenServer

  alias Phoenix.PubSub

  alias FzHttpWeb.NotificationsLive

  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @doc """
  Gets a list of current notifications.
  """
  def current, do: GenServer.call(__MODULE__, :current)

  @doc """
  Add a notification.
  """
  def add(notification), do: GenServer.call(__MODULE__, {:add, notification})

  @doc """
  Clear all notifications.
  """
  def clear, do: GenServer.call(__MODULE__, :clear_all)

  @doc """
  Clear the given notification.
  """
  def clear(notification), do: GenServer.call(__MODULE__, {:clear, notification})

  @doc """
  Clear a notification at the given index.
  """
  def clear_at(index), do: GenServer.call(__MODULE__, {:clear_at, index})

  defp broadcast(notifications) do
    PubSub.broadcast(
      FzHttp.PubSub,
      NotificationsLive.Index.topic(),
      {:notifications, notifications}
    )
  end

  @impl GenServer
  def init(notifications) do
    {:ok, notifications}
  end

  @impl GenServer
  def handle_call(:current, _from, notifications) do
    {:reply, notifications, notifications}
  end

  @impl GenServer
  def handle_call({:add, notification}, _from, notifications) do
    new_notifications = [notification | notifications]
    broadcast(new_notifications)

    {:reply, :ok, new_notifications}
  end

  @impl GenServer
  def handle_call(:clear_all, _from, _notifications) do
    broadcast([])

    {:reply, :ok, []}
  end

  @impl GenServer
  def handle_call({:clear, notification}, _from, notifications) do
    new_notifications = Enum.reject(notifications, &(&1 == notification))
    broadcast(new_notifications)

    {:reply, :ok, new_notifications}
  end

  @impl GenServer
  def handle_call({:clear_at, index}, _from, notifications) do
    {_, new_notifications} = List.pop_at(notifications, index)
    broadcast(new_notifications)

    {:reply, :ok, new_notifications}
  end
end
