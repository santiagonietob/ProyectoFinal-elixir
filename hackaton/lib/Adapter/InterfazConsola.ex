defmodule HackathonApp.Adapter.InterfazConsola do
  @moduledoc "Interfaz principal del sistema HackathonApp"
  alias HackathonApp.Adapter.{
    InterfazConsolaEquipos,
    InterfazConsolaProyectos,
    InterfazConsolaChat,
    InterfazConsolaMentoria
  }

  def iniciar do
    HackathonApp.Guard.ensure_role!("organizador")
    IO.puts("\n=== HACKATHON COLABORATIVA ===\n")
    IO.puts("1) Gestión de equipos")
    IO.puts("2) Gestión de proyectos")
    IO.puts("3) Comunicación en tiempo real")
    IO.puts("4) Mentoría y retroalimentación")
    IO.puts("5) Modo comandos (/help, /teams, /project...)")
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

      _ ->
        IO.puts("Opción inválida")
        iniciar()
    end
  end
end
