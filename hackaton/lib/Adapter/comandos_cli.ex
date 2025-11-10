defmodule HackathonApp.Adapter.ComandosCLI do
  @moduledoc """
  Intérprete de comandos tipo slash:
    /teams
    /project <nombre_equipo>
    /join <nombre_equipo>
    /chat <nombre_equipo>
    /help
    /exit
  """

  alias HackathonApp.Session
  alias HackathonApp.Service.{EquipoServicio, ProyectoServicio, Autorizacion}
  alias HackathonApp.Adapter.AvancesCliente

  # ===== Entrada principal =====
  def iniciar do
    case Session.current() do
      nil ->
        IO.puts("No hay sesión. Inicia sesión primero.")

      %{nombre: n, rol: r} ->
        IO.puts("\n=== MODO COMANDOS ===")
        IO.puts("Usuario: #{n} (rol=#{r}). Escribe /help para ver los comandos. /exit para salir.")
        loop()
    end
  end

  defp loop do
    case IO.gets("> ") do
      :eof ->
        IO.puts("\n[Entrada cerrada]")
        :ok

      nil ->
        IO.puts("\n[Entrada nula]")
        loop()

      data ->
        data
        |> to_str()
        |> dispatch()

        loop()
    end
  end

  # ===== Router de comandos =====
  defp dispatch(""), do: :ok
  defp dispatch("/help"), do: print_help()
  defp dispatch("/exit"), do: System.halt(0)

  defp dispatch("/teams") do
    with_guard(:ver_equipos, fn ->
      equipos = EquipoServicio.listar_todos()

      if equipos == [] do
        IO.puts("(No hay equipos)")
      else
        IO.puts("\n--- Equipos ---")
        Enum.each(equipos, fn e ->
          miembros = EquipoServicio.listar_miembros_por_id(e.id) |> length()
          estado = if e.activo, do: "activo", else: "inactivo"
          IO.puts("• #{e.nombre} (id=#{e.id}, #{estado}, miembros=#{miembros})")
        end)
      end
    end)
  end

  defp dispatch(<<"/project ", rest::binary>>) do
    with_guard(:ver_proyecto, fn ->
      nombre_eq = String.trim(rest)

      case ProyectoServicio.buscar_por_equipo(nombre_eq) do
        nil ->
          IO.puts("No hay proyecto asociado al equipo \"#{nombre_eq}\".")

        p ->
          IO.puts("\nProyecto del equipo #{nombre_eq}:")
          IO.puts("  [#{p.id}] #{p.titulo}")
          IO.puts("  categoría: #{p.categoria}")
          IO.puts("  estado:    #{p.estado}")
          IO.puts("  creado:    #{p.fecha_registro}")
      end
    end)
  end

  defp dispatch(<<"/join ", rest::binary>>) do
    nombre_eq = String.trim(rest)

    case Session.current() do
      nil ->
        IO.puts("No hay sesión activa.")

      %{id: uid, rol: rol} ->
        # Permisos: participante puede; organizador también (si lo deseas ya tiene todos los permisos)
        if Autorizacion.can?(rol, :unir_usuario) or rol in ["participante", "organizador"] do
          case EquipoServicio.unirse_a_equipo(nombre_eq, uid) do
            {:ok, _} -> IO.puts("Te uniste al equipo \"#{nombre_eq}\".")
            {:error, m} -> IO.puts("No se pudo unir: #{m}")
          end
        else
          IO.puts("Acceso denegado para /join.")
        end
    end
  end

  defp dispatch(<<"/chat ", rest::binary>>) do
    # Implementación simple: usa el canal de avances como “chat” de equipo/proyecto.
    # Si quisieras salas reales, se puede expandir a otro GenServer (ChatServidor).
    nombre_eq = String.trim(rest)

    with %{rol: rol} <- Session.current(),
         true <- Autorizacion.can?(rol, :ver_proyecto) do
      case ProyectoServicio.buscar_por_equipo(nombre_eq) do
        nil ->
          IO.puts("Ese equipo no tiene proyecto para escuchar mensajes/avances.")

        %{id: proyecto_id} ->
          case AvancesCliente.suscribirse(proyecto_id) do
            :ok ->
              IO.puts("Entraste al canal de #{nombre_eq} (proyecto #{proyecto_id}). Escuchando 20s...")
              escuchar_avances(proyecto_id, 20)

            {:error, reason} ->
              IO.puts("No se pudo entrar al canal: #{inspect(reason)}")
          end
      end
    else
      _ -> IO.puts("Acceso denegado para /chat.")
    end
  end

  defp dispatch(other) when is_binary(other) and String.starts_with?(other, "/") do
    IO.puts("Comando desconocido. Escribe /help.")
  end

  defp dispatch(_free_text) do
    # No comando: texto normal (podrías enviarlo como mensaje si implementas ChatServidor)
    IO.puts("(Escribe /help para ver los comandos)")
  end

  # ===== Helpers =====
  defp print_help do
    IO.puts("""
    Comandos disponibles:
      /teams                         -> Listar equipos registrados
      /project <nombre_equipo>       -> Mostrar información del proyecto de un equipo
      /join <nombre_equipo>          -> Unirse a un equipo
      /chat <nombre_equipo>          -> Entrar al canal del equipo (escucha de avances)
      /help                          -> Mostrar esta ayuda
      /exit                          -> Salir
    """)
  end

  defp to_str(nil), do: ""
  defp to_str(s), do: s |> to_string() |> String.trim()

  defp escuchar_avances(_proyecto_id, segundos) when segundos <= 0 do
    IO.puts("Fin del chat/escucha.")
  end

  defp escuchar_avances(proyecto_id, segundos) do
    receive do
      {:avance, a} ->
        t = a[:timestamp] || a[:fecha_iso] || "-"
        msg = a[:mensaje] || a[:contenido] || "(sin contenido)"
        IO.puts("[#{t}] (proy #{proyecto_id}) #{msg}")
        escuchar_avances(proyecto_id, segundos)
    after
      1_000 ->
        escuchar_avances(proyecto_id, segundos - 1)
    end
  end

  # Ejecuta una función solo si el rol actual tiene el permiso dado
  defp with_guard(permiso, fun) when is_function(fun, 0) do
    case Session.current() do
      nil ->
        IO.puts("No hay sesión activa.")

      %{rol: rol} ->
        if Autorizacion.can?(rol, permiso) do
          fun.()
        else
          IO.puts("Acceso denegado (permiso requerido: #{permiso}).")
        end
    end
  end
end
