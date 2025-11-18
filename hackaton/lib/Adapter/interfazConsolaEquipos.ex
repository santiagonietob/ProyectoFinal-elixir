defmodule HackathonApp.Adapter.InterfazConsolaEquipos do
  @moduledoc "Menú para gestionar equipos (solo ORGANIZADOR)."
  alias HackathonApp.Service.{UsuarioServicio, EquipoServicio, Autorizacion}
  alias HackathonApp.Adapter.InterfazConsola
  alias HackathonApp.Adapter.InterfazConsolaLogin
  alias HackathonApp.Session

  # ======== Entrada protegida ========
  def iniciar do
    ensure_organizer!()
    menu()
  end

  defp menu do
    IO.puts(IO.ANSI.cyan() <> "\n══════════════════════════════════════")
    IO.puts("   GESTIÓN DE EQUIPOS (organizador) ")
    IO.puts("══════════════════════════════════════" <> IO.ANSI.reset() <> "\n")
    IO.puts(IO.ANSI.green() <> "1) Registrar participante/mentor/organizador" <> IO.ANSI.reset())
    IO.puts(IO.ANSI.green() <> "2) Crear equipo (por tema)" <> IO.ANSI.reset())
    IO.puts(IO.ANSI.green() <> "3) Unir participante a equipo" <> IO.ANSI.reset())
    IO.puts(IO.ANSI.green() <> "4) Listar equipos activos" <> IO.ANSI.reset())
    IO.puts(IO.ANSI.green() <> "5) Listar miembros de un equipo" <> IO.ANSI.reset())
    IO.puts(IO.ANSI.green() <> "6) Eliminar equipo" <> IO.ANSI.reset())
    IO.puts(IO.ANSI.light_cyan() <> "7) Cerrar sesión" <> IO.ANSI.reset())
    IO.puts("0) Menú anterior")

    case IO.gets("> ") |> to_str() do
      "1" ->
        ensure_organizer!()
        registrar_usuario()
        menu()

      "2" ->
        ensure_organizer!()
        crear_equipo()
        menu()

      "3" ->
        ensure_organizer!()
        unir_usuario()
        menu()

      "4" ->
        ensure_organizer!()
        listar_activos_con_ids()
        menu()

      "5" ->
        ensure_organizer!()
        listar_miembros()
        menu()

      "6" ->
        ensure_organizer!()
        eliminar_equipo()
        menu()

      "7" ->
        IO.puts("Hasta pronto!")
        InterfazConsolaLogin.iniciar()

      "0" ->
        IO.puts("Volviendo...")

      _ ->
        IO.puts(IO.ANSI.red() <> "Opción inválida" <> IO.ANSI.reset())
        menu()
    end
  end

  defp eliminar_equipo do
    ident = ask("Equipo a eliminar (nombre o id): ") |> String.trim()

    case HackathonApp.Service.EquipoServicio.eliminar_equipo(ident) do
      {:ok, nombre, id, borradas} ->
        IO.puts(
          IO.ANSI.green() <>
            "Eliminado equipo #{nombre} (id=#{id}). Membresías removidas: #{borradas}" <>
            IO.ANSI.reset()
        )

      {:error, msg} ->
        IO.puts(IO.ANSI.red() <> "Error: #{msg}" <> IO.ANSI.reset())
    end
  end

  # ======== Guardias de acceso ========
  defp ensure_organizer! do
    case Session.current() do
      nil ->
        IO.puts(IO.ANSI.yellow() <> "No hay sesión. Inicia sesión primero." <> IO.ANSI.reset())
        raise RuntimeError, message: "Sin sesión activa"

      %{rol: rol} ->
        if Autorizacion.can?(rol, :crear_equipo) do
          :ok
        else
          IO.puts(
            IO.ANSI.red() <>
              "Acceso denegado. Esta sección es solo para organizador." <> IO.ANSI.reset()
          )

          InterfazConsola.iniciar()
          raise RuntimeError, message: "Acceso denegado: se requiere rol organizador"
        end
    end
  end

  # ======== Acciones del menú ========
  defp registrar_usuario do
    nombre = ask("Nombre: ") |> String.trim()
    correo = ask("Correo: ") |> String.trim()
    rol = ask("Rol (participante|mentor|organizador): ") |> String.trim()
    pass = ask("Contraseña: ")

    case UsuarioServicio.registrar(nombre, correo, rol, pass) do
      {:ok, u} ->
        IO.puts(IO.ANSI.green() <> "Registrado id=#{u.id} rol=#{u.rol}" <> IO.ANSI.reset())

      {:error, "Ya existe un usuario con ese nombre"} ->
        IO.puts(
          IO.ANSI.yellow() <> "El usuario '#{nombre}' ya está registrado" <> IO.ANSI.reset()
        )

      {:error, m} ->
        IO.puts(IO.ANSI.red() <> "Error: #{m}" <> IO.ANSI.reset())
    end
  end

  defp crear_equipo do
    nombre = ask("Nombre del equipo: ")
    desc = ask("Descripción: ")
    tema = ask("Tema/Afinidad: ")

    case EquipoServicio.crear_equipo(nombre, desc, tema) do
      {:ok, e} ->
        IO.puts(
          IO.ANSI.green() <>
            "Creado equipo #{e.nombre} (id=#{e.id}, tema=#{e.tema})" <> IO.ANSI.reset()
        )

      {:error, m} ->
        IO.puts(IO.ANSI.red() <> "Error: #{m}" <> IO.ANSI.reset())
    end
  end

  defp unir_usuario do
    nombre_part = ask("Nombre del participante: ")
    nombre_eq = ask("Nombre del equipo: ")

    with %{id: uid} <- UsuarioServicio.buscar_por_nombre(nombre_part) || %{},
         {:ok, _} <- EquipoServicio.unirse_a_equipo(nombre_eq, uid) do
      IO.puts(IO.ANSI.green() <> "Se unió #{nombre_part} a #{nombre_eq}" <> IO.ANSI.reset())
    else
      nil -> IO.puts(IO.ANSI.yellow() <> "Usuario no encontrado" <> IO.ANSI.reset())
      {:error, msg} -> IO.puts(IO.ANSI.red() <> "Error: #{msg}" <> IO.ANSI.reset())
      _ -> IO.puts(IO.ANSI.red() <> "Operación inválida" <> IO.ANSI.reset())
    end
  end

  # ======== Listados ========
  # Nueva versión: muestra nombre + id + conteo de miembros
  defp listar_activos_con_ids do
    equipos_activos =
      EquipoServicio.listar_todos()
      |> Enum.filter(& &1.activo)

    if equipos_activos == [] do
      IO.puts("No hay equipos activos.")
    else
      IO.puts("\n--- Equipos activos ---")

      Enum.each(equipos_activos, fn e ->
        miembros = EquipoServicio.listar_miembros_por_id(e.id) |> length()

        IO.puts(
          "• #{e.nombre} (id=#{e.id}, #{miembros} #{plural(miembros, "miembro", "miembros")})"
        )
      end)
    end
  end

  defp listar_miembros do
    eq = ask("Equipo (por nombre): ")
    miembros = EquipoServicio.listar_miembros(eq)

    if miembros == [] do
      IO.puts("Sin miembros o equipo inexistente.")
    else
      Enum.each(miembros, fn m ->
        IO.puts("usuario_id=#{m.usuario_id} rol=#{m.rol_en_equipo}")
      end)
    end
  end

  # ======== Helpers de entrada ========
  defp ask(p) do
    IO.write(p)
    to_str(IO.gets(""))
  end

  defp to_str(nil), do: ""
  defp to_str(s), do: String.trim(to_string(s))

  defp plural(1, singular, _plural), do: singular
  defp plural(_, _singular, plural), do: plural
end
