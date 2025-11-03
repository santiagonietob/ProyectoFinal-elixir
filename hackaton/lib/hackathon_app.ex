# lib/hackathon_app.ex
defmodule HackathonApp do
  @moduledoc """
  Punto de entrada OTP de la app.
  Inicia el árbol de supervisión (puedes agregar procesos aquí).
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Ejemplos de procesos a iniciar (descomenta si los creas):
      # {Task, fn -> HackathonApp.Adapter.AvancesServidor.iniciar() end},
      # {Registry, keys: :unique, name: HackathonApp.Registry}
    ]

    opts = [strategy: :one_for_one, name: HackathonApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
