defmodule HackathonApp do
  use Application
  alias HackathonApp.Adapter.InterfazConsolaLogin

  @impl true
  def start(_type, _args) do
    IO.puts("\nIniciando HackathonApp...")

    ui_child = %{
      id: :ui_login,
      start: {Task, :start_link, [fn -> InterfazConsolaLogin.iniciar() end]},
      # <-- clave: NO reiniciar la UI
      restart: :temporary,
      shutdown: 5000,
      type: :worker
    }

    Supervisor.start_link([ui_child], strategy: :one_for_one, name: HackathonApp.Supervisor)
  end
end
