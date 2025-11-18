defmodule HackathonApp.Adapter.AvancesCliente do
  @moduledoc """
  Cliente para suscribirse y publicar avances en tiempo real.

  - `suscribirse/1` (proyecto_id) registra el proceso actual para recibir `{:avance, mapa}`.
  - `publicar_avance/2` (proyecto_id, mapa) difunde el avance.
  - Si no hay nodo distribuido/servicio remoto, usa servidor local (:servicio_avances).
  - NO bloquea; la UI se encarga del loop `receive`.
  """

  # {proceso_remoto_registrado, nodo_remoto}
  @servicio_remoto {:servicio_avances, :"nodoservidor@192.168.11.103"}
  @nombre_local :servicio_avances

  @spec suscribirse(non_neg_integer(), pid()) :: :ok | {:error, term()}
  def suscribirse(proyecto_id, pid \\ self())
      when is_integer(proyecto_id) and proyecto_id > 0 and is_pid(pid) do
    case conectar_remoto(elem(@servicio_remoto, 1)) do
      :ok ->
        send({elem(@servicio_remoto, 0), elem(@servicio_remoto, 1)}, {:suscribir, pid})
        :ok

      :error ->
        with :ok <- HackathonApp.Adapter.AvancesServidor.ensure_started() do
          send(@nombre_local, {:suscribir, pid})
          :ok
        else
          {:error, reason} -> {:error, reason}
        end
    end
  end

  def suscribirse(other, _pid), do: {:error, {:proyecto_id_invalido, other}}

  @spec publicar_avance(non_neg_integer(), map()) :: :ok | {:error, term()}
  def publicar_avance(proyecto_id, avance) when is_integer(proyecto_id) and is_map(avance) do
    avance = Map.put_new(avance, :proyecto_id, proyecto_id)

    case conectar_remoto(elem(@servicio_remoto, 1)) do
      :ok ->
        send({elem(@servicio_remoto, 0), elem(@servicio_remoto, 1)}, {:avance, avance})
        :ok

      :error ->
        with :ok <- HackathonApp.Adapter.AvancesServidor.ensure_started() do
          send(@nombre_local, {:avance, avance})
          :ok
        else
          {:error, reason} -> {:error, reason}
        end
    end
  end

  def publicar_avance(_, _), do: {:error, :parametros_invalidos}

  ## ===== Helpers =====

  # Normaliza Node.connect/1 a :ok | :error (maneja false, :ignored, :pang, etc.)
  defp conectar_remoto(node) when is_atom(node) do
    case Node.connect(node) do
      true -> :ok
      _ -> :error
    end
  end

  defp conectar_remoto(_), do: :error
end
