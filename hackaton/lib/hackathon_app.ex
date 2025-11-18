defmodule HackathonApp do
  use Application
  alias HackathonApp.Adapter.InterfazConsolaLogin

  @impl true
  def start(_type, _args) do
    IO.puts("\nIniciando HackathonApp...")

    base_children = [
      # UI: no reiniciar la UI
      %{
        id: :ui_login,
        start: {Task, :start_link, [fn -> InterfazConsolaLogin.iniciar() end]},
        restart: :temporary,
        shutdown: 5_000,
        type: :worker
      }
    ]

    children =
      base_children
      |> maybe_add_avances_servidor()
      |> maybe_add_chat_servidor()

    Supervisor.start_link(children,
      strategy: :one_for_one,
      name: HackathonApp.Supervisor
    )
  end

  defp maybe_add_avances_servidor(children) do
    case node() do
      :"nodoservidor@192.168.11.103" ->
        children ++
          [
            {HackathonApp.Adapter.AvancesServidor, []}
          ]

      _ ->
        children
    end
  end

  defp maybe_add_chat_servidor(children) do
    case node() do
      :"nodoservidor@192.168.11.103" ->
        children ++
          [
            %{
              id: :chat_servidor,
              start: {Task, :start_link, [fn -> HackathonApp.Adapter.ChatServidor.main() end]},
              restart: :permanent,
              shutdown: 5_000,
              type: :worker
            }
          ]

      _ ->
        children
    end
  end
end
