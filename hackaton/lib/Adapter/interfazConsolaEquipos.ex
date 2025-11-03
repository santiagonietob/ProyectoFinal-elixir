# lib/adapter/interfazConsolaEquipos.ex
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
      "1" -> registrar_usuario() ; iniciar()
      "2" -> login()            ; iniciar()
      "3" -> crear_equipo()     ; iniciar()
      "4" -> unir_usuario()     ; iniciar()
      "5" -> listar_equipos()   ; iniciar()
      "6" -> listar_miembros()  ; iniciar()
      "7" -> InterfazConsola.iniciar() ; iniciar()
      "0" -> IO.puts("¡Hasta luego!")
      _   -> IO.puts("Opción inválida") ; iniciar()
    end
  end

  defp registrar_usuario do
    nombre = ask("Nombre: ")
    correo = ask("Correo: ")
    rol    = ask("Rol (participante|mentor|organizador): ")
    pass   = ask("Contraseña (puede estar vacía): ")

    case UsuarioServicio.registrar(nombre, correo, rol, pass) do
      {:ok, u} -> IO.puts("Registrado id=#{u.id} rol=#{u.rol}")
      {:error, m} -> IO.puts("Error: #{m}")
    end
  end

  defp login do
    nombre = ask("Usuario: ")
    pass   = ask("Contraseña: ")

    case AuthServicio.login(nombre, pass) do
      {:ok, u} -> IO.puts("Sesión iniciada como #{u.nombre} (rol=#{u.rol})")
      {:error, m} -> IO.puts("Login fallido: #{m}")
    end
  end

  # ... (resto igual)
  defp ask(p), do: (IO.write(p); to_str(IO.gets("")))
  defp to_str(nil), do: ""
  defp to_str(s),  do: String.trim(to_string(s))
end
