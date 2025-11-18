defmodule HackathonApp.Adapter.InterfazConsolaMentoria do
  @moduledoc "Menú para mentor (lectura de equipos y proyectos + feedback y consultas)."

  alias HackathonApp.Service.{EquipoServicio, ProyectoServicio, Autorizacion}
  alias HackathonApp.Adapter.PersistenciaCSV, as: CSV
  alias HackathonApp.Adapter.InterfazConsolaChat
  alias HackathonApp.Adapter.InterfazConsolaLogin

  # ====== Punto de entrada ======
  def iniciar do
    case HackathonApp.Session.current() do
      nil -> IO.puts("\n[Sesión no iniciada] Vuelve al login.")
      u when is_map(u) -> loop(u)
    end
  end

  # ====== Menú Mentoría ======
  defp loop(u) do
    IO.puts(
      "\n" <> IO.ANSI.cyan_background() <> "=== MENÚ DE MENTORÍA ===" <> IO.ANSI.reset() <> "\n"
    )

    IO.puts(IO.ANSI.yellow() <> "Mentor: #{u.nombre}" <> IO.ANSI.reset())

    IO.puts(
      IO.ANSI.light_black() <> "----------------------------------------" <> IO.ANSI.reset()
    )

    IO.puts(IO.ANSI.green() <> "1) Ver equipos" <> IO.ANSI.reset())
    IO.puts(IO.ANSI.green() <> "2) Ver proyectos" <> IO.ANSI.reset())
    IO.puts(IO.ANSI.green() <> "3) Dar mentoría (dejar comentario)" <> IO.ANSI.reset())
    IO.puts(IO.ANSI.green() <> "4) Ver avances recientes" <> IO.ANSI.reset())
    IO.puts(IO.ANSI.green() <> "5) Ver miembros de un equipo" <> IO.ANSI.reset())
    IO.puts(IO.ANSI.green() <> "6) Ver mensajes recientes de un equipo" <> IO.ANSI.reset())
    IO.puts(IO.ANSI.green() <> "7) Enviar mensaje al equipo (consulta)" <> IO.ANSI.reset())
    IO.puts(IO.ANSI.green() <> "8) Modo comandos (/help, /teams, /project...)" <> IO.ANSI.reset())
    IO.puts(IO.ANSI.yellow() <> "9) Chat en tiempo real (canal general)" <> IO.ANSI.reset())
    IO.puts(IO.ANSI.light_cyan() <> "0) Cerrar sesión" <> IO.ANSI.reset())

    case prompt("> ") do
      "1" ->
        ver_equipos(u)
        loop(u)

      "2" ->
        ver_proyectos(u)
        loop(u)

      "3" ->
        dar_mentoria(u)
        loop(u)

      "4" ->
        ver_avances(u)
        loop(u)

      "5" ->
        ver_miembros(u)
        loop(u)

      "6" ->
        ver_mensajes(u)
        loop(u)

      "7" ->
        enviar_mensaje(u)
        loop(u)

      "8" ->
        HackathonApp.Adapter.ComandosCLI.iniciar()
        loop(u)

      "9" ->
        InterfazConsolaChat.iniciar()
        loop(u)

      "0" ->
       IO.puts("Hasta pronto!")
       InterfazConsolaLogin.iniciar()

      _ ->
        IO.puts("Opción inválida")
        loop(u)
    end
  end

  # ====== Acciones ======
  defp ver_equipos(u) do
    if Autorizacion.can?(u.rol, :ver_equipos) do
      case EquipoServicio.listar_equipos() do
        {:ok, []} ->
          IO.puts(IO.ANSI.yellow() <> "No hay equipos registrados." <> IO.ANSI.reset())

        {:ok, equipos} ->
          IO.puts("\n" <> IO.ANSI.green() <> "--- Equipos ---" <> IO.ANSI.reset())

          Enum.each(equipos, fn e ->
            tema = Map.get(e, :tema, Map.get(e, :nombre, "sin_tema"))
            estado = if Map.get(e, :activo, true), do: "activo", else: "inactivo"

            IO.puts(
              IO.ANSI.cyan() <>
                "• #{tema} (id=#{Map.get(e, :id, "N/A")}, #{estado})" <> IO.ANSI.reset()
            )
          end)

        {:error, m} ->
          IO.puts(IO.ANSI.red() <> "Error al listar equipos: " <> to_string(m) <> IO.ANSI.reset())
      end
    else
      IO.puts(
        IO.ANSI.red() <>
          "Acceso denegado. Esta sección es solo lectura para mentor." <> IO.ANSI.reset()
      )
    end
  end

  defp ver_proyectos(u) do
    if Autorizacion.can?(u.rol, :ver_proyecto) do
      # Soporta ambas firmas: listar_proyectos/0 -> {:ok, lista}  o  listar/0 -> lista
      case safe_listar_proyectos() do
        {:ok, []} ->
          IO.puts(IO.ANSI.yellow() <> "No hay proyectos registrados." <> IO.ANSI.reset())

        {:ok, proyectos} ->
          IO.puts("\n" <> IO.ANSI.green() <> "--- Proyectos ---" <> IO.ANSI.reset())
          Enum.each(proyectos, &print_proyecto/1)

        lista when is_list(lista) and lista == [] ->
          IO.puts(IO.ANSI.yellow() <> "No hay proyectos registrados." <> IO.ANSI.reset())

        lista when is_list(lista) ->
          IO.puts("\n--- Proyectos ---")
          Enum.each(lista, &print_proyecto/1)

        {:error, m} ->
          IO.puts("Error al listar proyectos: " <> to_string(m))
      end
    else
      IO.puts(IO.ANSI.red() <> "Acceso denegado (solo lectura para mentor)." <> IO.ANSI.reset())
    end
  end

  defp print_proyecto(p) do
    id = Map.get(p, :id, "N/A")
    tit = Map.get(p, :titulo, "sin_titulo")
    eq = Map.get(p, :equipo_id, "N/A")
    est = Map.get(p, :estado, "N/A")
    cat = Map.get(p, :categoria, "N/A")
    fecha = Map.get(p, :fecha_registro, "")

    IO.puts(
      "• [#{id}] #{tit} — equipo #{eq} — estado #{est} — categoría #{cat} — creado #{fecha}"
    )
  end

  # 3) Dar mentoría (comentario dirigido al equipo)
  defp dar_mentoria(u) do
    if Autorizacion.can?(u.rol, :dar_mentoria) do
      nombre_eq = prompt("Equipo (por nombre): ")
      texto = prompt("Comentario: ")

      with {:ok, equipo_id} <- resolve_equipo_id(nombre_eq) do
        fecha = DateTime.utc_now() |> DateTime.to_iso8601()
        # mensajes.csv: id,equipo_id,usuario_id,texto,fecha_iso
        fila = ["", Integer.to_string(equipo_id), Integer.to_string(u.id), limpiar(texto), fecha]
        :ok = CSV.agregar("data/mensajes.csv", fila)
        IO.puts(IO.ANSI.green() <> "Comentario registrado." <> IO.ANSI.reset())
      else
        {:error, m} -> IO.puts(m)
      end
    else
      IO.puts(
        IO.ANSI.red() <> "Acceso denegado (no puedes registrar mentoría)." <> IO.ANSI.reset()
      )
    end
  end

  # 4) Ver avances recientes (últimos 10 de todos los proyectos)
  defp ver_avances(u) do
    if Autorizacion.can?(u.rol, :ver_proyecto) do
      # avances.csv (servicio actual): id,proyecto_id,contenido,fecha_iso
      avances =
        CSV.leer("data/avances.csv")
        |> Enum.map(fn
          [id, p, c, f] -> %{id: id, proyecto_id: p, contenido: c, fecha_iso: f}
          _ -> nil
        end)
        |> Enum.reject(&is_nil/1)
        |> Enum.take(-10)

      if avances == [] do
        IO.puts(IO.ANSI.yellow() <> "No hay avances registrados." <> IO.ANSI.reset())
      else
        IO.puts("\n" <> IO.ANSI.green() <> "--- Avances recientes ---" <> IO.ANSI.reset())

        Enum.each(avances, fn a ->
          IO.puts(
            IO.ANSI.cyan() <>
              "[#{a.fecha_iso}] (proy #{a.proyecto_id}) #{a.contenido}" <> IO.ANSI.reset()
          )
        end)
      end
    else
      IO.puts(IO.ANSI.red() <> "Acceso denegado." <> IO.ANSI.reset())
    end
  end

  # 5) Ver miembros de un equipo
  defp ver_miembros(u) do
    if Autorizacion.can?(u.rol, :ver_equipos) do
      nombre_eq = prompt("Equipo (por nombre): ")

      case EquipoServicio.listar_miembros(nombre_eq) do
        [] ->
          IO.puts(IO.ANSI.yellow() <> "Sin miembros o equipo inexistente." <> IO.ANSI.reset())

        miembros ->
          IO.puts(
            "\n" <>
              IO.ANSI.green() <>
              "--- Miembros de #{String.trim(nombre_eq)} ---" <> IO.ANSI.reset()
          )

          Enum.each(miembros, fn m ->
            IO.puts(
              IO.ANSI.cyan() <>
                "• usuario_id=#{m.usuario_id} rol_en_equipo=#{m.rol_en_equipo}" <> IO.ANSI.reset()
            )
          end)
      end
    else
      IO.puts(IO.ANSI.red() <> "Acceso denegado." <> IO.ANSI.reset())
    end
  end

  # 6) Ver mensajes recientes de un equipo
  defp ver_mensajes(u) do
    if Autorizacion.can?(u.rol, :ver_proyecto) do
      nombre_eq = prompt("Equipo (por nombre): ")

      with {:ok, equipo_id} <- resolve_equipo_id(nombre_eq) do
        # mensajes.csv: id,equipo_id,usuario_id,texto,fecha_iso
        mensajes =
          CSV.leer("data/mensajes.csv")
          |> Enum.filter(fn
            [_id, e_id, _u, _t, _f] -> e_id == Integer.to_string(equipo_id)
            _ -> false
          end)
          |> Enum.map(fn [id, e, u_id, txt, f] ->
            %{id: id, equipo_id: e, usuario_id: u_id, texto: txt, fecha: f}
          end)
          |> Enum.take(-15)

        if mensajes == [] do
          IO.puts(IO.ANSI.yellow() <> "No hay mensajes para ese equipo." <> IO.ANSI.reset())
        else
          IO.puts(
            "\n" <>
              IO.ANSI.green() <>
              "--- Mensajes recientes (#{String.trim(nombre_eq)}) ---" <> IO.ANSI.reset()
          )

          Enum.each(mensajes, fn m ->
            IO.puts(
              IO.ANSI.cyan() <>
                "[#{m.fecha}] (user #{m.usuario_id}) #{m.texto}" <> IO.ANSI.reset()
            )
          end)
        end
      else
        {:error, m} -> IO.puts(m)
      end
    else
      IO.puts(IO.ANSI.red() <> "Acceso denegado." <> IO.ANSI.reset())
    end
  end

  # 7) Enviar mensaje al equipo (consulta del mentor hacia el equipo)
  defp enviar_mensaje(u) do
    if Autorizacion.can?(u.rol, :enviar_mensaje) do
      nombre_eq = prompt("Equipo (por nombre): ")
      texto = prompt("Mensaje: ")

      with {:ok, equipo_id} <- resolve_equipo_id(nombre_eq) do
        fecha = DateTime.utc_now() |> DateTime.to_iso8601()
        fila = ["", Integer.to_string(equipo_id), Integer.to_string(u.id), limpiar(texto), fecha]
        :ok = CSV.agregar("data/mensajes.csv", fila)

        IO.puts(
          IO.ANSI.green() <> "Mensaje enviado a #{String.trim(nombre_eq)}." <> IO.ANSI.reset()
        )
      else
        {:error, m} -> IO.puts(m)
      end
    else
      IO.puts(IO.ANSI.red() <> "Acceso denegado (no puedes enviar mensajes)." <> IO.ANSI.reset())
    end
  end

  # ====== Helpers ======
  defp resolve_equipo_id(nombre_eq) do
    case EquipoServicio.buscar_equipo_por_nombre(nombre_eq) do
      nil -> {:error, "No existe el equipo #{String.trim(nombre_eq)}"}
      %{id: equipo_id} -> {:ok, equipo_id}
    end
  end

  defp safe_listar_proyectos do
    # Intenta wrapper {:ok, lista}; si no existe, cae a listar/0 (lista)
    try do
      ProyectoServicio.listar_proyectos()
    rescue
      _ ->
        try do
          ProyectoServicio.listar()
        rescue
          e -> {:error, e}
        end
    end
  end

  # ====== I/O robusto ======
  defp prompt(label) do
    case IO.gets(:stdio, label) do
      :eof ->
        IO.puts("\n[Entrada cerrada] Intenta de nuevo.")
        Process.sleep(100)
        prompt(label)

      nil ->
        IO.puts("\n[Entrada nula] Intenta de nuevo.")
        prompt(label)

      data ->
        data |> to_string() |> String.trim()
    end
  end

  defp limpiar(t), do: t |> to_string() |> String.replace("\n", " ") |> String.trim()
  defp to_str(nil), do: ""
  defp to_str(s), do: s |> to_string() |> String.trim()
end
