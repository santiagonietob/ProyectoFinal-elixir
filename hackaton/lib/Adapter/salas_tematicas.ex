defmodule HackathonApp.Adapter.SalasTematicas do
  @moduledoc """
  Gestor de salas temáticas de chat (distribuido).

  - suscribirse/1     -> el proceso actual se suscribe a una sala (string)
  - publicar/3        -> envía mensaje a una sala

  Los procesos suscritos reciben:
    {:sala_msg, sala, %{usuario: nombre, texto: texto, fecha_iso: fecha}}

  El servidor de salas vive en el nodo: nodoservidor@192.168.1.28
  """

  use GenServer

  @nombre :salas_tematicas
  @nodo_servidor :"nodoservidor@192.168.1.28"

  ## ========= API PÚBLICA =========

  def start_link(_args \\ []) do
    GenServer.start_link(__MODULE__, %{salas: %{}}, name: @nombre)
  end

  @doc """
  Asegura que el servidor de salas esté disponible.

  - En el nodo servidor (`@nodo_servidor`): arranca el GenServer local si no existe.
  - En otros nodos: se conecta al servidor y le pide, vía RPC, que haga lo mismo.
  """
  def ensure_started, do: ensure_started(node())

  # Versión que corre en el nodo servidor
  defp ensure_started(@nodo_servidor) do
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

  # Versión que corre en cualquier otro nodo (cliente)
  defp ensure_started(_otra_maquina) do
    case Node.connect(@nodo_servidor) do
      true ->
        :rpc.call(@nodo_servidor, __MODULE__, :ensure_started, [])

      false ->
        {:error, :no_se_pudo_conectar_nodo_servidor}
    end
  end

  @doc "Suscribe el proceso actual a la sala dada (string)."
  def suscribirse(sala) when is_binary(sala) do
    case ensure_started() do
      {:ok, _} ->
        sala = normalizar(sala)
        destino = destino()
        send(destino, {:suscribir, self(), sala})
        :ok

      error ->
        # Si quieres, elimina esta línea para que ni siquiera muestre errores
        IO.puts("No se pudo suscribir a salas: #{inspect(error)}")
        error
    end
  end

  @doc "Publica un mensaje en la sala."
  def publicar(sala, usuario, texto)
      when is_binary(sala) and is_binary(usuario) and is_binary(texto) do
    case ensure_started() do
      {:ok, _} ->
        sala = normalizar(sala)
        fecha = DateTime.utc_now() |> DateTime.to_iso8601()

        payload = %{usuario: usuario, texto: texto, fecha_iso: fecha}
        destino = destino()
        send(destino, {:mensaje, sala, payload})
        :ok

      error ->
        IO.puts("No se pudo publicar en salas: #{inspect(error)}")
        error
    end
  end

  def publicar(_, _, _), do: {:error, :parametros_invalidos}

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

  # ========= Helpers internos =========

  defp destino do
    if node() == @nodo_servidor do
      @nombre
    else
      {@nombre, @nodo_servidor}
    end
  end

  defp normalizar(sala),
    do: sala |> String.downcase() |> String.trim()
end
