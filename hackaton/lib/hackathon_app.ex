defmodule HackathonApp do
  use Application
  alias HackathonApp.Adapter.InterfazConsolaLogin

  @impl true
  def start(_type, _args) do
    IO.puts("\nIniciando HackathonApp...")

    children = [
      # Servidor de avances (broadcast de avances de proyectos)
      {HackathonApp.Adapter.AvancesServidor, []},

      # Canal general de anuncios
      {HackathonApp.Adapter.CanalGeneral, []},

      # Gestor de salas temáticas de chat
      {HackathonApp.Adapter.SalasTematicas, []},

      # UI: pantalla de login (no se reinicia automáticamente)
      %{
        id: :ui_login,
        start: {Task, :start_link, [fn -> InterfazConsolaLogin.iniciar() end]},
        restart: :temporary,
        shutdown: 5_000,
        type: :worker
      }
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: HackathonApp.Supervisor)
  end
end
