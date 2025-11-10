defmodule HackathonApp.Adapter.ComandosCLI do
  @moduledoc """
  Intérprete de comandos tipo slash (global).
  /teams, /project <equipo>, /join <equipo>, /chat <equipo>, /help, /exit
  """

  alias HackathonApp.Session
  alias HackathonApp.Service.{EquipoServicio, ProyectoServicio}
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
      :eof -> IO.puts("\n[Entrada cerrada]"); :ok
      nil -> IO.puts("\n[Entrada nula]"); loop()
      data -> data |> String.trim() |> dispatch(); loop()
    end
  end

  # ===== Router de comandos =====
  defp dispatch(""), do: :ok
  defp dispatch("/help"), do: print_help()
  defp dispatch("/exit"), do: System.halt(0)

  # --- /teams ---
  defp dispatch("/teams") do
    IO.puts("\n--- Equipos registrados ---")
    EquipoServicio.listar_todos()
    |> Enum.each(fn e ->
      IO.puts("• #{e.nombre} (id=#{e.id}, activo=#{e.activo})")
    end)
  end

  # --- /project nombre_equipo ---
  defp dispatch(<<"/project ", rest::binary>>) do
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
  end

  # --- /join equipo ---
  defp dispatch(<<"/join ", rest::binary>>) do
    nombre_eq = String.trim(rest)
    case Session.current() do
      %{id: uid, rol: "participante"} ->
        case EquipoServicio.unirse_a_equipo(nombre_eq, uid) do
          {:ok, _} -> IO.puts("Te uniste al equipo \"#{nombre_eq}\".")
          {:error, m} -> IO.puts("No se pudo unir: #{m}")
        end
      %{rol: r} ->
        IO.puts("Acceso denegado: el rol #{r} no puede unirse a equipos.")
      _ ->
        IO.puts("No hay sesión activa.")
    end
  end

  # --- /chat equipo ---
  defp dispatch(<<"/chat ", rest::binary>>) do
    nombre_eq = String.trim(rest)
    case Session.current() do
      %{rol: "participante"} ->
        case ProyectoServicio.buscar_por_equipo(nombre_eq) do
          nil ->
            IO.puts("Ese equipo no tiene proyecto o no existe.")
          %{id: proyecto_id} ->
            case AvancesCliente.suscribirse(proyecto_id) do
              :ok ->
                IO.puts("Entraste al canal de #{nombre_eq}. Escuchando 15s...")
                escuchar_avances(proyecto_id, 15)
              {:error, r} ->
                IO.puts("Error al entrar al canal: #{inspect(r)}")
            end
        end
      %{rol: r} ->
        IO.puts("Acceso denegado: el rol #{r} no puede usar /chat.")
      _ ->
        IO.puts("No hay sesión activa.")
    end
  end

  # --- Comando desconocido ---
  defp dispatch(<< ?/, _::binary >>), do: IO.puts("Comando desconocido. Usa /help.")
  defp dispatch(_text), do: IO.puts("(Escribe /help para ver los comandos)")

  # ===== Helpers =====
  defp print_help do
    IO.puts("""
    Comandos disponibles:
      /teams                  -> Listar equipos registrados
      /project <nombre>       -> Ver proyecto de un equipo
      /join <nombre_equipo>   -> Unirse a un equipo (solo participantes)
      /chat <nombre_equipo>   -> Entrar al canal de chat (solo participantes)
      /help                   -> Mostrar esta ayuda
      /exit                   -> Salir
    """)
  end

  defp escuchar_avances(_proyecto_id, 0), do: IO.puts("Fin del chat.")
  defp escuchar_avances(proyecto_id, segundos) do
    receive do
      {:avance, a} ->
        msg = a[:mensaje] || a[:contenido] || "(sin contenido)"
        IO.puts("[#{a[:fecha_iso] || "-"}] (proy #{proyecto_id}) #{msg}")
        escuchar_avances(proyecto_id, segundos)
    after
      1_000 -> escuchar_avances(proyecto_id, segundos - 1)
    end
  end
end
