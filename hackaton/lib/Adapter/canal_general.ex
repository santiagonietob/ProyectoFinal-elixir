defmodule HackathonApp.Adapter.CanalGeneral do
  @moduledoc """
  Canal global de anuncios.

  - suscribirse/0  -> el proceso actual recibirá mensajes {:anuncio, mapa}
  - anunciar/2     -> difunde un anuncio a todos los suscriptores

  El mapa de anuncio tiene forma:
    %{autor: nombre, mensaje: texto, fecha_iso: fecha}
  """

  use GenServer
  @nombre :canal_general

  ## ========= API PÚBLICA =========

  def start_link(_args \\ []) do
    GenServer.start_link(__MODULE__, %{subs: []}, name: @nombre)
  end

  @doc "Asegura que el servidor esté corriendo."
  def ensure_started do
    case Process.whereis(@nombre) do
      pid when is_pid(pid) ->
        {:ok, pid}

      nil ->
        case start_link([]) do
          {:ok, pid} -> {:ok, pid}
          {:error, {:already_started, pid}} -> {:ok, pid}
          other -> other
        end
    end
  end

  @doc "El proceso actual se suscribe al canal general."
  def suscribirse do
    with {:ok, _} <- ensure_started() do
      send(@nombre, {:suscribir, self()})
      :ok
    end
  end

  @doc "Envía un anuncio global."
  def anunciar(autor, mensaje) do
    with {:ok, _} <- ensure_started() do
      fecha = DateTime.utc_now() |> DateTime.to_iso8601()

      send(@nombre, {:anuncio, %{autor: autor, mensaje: mensaje, fecha_iso: fecha}})
      :ok
    end
  end

  ## ========= Callbacks =========

  @impl true
  def init(state) do
    Process.flag(:trap_exit, true)
    {:ok, state}
  end

  # registrar suscriptor
  @impl true
  def handle_info({:suscribir, pid}, state) do
    Process.monitor(pid)
    {:noreply, %{state | subs: Enum.uniq([pid | state.subs])}}
  end

  # difundir anuncio
  @impl true
  def handle_info({:anuncio, anuncio}, state) do
    Enum.each(state.subs, fn pid -> send(pid, {:anuncio, anuncio}) end)
    {:noreply, state}
  end

  # limpiar suscriptores muertos
  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    {:noreply, %{state | subs: Enum.reject(state.subs, &(&1 == pid))}}
  end

  @impl true
  def handle_info(_msg, state), do: {:noreply, state}
end
