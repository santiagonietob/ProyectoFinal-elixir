defmodule HackathonApp.Adapter.SalasTematicas do
  @moduledoc """
  Gestor de salas temáticas de chat (distribuido).

  - suscribirse/1     -> el proceso actual se suscribe a una sala (string)
  - publicar/3        -> envía mensaje a una sala

  Los procesos suscritos reciben:
    {:sala_msg, sala, %{usuario: nombre, texto: texto, fecha_iso: fecha}}

  Se espera que el nodo servidor sea: nodoservidor@192.168.1.28
  y que en ese nodo exista el GenServer registrado como :salas_tematicas.
  """

  use GenServer

  @nombre :salas_tematicas
  @nodo_servidor :"nodoservidor@192.168.1.28"

  ## ========= API PÚBLICA =========

  # En el nodo servidor, puedes arrancarlo desde el árbol de supervisión
  # o de forma lazy con ensure_started/0.
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
        IO.puts("[Salas] Iniciando GenServer local en nodo servidor #{inspect(node())}")

        case start_link([]) do
          {:ok, pid} ->
            IO.puts("[Salas] GenServer :salas_tematicas iniciado en servidor")
            {:ok, pid}

          {:error, {:already_started, pid}} ->
            {:ok, pid}

          other ->
            IO.puts("[Salas] Error al iniciar en servidor: #{inspect(other)}")
            other
        end
    end
  end

  # Versión que corre en cualquier otro nodo (cliente)
  defp ensure_started(_otra_maquina) do
    IO.puts("[Salas] Nodo actual: #{inspect(node())}")
    IO.puts("[Salas] Intentando conectar a #{@nodo_servidor}...")

    case Node.connect(@nodo_servidor) do
      true ->
        IO.puts("[Salas] Conectado a #{@nodo_servidor}. Haciendo RPC ensure_started...")
        :rpc.call(@nodo_servidor, __MODULE__, :ensure_started, [])

      false ->
        IO.puts("[Salas] FALLÓ Node.connect(#{inspect(@nodo_servidor)})")
        {:error, :no_se_pudo_conectar_nodo_servidor}
    end
  end

  @doc "Suscribe el proceso actual a la sala dada (string)."
  def suscribirse(sala) when is_binary(sala) do
    case ensure_started() do
      {:ok, _} ->
        sala = normalizar(sala)
        destino = destino()
        IO.puts("[Salas] Suscribiendo #{inspect(self())} a sala #{sala} en #{inspect(destino)}")

        send(destino, {:suscribir, self(), sala})
        :ok

      error ->
        IO.puts("[Salas] ERROR en suscribirse/1: #{inspect(error)}")
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

        IO.puts("[Salas] Enviando mensaje a sala #{sala} en #{inspect(destino)}")

        send(destino, {:mensaje, sala, payload})
        :ok

      error ->
        IO.puts("[Salas] ERROR en publicar/3: #{inspect(error)}")
        error
    end
  end

  @doc "Publica un mensaje en la sala."
  def publicar(sala, usuario, texto)
      when is_binary(sala) and is_binary(usuario) and is_binary(texto) do
    with {:ok, _} <- ensure_started() do
      sala = normalizar(sala)
      fecha = DateTime.utc_now() |> DateTime.to_iso8601()

      payload = %{usuario: usuario, texto: texto, fecha_iso: fecha}
      destino = destino()

      send(destino, {:mensaje, sala, payload})
      :ok
    end
  end

  # En cualquier otro tipo de parámetro, devuelve error
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

  # En el nodo servidor el destino es el nombre local;
  # en los clientes es el {nombre, nodo_servidor}
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
