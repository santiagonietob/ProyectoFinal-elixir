defmodule HackathonApp.Adapter.AvancesServidor do
  @moduledoc """
  Servidor que gestiona suscriptores y difunde avances en tiempo real.

  Mensajes esperados:
    {:suscribir, pid}  -> agrega el PID (monitorizado) a la lista de suscriptores.
    {:avance, avance}  -> envía `{:avance, avance}` a todos los suscriptores vivos.
  """

  use GenServer
  @nombre :servicio_avances

  ## ========= API PÚBLICA =========

  @doc """
  Inicia el servidor como GenServer registrado en `@nombre`.
  Pensado para usarse desde el árbol de supervisión.
  """
  def start_link(_args \\ []) do
    GenServer.start_link(__MODULE__, %{subs: []}, name: @nombre)
  end

  @doc """
  Asegura que el servidor esté en ejecución.
  Devuelve :ok si ya estaba o si se pudo arrancar; {:error, razón} en caso contrario.
  """
  @spec ensure_started() :: :ok | {:error, term()}
  def ensure_started do
    case Process.whereis(@nombre) do
      pid when is_pid(pid) ->
        :ok

      nil ->
        case start_link([]) do
          {:ok, _pid} -> :ok
          {:error, {:already_started, _pid}} -> :ok
          {:error, reason} -> {:error, reason}
        end
    end
  end

  ## ========= Callbacks =========

  @impl true
  def init(state) do
    Process.flag(:trap_exit, true)
    {:ok, state}
  end

  @impl true
  def handle_info({:suscribir, pid}, state) when is_pid(pid) do
    Process.monitor(pid)
    {:noreply, %{state | subs: Enum.uniq([pid | state.subs])}}
  end

  @impl true
  def handle_info({:avance, avance}, state) do
    Enum.each(state.subs, fn pid -> send(pid, {:avance, avance}) end)
    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    {:noreply, %{state | subs: Enum.reject(state.subs, &(&1 == pid))}}
  end

  @impl true
  def handle_info(_msg, state), do: {:noreply, state}
end
