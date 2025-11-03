defmodule HackathonApp.Adaptadores.CommandAdapter do
  @moduledoc """
  Adaptador de comandos de usuario (capa de interfaz).
  Normaliza la entrada, delega en Servicios y formatea salidas.
  """

  alias HackathonApp.Dominios.Comando
  alias HackathonApp.Servicios.{EquipoServicio, ProyectoServicio, ChatServicio}

  @type respuesta :: {:ok, String.t()} | {:error, String.t()}

  @spec procesar(String.t(), integer()) :: respuesta
  def procesar(input, usuario_id) when is_binary(input) do
    input
    |> normalizar()
    |> Comando.parse()
    |> ejecutar(usuario_id)
  end

  # ----------------------
  # Ejecutores por comando
  # ----------------------

  defp ejecutar({:ok, "help", _args}, _uid), do: listar_comandos()

  defp ejecutar({:ok, "teams", _args}, _uid) do
    equipos = EquipoServicio.listar_equipos_con_conteo() # [{nombre, conteo}]
    {:ok, formatear_equipos(equipos)}
  end

  defp ejecutar({:ok, "join", [nombre_equipo]}, uid) do
    case EquipoServicio.unirse_a_equipo(nombre_equipo, uid) do
      {:ok, equipo} -> {:ok, "Te has unido al equipo #{equipo.nombre}"}
      {:error, :ya_miembro} -> {:error, "Ya perteneces a #{nombre_equipo}"}
      {:error, :no_existe} -> {:error, "No existe el equipo #{nombre_equipo}"}
      {:error, motivo} -> {:error, "No fue posible unirte (#{inspect(motivo)})"}
    end
  end

  defp ejecutar({:ok, "project", [nombre_equipo]}, _uid) do
    case ProyectoServicio.buscar_por_equipo(nombre_equipo) do
      nil -> {:error, "No hay proyecto registrado para el equipo #{nombre_equipo}"}
      proyecto -> {:ok, formatear_proyecto(proyecto)}
    end
  end

  # /chat <equipo> <mensaje...>
  defp ejecutar({:ok, "chat", [nombre_equipo | resto]}, uid) do
    mensaje = Enum.join(resto, " ") |> String.trim()
    cond do
      mensaje == "" -> {:error, "Uso: /chat <equipo> <mensaje>"}
      true ->
        case ChatServicio.enviar(nombre_equipo, uid, mensaje) do
          :ok -> {:ok, "Mensaje enviado a #{nombre_equipo}"}
          {:error, :no_equipo} -> {:error, "El equipo #{nombre_equipo} no existe"}
          {:error, :sin_membresia} -> {:error, "No perteneces al equipo #{nombre_equipo}"}
          {:error, otro} -> {:error, "No se pudo enviar (#{inspect(otro)})"}
        end
    end
  end

  defp ejecutar({:error, :desconocido}, _uid), do: {:error, "Comando no reconocido. Usa /help"}
  defp ejecutar({:error, msg}, _uid) when is_binary(msg), do: {:error, msg}
  defp ejecutar(_otra, _uid), do: {:error, "Entrada inválida. Usa /help"}

  # ----------------------
  # Helpers de formato
  # ----------------------

  defp listar_comandos do
    comandos =
      Comando.listar_comandos()
      |> Enum.map(fn {cmd, desc} -> "/#{cmd} - #{desc}" end)
      |> Enum.join("\n")

    {:ok, "Comandos disponibles:\n" <> comandos}
  end

  # espera lista de {nombre, conteo}
  defp formatear_equipos(pares) do
    pares
    |> Enum.map(fn {nombre, conteo} -> "#{nombre} (#{conteo} miembros)" end)
    |> Enum.join("\n")
  end

  defp formatear_proyecto(p) do
    """
    Proyecto: #{p.titulo}
    Equipo: #{p.equipo}
    Categoría: #{p.categoria}
    Estado: #{p.estado}
    Registrado: #{p.fecha_registro}
    """
    |> String.trim_trailing()
  end

  # ----------------------
  # Normalización de input
  # ----------------------

  defp normalizar(input) do
    input
    |> String.trim()
    |> quitar_barra()
  end

  defp quitar_barra("/" <> resto), do: String.downcase(resto)
  defp quitar_barra(otro), do: String.downcase(otro)
end
