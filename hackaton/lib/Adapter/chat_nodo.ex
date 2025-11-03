defmodule Adapter.ChatNodo do
  @moduledoc "Servidor y cliente para chat distribuido entre PCs usando nodos de Elixir."
  # Nombre del proceso registrado en el servidor
  @nombre_servicio :servicio_chat

  ## === SERVIDOR (PC A) ===
  def iniciar_servidor() do
    # registra el proceso local
    Process.register(self(), @nombre_servicio)
    IO.puts("Servidor de chat iniciado: #{inspect(Node.self())} - #{@nombre_servicio}")
    loop_servidor()
  end

  defp loop_servidor do
    receive do
      {origen, {:mensaje, mapa}} when is_map(mapa) ->
        # reenviar respuesta al originador
        send(origen, {:ok, "recibido: #{mapa.texto}"})
        loop_servidor()

      {origen, :fin} ->
        send(origen, :fin)

      _otro ->
        loop_servidor()
    end
  end

  ## === CLIENTE (PC B) ===
  # nodo_servidor: :"nodoservidor@servidor"  (debe coincidir con --sname del servidor)
  def conectar(nodo_servidor) do
    # true/false
    Node.connect(nodo_servidor)
  end

  def enviar_mensaje(nodo_servidor, mapa_mensaje) do
    # Tupla {nombre_registrado, nodo} para enviar al proceso remoto
    pid_destino = {@nombre_servicio, nodo_servidor}
    send(pid_destino, {self(), {:mensaje, mapa_mensaje}})
    recibir_respuesta()
  end

  def terminar(nodo_servidor) do
    pid_destino = {@nombre_servicio, nodo_servidor}
    send(pid_destino, {self(), :fin})
    recibir_respuesta()
  end

  defp recibir_respuesta do
    receive do
      {:ok, texto} -> {:ok, texto}
      :fin -> :fin
      otro -> {:desconocido, otro}
    after
      3_000 -> {:error, :timeout}
    end
  end
end
