defmodule HackathonApp.Adapter.InterfazConsolaProyectos do
  @moduledoc "Menú para registrar proyectos, gestionar estados, avances y consultas."

  alias HackathonApp.Service.ProyectoServicio
  alias HackathonApp.Service.Autorizacion
  alias HackathonApp.Service.EquipoServicio
  alias HackathonApp.Session
  alias HackathonApp.Adapter.AvancesCliente
  alias HackathonApp.Adapter.InterfazConsolaChat
  alias HackathonApp.Adapter.InterfazConsolaEquipos
  alias HackathonApp.Adapter.InterfazConsolaLogin
  alias HackathonApp.Adapter.PersistenciaCSV, as: CSV

  # ====== ENTRADA ======
  def iniciar do
    Process.sleep(300)

    case Session.current() do
      nil ->
        IO.puts(IO.ANSI.yellow() <> "No hay sesión. Inicia sesión primero." <> IO.ANSI.reset())

      %{rol: rol} ->
        if Autorizacion.can?(rol, :ver_proyecto) do
          IO.puts(IO.ANSI.cyan() <> "\n══════════════════════════════════════")
          IO.puts("            PROYECTOS")
          IO.puts("══════════════════════════════════════" <> IO.ANSI.reset() <> "\n")
          IO.puts(IO.ANSI.green() <> "1) Registrar idea" <> IO.ANSI.reset())
          IO.puts(IO.ANSI.green() <> "2) Cambiar estado" <> IO.ANSI.reset())
          IO.puts(IO.ANSI.green() <> "3) Agregar avance" <> IO.ANSI.reset())
          IO.puts(IO.ANSI.green() <> "4) Listar por categoría" <> IO.ANSI.reset())
          IO.puts(IO.ANSI.green() <> "5) Listar por estado" <> IO.ANSI.reset())
          IO.puts(IO.ANSI.green() <> "6) Suscribirse a avances (tiempo real)" <> IO.ANSI.reset())
          IO.puts(IO.ANSI.green() <> "7) Enviar consulta a mentores" <> IO.ANSI.reset())

          IO.puts(
            IO.ANSI.green() <> "8) Modo comandos (/help, /teams, /project...)" <> IO.ANSI.reset()
          )

          IO.puts(IO.ANSI.green() <> "9) Chat en tiempo real (canal general)" <> IO.ANSI.reset())
          IO.puts("10) Menú anterior\n")
          IO.puts(IO.ANSI.green() <> "0) Cerrar sesión" <> IO.ANSI.reset())

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
              consulta_mentores()
              iniciar()

            "8" ->
              HackathonApp.Adapter.ComandosCLI.iniciar()
              iniciar()

            "9" ->
              InterfazConsolaChat.iniciar()
              iniciar()

            "10" ->
              IO.puts("Volviendo al menú anterior...")
              InterfazConsolaEquipos.iniciar()

            "0" ->
              IO.puts(IO.ANSI.green() <> "Hasta pronto!" <> IO.ANSI.reset())
              InterfazConsolaLogin.iniciar()

            _ ->
              IO.puts(IO.ANSI.red() <> "Opción inválida" <> IO.ANSI.reset())
              iniciar()
          end
        else
          IO.puts(
            IO.ANSI.red() <>
              "Acceso denegado (no tienes permiso para ver proyectos)." <> IO.ANSI.reset()
          )
        end
    end
  end

  # ====== ACCIONES ======
  defp registrar do
    case Session.current() do
      %{id: uid, rol: rol} ->
        if Autorizacion.can?(rol, :registrar_proyecto) do
          tit = ask("Título del proyecto: ")
          desc = ask("Descripción de la idea: ")
          cat = ask("Categoría (web|movil|ia|datos|iot|otros): ")

          case EquipoServicio.buscar_equipo_por_usuario(uid) do
            nil ->
              IO.puts(
                IO.ANSI.yellow() <>
                  "No se encontró un equipo asociado a tu usuario. Únete a uno antes de registrar un proyecto." <>
                  IO.ANSI.reset()
              )

            %{id: equipo_id} ->
              case ProyectoServicio.crear(tit, desc, cat, equipo_id) do
                {:ok, p} -> print_proyecto_creado(p, desc)
                {:error, m} -> IO.puts(IO.ANSI.red() <> "Error: " <> m <> IO.ANSI.reset())
              end
          end
        else
          IO.puts(
            IO.ANSI.red() <> "Acceso denegado (no puedes registrar proyectos)." <> IO.ANSI.reset()
          )
        end

      _ ->
        IO.puts(
          IO.ANSI.yellow() <> "No hay sesión activa. Inicia sesión primero." <> IO.ANSI.reset()
        )
    end
  end

  defp estado do
    case Session.current() do
      %{rol: rol} ->
        if Autorizacion.can?(rol, :cambiar_estado_proyecto) do
          id = ask_int("Proyecto ID: ")
          e = normalizar_estado(ask("Estado (idea|en_progreso|entregado) [acepta sinónimos]: "))

          case ProyectoServicio.cambiar_estado(id, e) do
            {:ok, nuevo} ->
              IO.puts(IO.ANSI.green() <> "Estado actualizado a: #{nuevo}" <> IO.ANSI.reset())

            {:error, m} ->
              IO.puts(IO.ANSI.red() <> "#{m}" <> IO.ANSI.reset())

            otro ->
              IO.inspect(otro, label: "Respuesta cambiar_estado/2")
          end
        else
          IO.puts(
            IO.ANSI.red() <>
              "Acceso denegado (no puedes cambiar el estado del proyecto)." <> IO.ANSI.reset()
          )
        end

      _ ->
        IO.puts(
          IO.ANSI.yellow() <> "No hay sesión activa. Inicia sesión primero." <> IO.ANSI.reset()
        )
    end
  end

  defp avance do
    case Session.current() do
      %{rol: rol} ->
        if Autorizacion.can?(rol, :agregar_avance) do
          pid = ask_int("Proyecto ID: ")
          txt = ask("Avance: ")

          case ProyectoServicio.agregar_avance(pid, txt) do
            {:ok, _} -> IO.puts(IO.ANSI.green() <> "Avance registrado" <> IO.ANSI.reset())
            {:error, m} -> IO.puts(IO.ANSI.red() <> "#{m}" <> IO.ANSI.reset())
            otro -> IO.inspect(otro, label: "Respuesta agregar_avance/2")
          end
        else
          IO.puts(
            IO.ANSI.red() <> "Acceso denegado (no puedes agregar avances)." <> IO.ANSI.reset()
          )
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
          IO.puts(IO.ANSI.red() <> "Acceso denegado." <> IO.ANSI.reset())
        end

      _ ->
        IO.puts(
          IO.ANSI.yellow() <> "No hay sesión activa. Inicia sesión primero." <> IO.ANSI.reset()
        )
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

  # ====== CANAL DE CONSULTAS A MENTORES ======
  defp consulta_mentores do
    case Session.current() do
      %{id: uid, rol: rol} ->
        if Autorizacion.can?(rol, :enviar_mensaje) do
          case EquipoServicio.buscar_equipo_por_usuario(uid) do
            nil ->
              IO.puts(
                IO.ANSI.yellow() <>
                  "No se encontró un equipo asociado a tu usuario. Únete a un equipo antes de enviar consultas." <>
                  IO.ANSI.reset()
              )

            %{id: equipo_id, nombre: nombre_eq} ->
              texto = ask("Escribe tu consulta para los mentores: ")
              fecha = DateTime.utc_now() |> DateTime.to_iso8601()

              # mensajes.csv: id,equipo_id,usuario_id,texto,fecha_iso
              fila = [
                "",
                Integer.to_string(equipo_id),
                Integer.to_string(uid),
                limpiar(texto),
                fecha
              ]

              :ok = CSV.agregar("data/mensajes.csv", fila)

              IO.puts(
                IO.ANSI.green() <>
                  "\nConsulta enviada a los mentores para el equipo #{nombre_eq}.\n" <>
                  IO.ANSI.reset()
              )
          end
        else
          IO.puts("No tienes permiso para enviar consultas a mentores.")
        end

      _ ->
        IO.puts("No hay sesión activa. Inicia sesión primero.")
    end
  end

  # ====== SUSCRIPCIÓN A AVANCES (TIEMPO REAL, SIN BLOQUEAR) ======
  defp sub_avances do
    id = ask_int("Proyecto ID a suscribirse: ")

    _listener =
      spawn(fn ->

        case AvancesCliente.suscribirse(id, self()) do
          :ok ->
            IO.puts(
              IO.ANSI.green() <>
                "Suscrito al proyecto #{id}. Escuchando avances en segundo plano..." <>
                IO.ANSI.reset()
            )

            loop_listen(id)

          {:error, m} ->
            IO.puts(
              IO.ANSI.red() <>
                "Error al suscribirse a avances en listener: #{inspect(m)}" <>
                IO.ANSI.reset()
            )
        end
      end)

    :ok
  end


  defp loop_listen(proyecto_id) do
    receive do
      {:avance, a} ->

        pid_avance = a[:proyecto_id] || a["proyecto_id"]

        if pid_avance == proyecto_id do
          t = a[:timestamp] || a[:fecha_iso] || "-"
          msg = a[:mensaje] || a[:contenido] || "(sin contenido)"

          IO.puts(
            IO.ANSI.cyan() <>
              "\n[AVANCE RT] [#{t}] Proyecto ##{proyecto_id}: #{msg}" <>
              IO.ANSI.reset()
          )
        end

        loop_listen(proyecto_id)

      otro ->
        IO.inspect(otro, label: "Evento no reconocido en avances")
        loop_listen(proyecto_id)
    end
  end

  # ====== LISTADO / HELPERS ======
  defp listar(lista) do
    if Enum.empty?(lista) do
      IO.puts(IO.ANSI.yellow() <> "(sin resultados)" <> IO.ANSI.reset())
    else
      Enum.each(lista, fn p ->
        IO.puts(
          IO.ANSI.cyan() <>
            "##{p.id} [eq=#{p.equipo_id}] #{p.titulo} (#{p.categoria}) - #{p.estado} @ #{p.fecha_registro}" <>
            IO.ANSI.reset()
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

  defp print_proyecto_creado(p, desc) do
    IO.puts("\n" <> IO.ANSI.green() <> "Proyecto registrado correctamente." <> IO.ANSI.reset())
    IO.puts(IO.ANSI.light_white() <> "ID de proyecto: #{p.id}" <> IO.ANSI.reset())
    IO.puts(IO.ANSI.light_white() <> "ID de equipo:   #{p.equipo_id}" <> IO.ANSI.reset())
    IO.puts(IO.ANSI.light_white() <> "Título:         #{p.titulo}" <> IO.ANSI.reset())
    IO.puts(IO.ANSI.light_white() <> "Descripción:    #{desc}" <> IO.ANSI.reset())
    IO.puts(IO.ANSI.light_white() <> "Categoría:      #{p.categoria}" <> IO.ANSI.reset())
    IO.puts(IO.ANSI.light_white() <> "Estado inicial: #{p.estado}" <> IO.ANSI.reset())

    IO.puts(
      IO.ANSI.light_white() <> "Fecha de registro: #{p.fecha_registro}\n" <> IO.ANSI.reset()
    )
  end

  defp ask_int(p), do: ask(p) |> String.to_integer()
  defp to_str(nil), do: ""
  defp to_str(s), do: String.trim(to_string(s))

  defp limpiar(t),
    do: t |> to_str() |> String.replace("\n", " ") |> String.trim()

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
      "archivado" -> "entregado"
      other -> other
    end
  end
end
