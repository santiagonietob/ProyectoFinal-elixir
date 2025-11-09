defmodule HackathonApp.Adapter.InterfazConsolaMentoria do
  @moduledoc "Menú para mentor (lectura de equipos y proyectos + feedback y consultas)."

  alias HackathonApp.Service.{EquipoServicio, ProyectoServicio, Autorizacion}
  alias HackathonApp.Adapter.PersistenciaCSV, as: CSV

  # ====== Punto de entrada ======
  def iniciar do
    case HackathonApp.Session.current() do
      nil -> IO.puts("\n[Sesión no iniciada] Vuelve al login.")
      u when is_map(u) -> loop(u)
    end
  end

  # ====== Menu Mentoria ======
  defp loop(u) do
    IO.puts("\n=== MENÚ DE MENTORÍA ===")
    IO.puts("Mentor: #{u.nombre} (#{u.rol})")
    IO.puts("1) Ver equipos")
    IO.puts("2) Ver proyectos")
    IO.puts("3) Dar mentoría (dejar comentario)")
    IO.puts("4) Ver avances recientes")
    IO.puts("5) Ver miembros de un equipo")
    IO.puts("6) Ver mensajes recientes de un equipo")
    IO.puts("7) Enviar mensaje al equipo (consulta)")
    IO.puts("0) Volver")

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

      "0" ->
        :ok

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
          IO.puts("No hay equipos registrados.")

        {:ok, equipos} ->
          IO.puts("\n--- Equipos ---")

          Enum.each(equipos, fn e ->
            tema = Map.get(e, :tema, Map.get(e, :nombre, "sin_tema"))
            estado = if Map.get(e, :activo, true), do: "activo", else: "inactivo"
            IO.puts("• #{tema} (id=#{Map.get(e, :id, "N/A")}, #{estado})")
          end)

        {:error, m} ->
          IO.puts("Error al listar equipos: " <> m)
      end
    else
      IO.puts("Acceso denegado. Esta sección es solo lectura para mentor.")
    end
  end

  defp ver_proyectos(u) do
    if Autorizacion.can?(u.rol, :ver_proyecto) do
      case ProyectoServicio.listar_proyectos() do
        {:ok, []} ->
          IO.puts("No hay proyectos registrados.")

        {:ok, proyectos} ->
          IO.puts("\n--- Proyectos ---")

          Enum.each(proyectos, fn p ->
            id = Map.get(p, :id, "N/A")
            tit = Map.get(p, :titulo, "sin_titulo")
            eq = Map.get(p, :equipo_id, "N/A")
            est = Map.get(p, :estado, "N/A")
            cat = Map.get(p, :categoria, "N/A")
            fecha = Map.get(p, :fecha_registro, "")

            IO.puts(
              "• [#{id}] #{tit} — equipo #{eq} — estado #{est} — categoría #{cat} — creado #{fecha}"
            )
          end)

        {:error, m} ->
          IO.puts("Error al listar proyectos: " <> m)
      end
    else
      IO.puts("Acceso denegado (solo lectura para mentor).")
    end
  end

  # 3) Dar mentoría (comentario dirigido al equipo)
  defp dar_mentoria(u) do
    if Autorizacion.can?(u.rol, :dar_mentoria) do
      nombre_eq = prompt("Equipo (por nombre): ")
      texto = prompt("Comentario: ")

      with {:ok, equipo_id} <- resolve_equipo_id(nombre_eq) do
        fecha = DateTime.utc_now() |> DateTime.to_iso8601()
        fila = ["", Integer.to_string(equipo_id), Integer.to_string(u.id), limpiar(texto), fecha]
        # mensajes.csv: id,equipo_id,usuario_id,texto,fecha_iso
        :ok = CSV.agregar("data/mensajes.csv", fila)
        IO.puts("✅ Comentario registrado.")
      else
        {:error, m} -> IO.puts(m)
      end
    else
      IO.puts("Acceso denegado (no puedes registrar mentoría).")
    end
  end

  # 4) Ver avances recientes (últimos 10 de todos los proyectos)
  defp ver_avances(u) do
    if Autorizacion.can?(u.rol, :ver_proyecto) do
      # id,proyecto_id,contenido,fecha_iso
      avances =
        CSV.leer("data/avances.csv")
        |> Enum.map(fn
          [id, p, c, f] -> %{id: id, proyecto_id: p, contenido: c, fecha: f}
          _ -> nil
        end)
        |> Enum.reject(&is_nil/1)
        |> Enum.take(-10)

      if avances == [] do
        IO.puts("No hay avances registrados.")
      else
        IO.puts("\n--- Avances recientes ---")

        Enum.each(avances, fn a ->
          IO.puts("[#{a.fecha}] (proy #{a.proyecto_id}) #{a.contenido}")
        end)
      end
    else
      IO.puts("Acceso denegado.")
    end
  end

  # 5) Ver miembros de un equipo
  defp ver_miembros(u) do
    if Autorizacion.can?(u.rol, :ver_equipos) do
      nombre_eq = prompt("Equipo (por nombre): ")

      case EquipoServicio.listar_miembros(nombre_eq) do
        [] ->
          IO.puts("Sin miembros o equipo inexistente.")

        miembros ->
          IO.puts("\n--- Miembros de #{String.trim(nombre_eq)} ---")

          Enum.each(miembros, fn m ->
            IO.puts("• usuario_id=#{m.usuario_id} rol_en_equipo=#{m.rol_en_equipo}")
          end)
      end
    else
      IO.puts("Acceso denegado.")
    end
  end

  # 6) Ver mensajes recientes de un equipo
  defp ver_mensajes(u) do
    if Autorizacion.can?(u.rol, :ver_proyecto) do
      nombre_eq = prompt("Equipo (por nombre): ")

      with {:ok, equipo_id} <- resolve_equipo_id(nombre_eq) do
        # id,equipo_id,usuario_id,texto,fecha_iso
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
          IO.puts("No hay mensajes para ese equipo.")
        else
          IO.puts("\n--- Mensajes recientes (#{String.trim(nombre_eq)}) ---")

          Enum.each(mensajes, fn m ->
            IO.puts("[#{m.fecha}] (user #{m.usuario_id}) #{m.texto}")
          end)
        end
      else
        {:error, m} -> IO.puts(m)
      end
    else
      IO.puts("Acceso denegado.")
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
        IO.puts("✅ Mensaje enviado a #{String.trim(nombre_eq)}.")
      else
        {:error, m} -> IO.puts(m)
      end
    else
      IO.puts("Acceso denegado (no puedes enviar mensajes).")
    end
  end

  # ====== Helpers ======
  defp resolve_equipo_id(nombre_eq) do
    case EquipoServicio.buscar_equipo_por_nombre(nombre_eq) do
      nil -> {:error, "No existe el equipo #{String.trim(nombre_eq)}"}
      %{id: equipo_id} -> {:ok, equipo_id}
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

# NO ME SALEN LOS COMITS NI SALGO COMO COLABORADORA
