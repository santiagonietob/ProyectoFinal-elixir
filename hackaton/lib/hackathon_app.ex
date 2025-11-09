defmodule HackathonApp do
  use Application
  alias HackathonApp.Adapter.InterfazConsolaLogin

  @impl true
  def start(_type, _args) do
    IO.puts("\nIniciando HackathonApp...")

    children = [
      # Arranca el servidor de avances como GenServer (usa start_link/1)
      {HackathonApp.Adapter.AvancesServidor, []},

      # UI: no reiniciar la UI
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
