# CommandAdapter: Adaptador para procesar comandos de usuario.
# Relaciones:
# - Usado por ComandoServicio para ejecutar comandos
# - Interactúa con ChatAdapter para comandos de chat
defmodule HackathonApp.Adaptadores.CommandAdapter do
  alias HackathonApp.Dominios.Comando
  alias HackathonApp.Servicios.{EquipoServicio, ProyectoServicio, ChatServicio}

  def procesar(input, usuario_id) do
    case Comando.parse(input) do
      {:ok, "help", _} ->
        listar_comandos()

      {:ok, "teams", _} ->
        {:ok, formatear_equipos(EquipoServicio.listar_equipos())}

      {:ok, "join", nombre_equipo} ->
        case EquipoServicio.unirse_a_equipo(nombre_equipo, usuario_id) do
          {:ok, equipo} -> {:ok, "Te has unido al equipo #{equipo.nombre}"}
          {:error, msg} -> {:error, msg}
        end

      {:ok, "project", nombre_equipo} ->
        case ProyectoServicio.buscar_por_equipo(nombre_equipo) do
          nil -> {:error, "No hay proyecto registrado para el equipo #{nombre_equipo}"}
          proyecto -> {:ok, formatear_proyecto(proyecto)}
        end

      {:ok, "chat", nombre_equipo} ->
        ChatServicio.conectar_a_canal(nombre_equipo, usuario_id)

      {:error, msg} ->
        {:error, msg}
    end
  end

  defp listar_comandos do
    comandos = Comando.listar_comandos()
    |> Enum.map(fn {cmd, desc} -> "/#{cmd} - #{desc}" end)
    |> Enum.join("\\n")
    {:ok, "Comandos disponibles:\\n#{comandos}"}
  end

  defp formatear_equipos(equipos) do
    equipos
    |> Enum.map(&"#{&1.nombre} (#{length(&1.miembros)} miembros)")
    |> Enum.join("\\n")
  end

  defp formatear_proyecto(proyecto) do
    """
    Proyecto: #{proyecto.titulo}
    Equipo: #{proyecto.equipo}
    Categoría: #{proyecto.categoria}
    Registrado: #{proyecto.fecha_registro}
    """
  end
end
