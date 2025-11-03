defmodule HackathonApp.Adapter.ProyectoStream do
  @moduledoc """
  Notificaciones de avances en 'tiempo real' usando :pg (grupos por proyecto).
  - suscribirse(proyecto_id): procesa mensajes {:avance, %Avance{}}
  - publicar_avance(proyecto_id, avance): envía a todos los suscriptores
  """
  @group_ns :proyecto_avances

  @spec suscribirse(integer()) :: :ok
  def suscribirse(proyecto_id) do
    :pg.join(@group_ns, clave(proyecto_id), self())
    :ok
  end

  @spec publicar_avance(integer(), any()) :: :ok
  def publicar_avance(proyecto_id, avance) do
    for pid <- :pg.get_members(@group_ns, clave(proyecto_id)) do
      send(pid, {:avance, avance})
    end

    :ok
  end

  defp clave(id), do: {:proyecto, id}
end
