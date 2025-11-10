defmodule HackathonApp.Adapter.InterfazConsolaProyectos do
  @moduledoc "Menú mínimo para registrar proyecto, avances y consultas."
  alias HackathonApp.Service.ProyectoServicio

  def iniciar do
    HackathonApp.Guard.ensure_role!("participante")
    IO.puts("\n=== Proyectos ===")
    IO.puts("1) Registrar idea")
    IO.puts("2) Cambiar estado")
    IO.puts("3) Agregar avance")
    IO.puts("4) Listar por categoría")
    IO.puts("5) Listar por estado")
    IO.puts("6) Suscribirse a avances (tiempo real)")
    IO.puts("0) Volver")

    case ask("> ") do
      "1" ->
        registrar()
        iniciar()

      "2" ->
        estado()
        iniciar()

      "3" ->
        avance()
        iniciar()

      "4" ->
        por_categoria()
        iniciar()

      "5" ->
        por_estado()
        iniciar()

      "6" ->
        sub_avances()
        iniciar()

      "0" ->
        :ok

      _ ->
        IO.puts("Opción inválida")
        iniciar()
    end
  end

  defp registrar do
    u = HackathonApp.Session.current()

    case u do
      nil ->
        IO.puts("No hay sesión activa. Inicia sesión primero.")

      %{rol: "participante"} ->
        tit = ask("Título del proyecto: ")
        cat = ask("Categoría: ")

        # El equipo_id se obtiene del usuario logueado (si lo tienes asociado)
        # Si cada participante pertenece a un equipo, busca ese equipo
        case HackathonApp.Service.EquipoServicio.buscar_equipo_por_usuario(u.id) do
          nil ->
            IO.puts(
              "No se encontró un equipo asociado a tu usuario. Únete a uno antes de registrar un proyecto."
            )

          %{id: equipo_id} ->
            case HackathonApp.Service.ProyectoServicio.crear(equipo_id, tit, cat) do
              {:ok, p} -> print_proyecto_creado(p)
              {:error, m} -> IO.puts("Error: " <> m)
            end
        end

      _ ->
        IO.puts("Solo los participantes pueden registrar proyectos.")
    end
  end

  defp estado do
    id = ask_int("Proyecto ID: ")
    e = ask("Estado (idea|en_progreso|entregado): ")
    IO.inspect(ProyectoServicio.cambiar_estado(id, e))
  end

  defp avance do
    id = ask_int("Proyecto ID: ")
    txt = ask("Avance: ")
    IO.inspect(ProyectoServicio.agregar_avance(id, txt))
  end

  defp por_categoria do
    cat = ask("Categoría: ")
    listar(ProyectoServicio.filtrar_por_categoria(cat))
  end

  defp por_estado do
    est = ask("Estado (idea|en_progreso|entregado): ")
    listar(ProyectoServicio.filtrar_por_estado(est))
  end

  defp sub_avances do
    id = ask_int("Proyecto ID a suscribirse: ")
    ProyectoStream.suscribirse(id)
    IO.puts("Suscrito. Esperando avances... (Ctrl+C para salir)")
    loop_listen()
  end

  defp loop_listen do
    receive do
      {:avance, a} ->
        IO.puts("[#{a.fecha_iso}] +#{a.proyecto_id}: #{a.contenido}")
        loop_listen()
    after
      60_000 ->
        IO.puts("Sin novedades...")
        loop_listen()
    end
  end

  defp listar(lista) do
    Enum.each(lista, fn p ->
      IO.puts(
        "##{p.id} [eq=#{p.equipo_id}] #{p.titulo} (#{p.categoria}) - #{p.estado} @ #{p.fecha_registro}"
      )
    end)
  end

  defp ask(p),
    do:
      (
        IO.write(p)
        IO.gets("") |> to_str()
      )

  defp print_proyecto_creado(p) do
    IO.puts("\nProyecto registrado correctamente.")
    IO.puts("ID: #{p.id}")
    IO.puts("Equipo ID: #{p.equipo_id}")
    IO.puts("Título: #{p.titulo}")
    IO.puts("Categoría: #{p.categoria}")
    IO.puts("Estado inicial: #{p.estado}")
    IO.puts("Fecha de registro: #{p.fecha_registro}\n")
  end

  defp print_proyecto(titulo, p) do
    IO.puts("\n#{titulo}.")
    IO.puts("ID: #{p.id}")
    IO.puts("Equipo ID: #{p.equipo_id}")
    IO.puts("Título: #{p.titulo}")
    IO.puts("Categoría: #{p.categoria}")
    IO.puts("Estado: #{p.estado}")
    IO.puts("Fecha de registro: #{p.fecha_registro}\n")
  end

  defp ask_int(p), do: ask(p) |> String.to_integer()
  defp to_str(nil), do: ""
  defp to_str(s), do: String.trim(to_string(s))
end
