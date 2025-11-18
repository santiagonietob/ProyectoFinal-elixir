defmodule HackathonApp do
  @moduledoc """
  Punto de entrada OTP de la app.
  Inicia el árbol de supervisión.
  """

  use Application
  alias HackathonApp.Adapter.InterfazConsolaLogin

  @impl true
  def start(_type, _args) do
    children = [
      # Servidor de difusión de avances (proceso simple con receive/loop)
      %{
        id: :avances_servidor,
        start: {Task, :start_link, [fn -> HackathonApp.Adapter.AvancesServidor.iniciar() end]},
        restart: :permanent,
        shutdown: 5_000,
        type: :worker
      },

      # UI de login en consola (no se reinicia)
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
