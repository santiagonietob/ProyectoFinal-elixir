defmodule HackathonApp.Adapter.InterfazConsolaLogin do
  @moduledoc "Pantalla de inicio de sesión y ruteo por rol."
  alias HackathonApp.Service.{AuthServicio, UsuarioServicio}
  alias HackathonApp.Adapter.{InterfazConsola, InterfazConsolaProyectos, InterfazConsolaMentoria}

  # ====== Punto de entrada ======
  def iniciar, do: loop()


  defp loop do
    Process.sleep(300)
    IO.puts(
      "\n" <> IO.ANSI.cyan_background() <> "=== HACKATHON COLABORATIVA ===" <> IO.ANSI.reset() <> "\n"
    )

    IO.puts(IO.ANSI.green() <> "1) Iniciar sesión" <> IO.ANSI.reset())
    IO.puts(IO.ANSI.green() <> "2) Registrarme (si no tengo cuenta)" <> IO.ANSI.reset())
    IO.puts(IO.ANSI.red() <> "0) Salir" <> IO.ANSI.reset())

    case prompt("> ") do
      "1" ->
        login()
        loop()

      "2" ->
        registrar_y_login()
        loop()

      "0" ->
        IO.puts(IO.ANSI.green() <> "Hasta pronto!" <> IO.ANSI.reset())

      _ ->
        IO.puts(IO.ANSI.red() <> "Opción inválida" <> IO.ANSI.reset())
        loop()
    end
  end

  # ====== Acciones ======
  defp login do
    nombre = prompt("Usuario: ")
    pass = prompt("Contraseña: ")

    case AuthServicio.login(nombre, pass) do
      {:ok, u} ->
        start_session(u)

        IO.puts(
          IO.ANSI.green() <> "\nBienvenido #{u.nombre} (Interfaz #{u.rol})" <> IO.ANSI.reset()
        )

        ruteo_por_rol(u.rol)

      {:error, m} ->
        IO.puts(IO.ANSI.red() <> "Login fallido: " <> m <> IO.ANSI.reset())
    end
  end

  # Reescrito: solicitar cada campo con validación local; intentar registrar y repetir hasta éxito.
  defp registrar_y_login do
    do_registrar()
  end

  defp do_registrar do
    nombre = solicitar_nombre_valido()
    correo = solicitar_correo_valido()
    rol = solicitar_rol_valido()
    pass = solicitar_password_valido()

    case UsuarioServicio.registrar(nombre, correo, rol, pass) do
      {:ok, _u} ->
        IO.puts(IO.ANSI.green() <> "Registro exitoso. Ahora inicia sesión." <> IO.ANSI.reset())
        login()
        :ok

      {:error, errors} when is_map(errors) ->
        errores =
          errors
          |> Enum.map(fn {k, v} ->
            key = if is_atom(k), do: Atom.to_string(k), else: to_string(k)
            "#{key}: #{v}"
          end)
          |> Enum.join("\n")

        IO.puts(IO.ANSI.red() <> "No se pudo registrar:\n" <> errores <> IO.ANSI.reset())

        do_registrar()

      {:error, other} ->
        IO.puts(IO.ANSI.red() <> "Error: " <> to_string(other) <> IO.ANSI.reset())
        do_registrar()
    end
  end

  # solicita el correo hasta que pase las validaciones básicas
  defp solicitar_correo_valido do
    regex = ~r/^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$/

    correo = prompt("Correo: ") |> String.trim()

    cond do
      correo == "" ->
        IO.puts(IO.ANSI.red() <> "El correo es obligatorio" <> IO.ANSI.reset())
        solicitar_correo_valido()

      not String.contains?(correo, "@") ->
        IO.puts(IO.ANSI.red() <> "El correo debe contener @" <> IO.ANSI.reset())
        solicitar_correo_valido()

      not Regex.match?(regex, correo) ->
        IO.puts(IO.ANSI.red() <> "Formato de correo inválido" <> IO.ANSI.reset())
        solicitar_correo_valido()

      true ->
        correo
    end
  end

  # Solicitar nombre hasta que cumpla reglas básicas
  defp solicitar_nombre_valido do
    nombre = prompt("Nombre: ") |> String.trim()

    cond do
      nombre == "" ->
        IO.puts(IO.ANSI.red() <> "El nombre es obligatorio" <> IO.ANSI.reset())
        solicitar_nombre_valido()

      String.length(nombre) < 2 ->
        IO.puts(IO.ANSI.red() <> "El nombre debe tener al menos 2 caracteres" <> IO.ANSI.reset())
        solicitar_nombre_valido()

      not Regex.match?(~r/^[A-Za-zÁÉÍÓÚáéíóúÑñ\s]+$/u, nombre) ->
        IO.puts(IO.ANSI.red() <> "El nombre solo puede contener letras y espacios" <> IO.ANSI.reset())
        solicitar_nombre_valido()

      true ->
        nombre
    end
  end

  # Nuevo: solicitar rol válido
  defp solicitar_rol_valido do
    rol = prompt("Rol (participante|mentor|organizador): ") |> String.trim() |> String.downcase()

    allowed = ["participante", "mentor", "organizador"]

    if rol in allowed do
      rol
    else
      IO.puts(IO.ANSI.red() <> "Rol inválido. Elija participante, mentor u organizador." <> IO.ANSI.reset())
      solicitar_rol_valido()
    end
  end

  # Nuevo: solicitar contraseña hasta que cumpla reglas básicas
  defp solicitar_password_valido do
    pass = prompt("Contraseña: ")

    cond do
      pass == "" ->
        IO.puts(IO.ANSI.red() <> "La contraseña es obligatoria" <> IO.ANSI.reset())
        solicitar_password_valido()

      String.length(pass) < 6 ->
        IO.puts(IO.ANSI.red() <> "La contraseña debe tener al menos 6 caracteres" <> IO.ANSI.reset())
        solicitar_password_valido()

      true ->
        pass
    end
  end

  # ====== Ruteo por rol ======
  defp ruteo_por_rol("organizador"), do: InterfazConsola.iniciar()
  defp ruteo_por_rol("mentor"), do: InterfazConsolaMentoria.iniciar()
  defp ruteo_por_rol("participante"), do: InterfazConsolaProyectos.iniciar()
  defp ruteo_por_rol(_), do: IO.puts(IO.ANSI.red() <> "Rol desconocido" <> IO.ANSI.reset())

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
