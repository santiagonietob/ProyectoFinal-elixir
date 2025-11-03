# lib/adapter/avances_cliente.ex
defmodule HackathonApp.Adapter.AvancesCliente do
  @moduledoc "Cliente que se conecta a un nodo remoto y escucha avances en tiempo real."
  @servicio_remoto {:servicio_avances, :nodoservidor@localhost}  # ajusta el nodo

  def suscribirse(remoto_nodo \\ :nodoservidor@localhost) do
    # 1) Conectar con el nodo remoto
    case Node.connect(remoto_nodo) do                           # ⇐ Node.connect/1
      true ->
        send({:servicio_avances, remoto_nodo}, {:suscribir, self()})
        IO.puts("📡 Suscrito a avances en #{inspect remoto_nodo}. Esperando… (Ctrl+C para salir)")
        escuchar()

      false ->
        IO.puts(" No se pudo conectar con #{inspect remoto_nodo}")
    end
  end

  def publicar_avance(avance, remoto_nodo \\ :nodoservidor@localhost) do
    send({:servicio_avances, remoto_nodo}, {:avance, avance})
    :ok
  end

  defp escuchar do
    receive do
      {:avance, a} ->
        IO.puts("[#{a.fecha_iso}] (+#{a.proyecto_id}) #{a.contenido}")
        escuchar()

      :fin ->
        IO.puts("Fin de transmisión")
        :ok
    end
  end
end
