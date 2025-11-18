defmodule HackathonApp.Adapter.ComandosCLI do
  @moduledoc """
  Intérprete de comandos tipo slash (modo comandos).
  Usa /back para cerrar sesión; /quit para cerrar la app.
  """

  alias HackathonApp.Session
  alias HackathonApp.Service.{EquipoServicio, ProyectoServicio}
  alias HackathonApp.Adapter.AvancesCliente

  # ===== Entrada principal =====
  @doc """
  Inicia el modo comandos. Retorna :back cuando el usuario teclea /back o /salir.
  """
  def iniciar do
    case Session.current() do
      nil ->
        IO.puts("No hay sesión. Inicia sesión primero.")
        :back

      %{nombre: n, rol: r} ->
        IO.puts("\n=== MODO COMANDOS ===")
        IO.puts("Usuario: #{n} (rol=#{r})")
        IO.puts("Escribe /help para ver comandos. Usa /back para cerrar sesión.")
        loop()
    end
  end

  # Bucle principal: devuelve :back para cerrar sesión
  defp loop do
    case IO.gets("> ") do
      :eof ->
        :back

      nil ->
        loop()

      data ->
        case dispatch(String.trim(to_string(data))) do
          :back -> :back
          _ -> loop()
        end
    end
  end

  # ===== Router de comandos (cada dispatch devuelve :cont o :back) =====
  defp dispatch(""), do: :cont

  defp dispatch("/help") do
    IO.puts("""
    Comandos:
      /teams                  -> Listar equipos
      /project <equipo>       -> Ver proyecto de un equipo
      /join <equipo>          -> Unirse a un equipo (solo participantes)
      /chat <equipo>          -> Entrar al canal del equipo (solo participantes, 15s)
      /back | /volver          -> Cerrar sesión
      /exit                   -> Cerrar aplicación
    """)

    :cont
  end

  # salir del modo comandos (cerrar sesión)
  defp dispatch("/back"), do: :back
  defp dispatch("/volver"), do: :back

  # salir de toda la app (opcional)
  defp dispatch("/exit") do
    IO.puts("Cerrando aplicación...")
    System.halt(0)
  end

  defp dispatch("/teams") do
    IO.puts("\n--- Equipos registrados ---")

    EquipoServicio.listar_todos()
    |> Enum.each(fn e ->
      IO.puts("• #{e.nombre} (id=#{e.id}, activo=#{e.activo})")
    end)

    :cont
  end

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

    :cont
  end

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

    :cont
  end

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

    :cont
  end

  # Desconocido: si empieza por '/', avisa; si no, ignora
  defp dispatch(<<?/, _::binary>>),
    do:
      (
        IO.puts("Comando desconocido. Usa /help.")
        :cont
      )

  defp dispatch(_text), do: :cont

  # ===== Helpers =====
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
