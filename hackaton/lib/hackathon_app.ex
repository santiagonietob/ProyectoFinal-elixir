defmodule HackathonApp do
  use Application
  alias HackathonApp.Adapter.InterfazConsolaLogin

  @impl true
  def start(_type, _args) do
    IO.puts("\nIniciando HackathonApp...")

    base_children = [
      # Servidor de avances como GenServer (usa start_link/1)
      {HackathonApp.Adapter.AvancesServidor, []},

      # UI de login: no reiniciar la UI si se cierra
      %{
        id: :ui_login,
        start: {Task, :start_link, [fn -> InterfazConsolaLogin.iniciar() end]},
        restart: :temporary,
        shutdown: 5_000,
        type: :worker
      }
    ]

    children = maybe_add_chat_server(base_children)

    Supervisor.start_link(children,
      strategy: :one_for_one,
      name: HackathonApp.Supervisor
    )
  end

  # Solo el nodo servidor levanta el ChatServidor
  defp maybe_add_chat_server(children) do
    case node() do
      # AJUSTA ESTE NOMBRE AL QUE USES EN EL SERVIDOR
      # ej: elixir --name nodoservidor@192.168.11.103 -S mix run --no-halt
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

      # En los demás nodos (clientes) no se arranca el servidor de chat
      _ ->
        children
    end
  end
end
