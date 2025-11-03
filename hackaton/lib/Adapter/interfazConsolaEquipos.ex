defmodule HackathonApp.Adapter.InterfazConsolaEquipos do
  @moduledoc "Menú mínimo para registrar usuarios y gestionar equipos."
  alias HackathonApp.Service.{UsuarioServicio, EquipoServicio}

  def iniciar do
    IO.puts("\n=== Gestión de equipos ===")
    IO.puts("1) Registrar participante")
    IO.puts("2) Crear equipo (por tema)")
    IO.puts("3) Unir participante a equipo")
    IO.puts("4) Listar equipos activos")
    IO.puts("5) Listar miembros de un equipo")
    IO.puts("0) Salir")

    case IO.gets("> ") |> to_str() do
      "1" -> registrar_usuario(); iniciar()
      "2" -> crear_equipo(); iniciar()
      "3" -> unir_usuario(); iniciar()
      "4" -> listar_equipos(); iniciar()
      "5" -> listar_miembros(); iniciar()
      "0" -> IO.puts("¡Hasta luego!")
      _   -> IO.puts("Opción inválida"); iniciar()
    end
  end

  defp registrar_usuario do
    nombre = ask("Nombre: ")
    correo = ask("Correo: ")
    case UsuarioServicio.registrar(nombre, correo, "participante") do
      {:ok, u} -> IO.puts("Registrado id=#{u.id}")
      {:error, m} -> IO.puts("Error: #{m}")
    end
  end

  defp crear_equipo do
    nombre = ask("Nombre del equipo: ")
    desc   = ask("Descripción: ")
    tema   = ask("Tema/Afinidad: ")
    case EquipoServicio.crear_equipo(nombre, desc, tema) do
      {:ok, e} -> IO.puts("Creado equipo #{e.nombre} (tema=#{e.tema})")
      {:error, m} -> IO.puts("Error: #{m}")
    end
  end

  defp unir_usuario do
    nombre_part = ask("Nombre del participante: ")
    nombre_eq   = ask("Nombre del equipo: ")
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

  defp ask(p), do: (IO.write(p); to_str(IO.gets("")))
  defp to_str(nil), do: ""
  defp to_str(s), do: String.trim(to_string(s))
end
