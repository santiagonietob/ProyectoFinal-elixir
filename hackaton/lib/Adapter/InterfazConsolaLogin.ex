defmodule HackathonApp.Adapter.InterfazConsolaLogin do
  @moduledoc "Pantalla de inicio de sesión y ruteo por rol."
  alias HackathonApp.Service.{AuthServicio, UsuarioServicio}
  alias HackathonApp.Adapter.{InterfazConsola, InterfazConsolaProyectos, InterfazConsolaMentoria}

  # ====== Punto de entrada ======
  def iniciar, do: loop()

  defp loop do
    IO.puts("\n=== HACKATHON COLABORATIVA ===")
    IO.puts("1) Iniciar sesión")
    IO.puts("2) Registrarme (si no tengo cuenta)")
    IO.puts("0) Salir")

    case prompt("> ") do
      "1" -> login(); loop()
      "2" -> registrar_y_login(); loop()
      "0" -> IO.puts("Hasta pronto!")
      _   -> IO.puts("Opción inválida"); loop()
    end
  end

  # ====== Acciones ======
  defp login do
    nombre = prompt("Usuario: ")
    pass   = prompt("Contraseña: ")

    case AuthServicio.login(nombre, pass) do
      {:ok, u} ->
        start_session(u)
        IO.puts("Bienvenido #{u.nombre} (rol=#{u.rol})")
        ruteo_por_rol(u.rol)
      {:error, m} ->
        IO.puts("Login fallido: " <> m)
    end
  end

  defp registrar_y_login do
    nombre = prompt("Nombre: ")
    correo = prompt("Correo: ")
    rol    = prompt("Rol (participante|mentor|organizador): ")
    pass   = prompt("Contraseña: ")

    case UsuarioServicio.registrar(nombre, correo, rol, pass) do
      {:ok, _u} -> IO.puts("Registro exitoso. Ahora inicia sesión."); login()
      {:error, m} -> IO.puts("Error: " <> m)
    end
  end

  # ====== Ruteo por rol ======
  defp ruteo_por_rol("organizador"), do: InterfazConsola.iniciar()
  defp ruteo_por_rol("mentor"),      do: InterfazConsolaMentoria.iniciar()
  defp ruteo_por_rol("participante"),do: InterfazConsolaProyectos.iniciar()
  defp ruteo_por_rol(_), do: IO.puts("Rol desconocido")

  # ====== Sesión ======
  defp start_session(%{id: id, nombre: n, rol: r}),
    do: HackathonApp.Session.start(%{id: id, nombre: n, rol: r})

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
end
