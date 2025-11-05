defmodule HackathonApp.Adapter.InterfazConsolaMentoria do
  @moduledoc "Menú de mentoría para la CLI (stub)."
  alias HackathonApp.Session

  def iniciar do
    IO.puts("\n=== MENÚ DE MENTORÍA ===")

    case Session.current() do
      nil -> IO.puts("No hay sesión activa.")
      %{nombre: nombre, rol: rol} -> IO.puts("Mentor: #{nombre} (#{rol})")
    end

    loop()
  end

  defp loop do
    IO.puts("""
    1) Ver equipos
    2) Ver proyectos (en construcción)
    0) Volver
    """)

    IO.write("> ")
    case IO.gets("") |> to_str() do
      "1" ->
        # Si ya tienes esta interfaz, la llamas; si no, solo muestra un placeholder.
        try do
          HackathonApp.Adapter.InterfazConsolaEquipos.iniciar()
        rescue
          _ -> IO.puts("Interfaz de equipos no disponible (stub).")
        end
        loop()

      "2" ->
        IO.puts("Sección de proyectos en construcción.")
        loop()

      "0" ->
        :ok

      _ ->
        IO.puts("Opción inválida")
        loop()
    end
  end

  defp to_str(nil), do: ""
  defp to_str(s), do: String.trim(s)
end
