defmodule HackathonApp.Dominios.Comando do
  @moduledoc """
  Parser de comandos de consola (capa dominio, sin E/S).
  Convención de retorno:
    {:ok, comando :: String.t(), args :: [String.t()]} | {:error, motivo}
  """

  # Lista de comandos disponibles y sus descripciones
  @comandos %{
    "teams"   => "Lista equipos activos",
    "join"    => "Unirse a un equipo: /join <equipo>",
    "project" => "Ver proyecto de un equipo: /project <equipo>",
    "chat"    => "Enviar mensaje al chat: /chat <equipo> <mensaje>",
    "help"    => "Muestra esta ayuda"
  }

  @type parse_result :: {:ok, String.t(), [String.t()]} | {:error, String.t()}

  @doc """
  Parsea una línea de entrada. Acepta con o sin '/' inicial.
  No hace I/O ni llama servicios.
  """
  @spec interpretar_comando(String.t()) :: parse_result
  def interpretar_comando(texto) when is_binary(texto) do
    texto = String.trim(texto)

    if texto == "" do
      {:error, "Entrada vacía. Usa /help para ver los comandos disponibles."}
    else
      do_parse(quitar_barra(texto))
    end
  end

  # ----------------- Helpers de parseo -----------------

  # /help  |  help
  defp do_parse(linea) do
    [cmd | rest] = String.split(linea, " ", parts: 2)
    cmd = String.downcase(cmd)

    case cmd do
      "help"   -> {:ok, "help", []}
      "teams"  -> {:ok, "teams", []}

      "join" ->
        case rest do
          [equipo] when equipo != "" -> {:ok, "join", [equipo]}
          _ -> {:error, "Uso: /join <equipo>"}
        end

      "project" ->
        case rest do
          [equipo] when equipo != "" -> {:ok, "project", [equipo]}
          _ -> {:error, "Uso: /project <equipo>"}
        end

      "chat" ->
        case rest do
          [resto] ->
            case String.split(resto, " ", parts: 2) do
              [equipo, mensaje] when equipo != "" and String.trim(mensaje) != "" ->
                {:ok, "chat", [equipo, mensaje]}
              _ ->
                {:error, "Uso: /chat <equipo> <mensaje>"}
            end

          _ -> {:error, "Uso: /chat <equipo> <mensaje>"}
        end

      _ ->
        {:error, "Comando no reconocido. Usa /help para ver los comandos disponibles."}
    end
  end

  defp quitar_barra("/" <> resto), do: resto
  defp quitar_barra(otro), do: otro

  @doc """
  Devuelve lista de {comando, descripción} para que el Adapter la formatee.
  """
  @spec listar_comandos() :: [{String.t(), String.t()}]
  def listar_comandos do
    @comandos |> Enum.into([]) |> Enum.sort()
  end
end
