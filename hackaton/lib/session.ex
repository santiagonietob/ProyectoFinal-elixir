defmodule HackathonApp.Session do
  @moduledoc "Guarda la sesión actual (usuario logueado) para la CLI."
  use Agent

  defp ensure_started do
    case Process.whereis(__MODULE__) do
      nil -> Agent.start_link(fn -> nil end, name: __MODULE__)
      _pid -> :ok
    end
  end

  @doc "Guarda el usuario actual (mapa con :id, :nombre, :rol)."
  def start(user) when is_map(user) do
    ensure_started()
    Agent.update(__MODULE__, fn _ -> user end)
    :ok
  end

  @doc "Devuelve el usuario actual o nil si no hay sesión."
  def current do
    ensure_started()
    Agent.get(__MODULE__, & &1)
  end

  @doc "Borra la sesión actual."
  def clear do
    ensure_started()
    Agent.update(__MODULE__, fn _ -> nil end)
    :ok
  end
end
