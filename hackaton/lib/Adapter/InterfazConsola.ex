defmodule HackathonApp.Adapter.InterfazConsola do
  @moduledoc "Interfaz principal del sistema HackathonApp"
  alias HackathonApp.Adapter.{
    InterfazConsolaEquipos,
    InterfazConsolaProyectos,
    InterfazConsolaChat,
    InterfazConsolaMentoria,
    InterfazConsolaLogin
  }

  def iniciar do
    HackathonApp.Guard.ensure_role!("organizador")

    IO.puts(IO.ANSI.cyan() <> "\n══════════════════════════════════════")
    IO.puts("=== HACKATHON COLABORATIVA ===")
    IO.puts("══════════════════════════════════════" <> IO.ANSI.reset() <> "\n")

    IO.puts(IO.ANSI.green() <> "1) Gestión de equipos" <> IO.ANSI.reset())
    IO.puts(IO.ANSI.green() <> "2) Gestión de proyectos" <> IO.ANSI.reset())
    IO.puts(IO.ANSI.green() <> "3) Comunicación en tiempo real" <> IO.ANSI.reset())
    IO.puts(IO.ANSI.green() <> "4) Mentoría y retroalimentación" <> IO.ANSI.reset())
    IO.puts(IO.ANSI.green() <> "5) Modo comandos (/help, /teams, /project...)" <> IO.ANSI.reset())
    IO.puts("0) Salir")

    case IO.gets("> ") |> String.trim() do
      "1" ->
        InterfazConsolaEquipos.iniciar()
        iniciar()

      "2" ->
        InterfazConsolaProyectos.iniciar()
        iniciar()

      "3" ->
        InterfazConsolaChat.iniciar()
        iniciar()

      "4" ->
        InterfazConsolaMentoria.iniciar()
        iniciar()

      "5" ->
        HackathonApp.Adapter.ComandosCLI.iniciar()
        iniciar()

      "0" ->
        IO.puts("Hasta pronto!")
        InterfazConsolaLogin.iniciar()

      _ ->
        IO.puts(IO.ANSI.red() <> "Opción inválida" <> IO.ANSI.reset())
        iniciar()
    end
  end
end
