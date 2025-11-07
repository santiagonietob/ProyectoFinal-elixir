defmodule HackathonApp.Adapter.InterfazConsolaLogin do
  @moduledoc "Pantalla de inicio de sesión y ruteo por rol."
  alias HackathonApp.Service.{AuthServicio, UsuarioServicio}

  alias HackathonApp.Adapter.{
    # menú general (organizador)
    InterfazConsola,
    # participante
    InterfazConsolaProyectos,
    # mentor
    InterfazConsolaMentoria
  }

  def iniciar do
    IO.puts("\n=== HACKATHON COLABORATIVA ===")
    IO.puts("1) Iniciar sesión")
    IO.puts("2) Registrarme (si no tengo cuenta)")
    IO.puts("0) Salir")

    case IO.gets("> ") |> to_str() do
      "1" ->
        login()

      "2" ->
        registrar_y_login()

      "0" ->
        IO.puts("Hasta pronto!")

      _ ->
        IO.puts("Opción inválida")
        iniciar()
    end
  end

  defp login do
    nombre = ask("Usuario: ")
    pass = ask("Contraseña: ")

    case AuthServicio.login(nombre, pass) do
      {:ok, u} ->
        IO.puts("Bienvenido #{u.nombre} (rol=#{u.rol})")
        ruteo_por_rol(u.rol)

      {:error, m} ->
        IO.puts("Login fallido: " <> m)
        iniciar()
    end
  end

  defp registrar_y_login do
    nombre = ask("Nombre: ")
    correo = ask("Correo: ")
    rol = ask("Rol (participante|mentor|organizador): ")
    pass = ask("Contraseña: ")

    case UsuarioServicio.registrar(nombre, correo, rol, pass) do
      {:ok, _u} ->
        IO.puts("Registro exitoso. Ahora inicia sesión.")
        login()

      {:error, m} ->
        IO.puts("Error: " <> m)
        iniciar()
    end
  end

  # ---------- Ruteo por rol ----------
  defp ruteo_por_rol("organizador"), do: InterfazConsola.iniciar()
  defp ruteo_por_rol("mentor"), do: InterfazConsolaMentoria.iniciar()
  defp ruteo_por_rol("participante"), do: InterfazConsolaProyectos.iniciar()

  defp ruteo_por_rol(_otro) do
    IO.puts("Rol desconocido")
    iniciar()
  end

  # ---------- Sesión mínima ----------
  defp start_session(%{id: id, nombre: n, rol: r}),
    do: HackathonApp.Session.start(%{id: id, nombre: n, rol: r})

  # ---------- Helpers ----------
  defp ask(p) do
    IO.write(p)
    IO.gets("") |> to_str()
  end

  defp to_str(nil), do: ""
  defp to_str(s), do: s |> to_string() |> String.trim()
end
