defmodule HackathonApp.Adapter.InterfazConsolaEquipos do
  @moduledoc "Menú mínimo para registrar usuarios y gestionar equipos."
  alias HackathonApp.Service.{UsuarioServicio, EquipoServicio}
  alias HackathonApp.Service.AuthServicio
  alias HackathonApp.Adapter.InterfazConsola

  def iniciar do
    IO.puts("\n=== Gestión de equipos ===")
    IO.puts("1) Registrar participante/mentor/organizador")
    IO.puts("2) Iniciar sesión (login)")
    IO.puts("3) Crear equipo (por tema)")
    IO.puts("4) Unir participante a equipo")
    IO.puts("5) Listar equipos activos")
    IO.puts("6) Listar miembros de un equipo")
    IO.puts("7) Volver")
    IO.puts("0) Salir")

    case IO.gets("> ") |> to_str() do
      "1" ->
        registrar_usuario()
        iniciar()

      "2" ->
        login()
        iniciar()

      "3" ->
        crear_equipo()
        iniciar()

      "4" ->
        unir_usuario()
        iniciar()

      "5" ->
        listar_equipos()
        iniciar()

      "6" ->
        listar_miembros()
        iniciar()

      "7" ->
        InterfazConsola.iniciar()
        iniciar()

      "0" ->
        IO.puts("¡Hasta luego!")

      _ ->
        IO.puts("Opción inválida")
        iniciar()
    end
  end

  # -------------------------
  # Acciones del menú
  # -------------------------

  defp registrar_usuario do
    nombre = ask("Nombre: ") |> String.trim()
    correo = ask("Correo: ") |> String.trim()
    rol = ask("Rol (participante|mentor|organizador): ") |> String.trim()
    pass = ask("Contraseña: ")

    case HackathonApp.Service.UsuarioServicio.registrar(nombre, correo, rol, pass) do
      {:ok, u} ->
        IO.puts("Registrado id=#{u.id} rol=#{u.rol}")

      {:error, "Ya existe un usuario con ese nombre"} ->
        IO.puts(" El usuario '#{nombre}' ya está registrado")

      {:error, m} ->
        IO.puts(" Error: #{m}")
    end
  end

  defp login do
    nombre = ask("Usuario: ")
    pass = ask("Contraseña: ")

    if Code.ensure_loaded?(AuthServicio) and function_exported?(AuthServicio, :login, 2) do
      case AuthServicio.login(nombre, pass) do
        {:ok, u} -> IO.puts("Sesión iniciada como #{u.nombre} (rol=#{u.rol})")
        {:error, m} -> IO.puts("Login fallido: #{m}")
      end
    else
      # Modo compat: si no existe AuthServicio todavía, al menos valida existencia de usuario
      case UsuarioServicio.buscar_por_nombre(nombre) do
        nil -> IO.puts("Usuario no encontrado")
        u -> IO.puts("Sesión (modo compat) como #{u.nombre} (rol=#{u.rol})")
      end
    end
  end

  defp crear_equipo do
    nombre = ask("Nombre del equipo: ")
    desc = ask("Descripción: ")
    tema = ask("Tema/Afinidad: ")

    case EquipoServicio.crear_equipo(nombre, desc, tema) do
      {:ok, e} -> IO.puts("Creado equipo #{e.nombre} (tema=#{e.tema})")
      {:error, m} -> IO.puts("Error: #{m}")
    end
  end

  defp unir_usuario do
    nombre_part = ask("Nombre del participante: ")
    nombre_eq = ask("Nombre del equipo: ")

    with %{id: uid} <- UsuarioServicio.buscar_por_nombre(nombre_part) || %{},
         {:ok, _} <- EquipoServicio.unirse_a_equipo(nombre_eq, uid) do
      IO.puts("Se unió #{nombre_part} a #{nombre_eq}")
    else
      nil -> IO.puts("Usuario no encontrado")
      {:error, m} -> IO.puts("Error: #{m}")
      _ -> IO.puts("Operación inválida")
    end
  end

  defp listar_equipos do
    EquipoServicio.listar_equipos_con_conteo()
    |> Enum.each(fn {n, c} -> IO.puts("- #{n} (#{c} miembros)") end)
  end

  defp listar_miembros do
    eq = ask("Equipo: ")

    EquipoServicio.listar_miembros(eq)
    |> Enum.each(fn m -> IO.puts("usuario_id=#{m.usuario_id} rol=#{m.rol_en_equipo}") end)
  end

  # -------------------------
  # Helpers de entrada
  # -------------------------

  defp ask(p) do
    IO.write(p)
    to_str(IO.gets(""))
  end

  defp to_str(nil), do: ""
  defp to_str(s), do: String.trim(to_string(s))
end
