defmodule HackathonApp.Adapter.SalasTematicas do
  @moduledoc """
  Gestor de salas temáticas de chat.

  - suscribirse/1     -> el proceso actual se suscribe a una sala (string)
  - publicar/3        -> envía mensaje a una sala

  Los procesos suscritos reciben:
    {:sala_msg, sala, %{usuario: nombre, texto: texto, fecha_iso: fecha}}
  """

  use GenServer
  @nombre :salas_tematicas

  ## ========= API PÚBLICA =========

  def start_link(_args \\ []) do
    GenServer.start_link(__MODULE__, %{salas: %{}}, name: @nombre)
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

  @doc "Suscribe el proceso actual a la sala dada (string)."
  def suscribirse(sala) when is_binary(sala) do
    with {:ok, _} <- ensure_started() do
      sala = normalizar(sala)
      send(@nombre, {:suscribir, self(), sala})
      :ok
    end
  end

  @doc "Publica un mensaje en la sala."
  def publicar(sala, usuario, texto)
      when is_binary(sala) and is_binary(usuario) and is_binary(texto) do
    with {:ok, _} <- ensure_started() do
      sala = normalizar(sala)
      fecha = DateTime.utc_now() |> DateTime.to_iso8601()

      payload = %{usuario: usuario, texto: texto, fecha_iso: fecha}
      send(@nombre, {:mensaje, sala, payload})
      :ok
    end
  end

  ## ========= Callbacks =========

  @impl true
  def init(state) do
    Process.flag(:trap_exit, true)
    {:ok, state}
  end

  # suscribir a sala
  @impl true
  def handle_info({:suscribir, pid, sala}, %{salas: salas} = state) do
    Process.monitor(pid)
    subs_prev = Map.get(salas, sala, [])
    subs = Enum.uniq([pid | subs_prev])
    {:noreply, %{state | salas: Map.put(salas, sala, subs)}}
  end

  # difundir mensaje a suscriptores de esa sala
  @impl true
  def handle_info({:mensaje, sala, payload}, %{salas: salas} = state) do
    subs = Map.get(salas, sala, [])

    Enum.each(subs, fn pid ->
      send(pid, {:sala_msg, sala, payload})
    end)

    {:noreply, state}
  end

  # limpiar pids muertos de todas las salas
  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, %{salas: salas} = state) do
    nuevas =
      salas
      |> Enum.map(fn {sala, subs} -> {sala, Enum.reject(subs, &(&1 == pid))} end)
      |> Enum.into(%{})

    {:noreply, %{state | salas: nuevas}}
  end

  @impl true
  def handle_info(_msg, state), do: {:noreply, state}

  defp normalizar(sala),
    do: sala |> String.downcase() |> String.trim()
end
