defmodule Hackaton.Adapter.InterfazConsola do
  alias Hackaton.Service.UsuariosService

  def iniciar do
    IO.puts("\n=== MENÚ PRINCIPAL ===")
    IO.puts("1) Registrar usuario")
    IO.puts("2) Listar usuarios")
    IO.puts("0) Salir")

    case IO.gets("> ") |> String.trim() do
      "1" -> registrar(); iniciar()
      "2" -> listar(); iniciar()
      "0" -> IO.puts("Hasta luego!")
      _ -> IO.puts("Opción inválida"); iniciar()
    end
  end

  defp registrar do
    nombre = IO.gets("Nombre: ") |> String.trim()
    correo = IO.gets("Correo: ") |> String.trim()
    rol = IO.gets("Rol (participante/mentor): ") |> String.trim()
    UsuariosService.registrar_usuario(nombre, correo, rol)
    IO.puts("Usuario registrado correctamente.")
  end

  defp listar do
    UsuariosService.listar_usuarios()
    |> Enum.each(fn u -> IO.puts("#{u.id}. #{u.nombre} (#{u.rol}) - #{u.correo}") end)
  end
end
