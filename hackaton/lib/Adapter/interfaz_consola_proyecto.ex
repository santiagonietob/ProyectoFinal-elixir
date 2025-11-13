defmodule HackathonApp.Adapter.InterfazConsolaProyectos do
  @moduledoc "Menú para registrar proyectos, gestionar estados, avances y consultas."
  alias HackathonApp.Service.ProyectoServicio
  alias HackathonApp.Service.Autorizacion
  alias HackathonApp.Session

  # ====== ENTRADA ======
  def iniciar do
    case Session.current() do
      nil ->
        IO.puts("No hay sesión. Inicia sesión primero.")

      %{rol: rol} ->
        if Autorizacion.can?(rol, :ver_proyecto) do
          IO.puts("\n=== Proyectos ===")
          IO.puts("1) Registrar idea")
          IO.puts("2) Cambiar estado")
          IO.puts("3) Agregar avance")
          IO.puts("4) Listar por categoría")
          IO.puts("5) Listar por estado")
          IO.puts("6) Suscribirse a avances (tiempo real)")
          IO.puts("7) Modo comandos (/help, /teams, /project...)")
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

            "7" ->
              HackathonApp.Adapter.ComandosCLI.iniciar()
              iniciar()

            "0" ->
              :ok

            _ ->
              IO.puts("Opción inválida")
              iniciar()
          end
        else
          IO.puts("Acceso denegado (no tienes permiso para ver proyectos).")
        end
    end
  end

  # ====== ACCIONES ======
  defp registrar do
    case Session.current() do
      %{id: uid, rol: rol} ->
        if Autorizacion.can?(rol, :registrar_proyecto) do
          tit = ask("Título del proyecto: ")
          cat = ask("Categoría (web|movil|ia|datos|iot|otros): ")

          case HackathonApp.Service.EquipoServicio.buscar_equipo_por_usuario(uid) do
            nil ->
              IO.puts(
                "No se encontró un equipo asociado a tu usuario. Únete a uno antes de registrar un proyecto."
              )

            %{id: equipo_id} ->
              case ProyectoServicio.crear(equipo_id, tit, cat) do
                {:ok, p} -> print_proyecto_creado(p)
                {:error, m} -> IO.puts("Error: " <> m)
              end
          end
        else
          IO.puts("Acceso denegado (no puedes registrar proyectos).")
        end

      _ ->
        IO.puts("No hay sesión activa. Inicia sesión primero.")
    end
  end

  defp estado do
    case Session.current() do
      %{rol: rol} ->
        if Autorizacion.can?(rol, :cambiar_estado_proyecto) do
          id = ask_int("Proyecto ID: ")
          e = normalizar_estado(ask("Estado (idea|en_progreso|entregado) [acepta sinónimos]: "))

          case ProyectoServicio.cambiar_estado(id, e) do
            {:ok, nuevo} -> IO.puts("Estado actualizado a: #{nuevo}")
            {:error, m} -> IO.puts("#{m}")
            otro -> IO.inspect(otro, label: "Respuesta cambiar_estado/2")
          end
        else
          IO.puts("Acceso denegado (no puedes cambiar el estado del proyecto).")
        end

      _ ->
        IO.puts("No hay sesión activa. Inicia sesión primero.")
    end
  end

  defp avance do
    case Session.current() do
      %{rol: rol} ->
        if Autorizacion.can?(rol, :agregar_avance) do
          pid = ask_int("Proyecto ID: ")
          txt = ask("Avance: ")

          case ProyectoServicio.agregar_avance(pid, txt) do
            {:ok, _} -> IO.puts("Avance registrado")
            {:error, m} -> IO.puts("#{m}")
            otro -> IO.inspect(otro, label: "Respuesta agregar_avance/2")
          end
        else
          IO.puts("Acceso denegado (no puedes agregar avances).")
        end

      _ ->
        IO.puts("No hay sesión activa. Inicia sesión primero.")
    end
  end

  defp por_categoria do
    case Session.current() do
      %{rol: rol} ->
        if Autorizacion.can?(rol, :ver_proyecto) do
          cat =
            ask("Categoría (web|movil|ia|datos|iot|otros): ")
            |> String.downcase()
            |> String.trim()

          proyectos = listar_seguro() |> Enum.filter(&(&1.categoria == cat))
          listar(proyectos)
        else
          IO.puts("Acceso denegado.")
        end

      _ ->
        IO.puts("No hay sesión activa. Inicia sesión primero.")
    end
  end

  defp por_estado do
    case Session.current() do
      %{rol: rol} ->
        if Autorizacion.can?(rol, :ver_proyecto) do
          est = normalizar_estado(ask("Estado (idea|en_progreso|entregado): "))
          proyectos = listar_seguro() |> Enum.filter(&(&1.estado == est))
          listar(proyectos)
        else
          IO.puts("Acceso denegado.")
        end

      _ ->
        IO.puts("No hay sesión activa. Inicia sesión primero.")
    end
  end

  # ====== SUSCRIPCIÓN A AVANCES (TIEMPO REAL, SIN BLOQUEAR) ======
  defp sub_avances do
    case Session.current() do
      %{rol: rol} ->
        if Autorizacion.can?(rol, :ver_proyecto) do
          id = ask_int("Proyecto ID a suscribirse: ")

          case HackathonApp.Adapter.AvancesCliente.suscribirse(id) do
            :ok ->
              IO.puts("Suscrito al proyecto #{id}. Esperando avances en tiempo real...\n")
              escuchar_avances(id, 15)

            {:error, m} ->
              IO.puts("Error al suscribirse: #{inspect(m)}")
          end
        else
          IO.puts("Acceso denegado.")
        end

      _ ->
        IO.puts("No hay sesión activa. Inicia sesión primero.")
    end
  end

  # Escucha controlada: consume mensajes por N segundos y luego vuelve al menú.
  defp escuchar_avances(_proyecto_id, segundos_restantes) when segundos_restantes <= 0 do
    IO.puts("\nTiempo de escucha finalizado. Volviendo al menú de proyectos...\n")
  end

  defp escuchar_avances(proyecto_id, segundos_restantes) do
    receive do
      {:avance, a} ->
        t = a[:timestamp] || a[:fecha_iso] || "-"
        msg = a[:mensaje] || a[:contenido] || "(sin contenido)"
        IO.puts("[#{t}] Proyecto ##{proyecto_id}: #{msg}")
        escuchar_avances(proyecto_id, segundos_restantes)

      otro ->
        IO.inspect(otro, label: "Evento recibido")
        escuchar_avances(proyecto_id, segundos_restantes)
    after
      1_000 ->
        escuchar_avances(proyecto_id, segundos_restantes - 1)
    end
  end

  # ====== LISTADO / HELPERS ======
  defp listar(lista) do
    if Enum.empty?(lista) do
      IO.puts("(sin resultados)")
    else
      Enum.each(lista, fn p ->
        IO.puts(
          "##{p.id} [eq=#{p.equipo_id}] #{p.titulo} (#{p.categoria}) - #{p.estado} @ #{p.fecha_registro}"
        )
      end)
    end
  end

  defp listar_seguro do
    case safe_listar() do
      {:ok, xs} when is_list(xs) -> xs
      xs when is_list(xs) -> xs
      _ -> []
    end
  end

  defp safe_listar do
    # Soporta wrapper {:ok, lista} o listar/0 que devuelve lista
    with {:ok, xs} <- try_listar_proyectos() do
      {:ok, xs}
    else
      _ -> ProyectoServicio.listar()
    end
  end

  defp try_listar_proyectos do
    try do
      ProyectoServicio.listar_proyectos()
    rescue
      _ -> {:error, :no_wrapper}
    end
  end

  # ====== INPUT ======
  defp ask(p) do
    IO.write(p)
    IO.gets("") |> to_str()
  end

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

  # ====== NORMALIZACIÓN ======
  # Estados del servicio: idea | en_progreso | entregado
  defp normalizar_estado(s) do
    s
    |> to_str()
    |> String.downcase()
    |> case do
      "en_desarrollo" -> "en_progreso"
      "progreso" -> "en_progreso"
      "done" -> "entregado"
      "completado" -> "entregado"
      # compatibilidad antigua
      "archivado" -> "entregado"
      other -> other
    end
  end
end
