# Módulo: Comando
# Descripción: Procesa e interpreta comandos de texto ingresados por
# los usuarios en la interfaz de consola.
#
# Relaciones con otros módulos:
# - ComandoServicio: Utiliza este módulo para procesar comandos
# - Interactúa indirectamente con todos los servicios

defmodule HackathonApp.Dominios.Comando do
  @moduledoc """
  Define la estructura y procesamiento de comandos de consola.
  Los comandos permiten a los usuarios interactuar con el sistema
  usando una sintaxis simple tipo '/comando argumento'.
  """

  # Lista de comandos disponibles y sus descripciones
  @comandos %{
    "teams" => "Lista equipos activos",
    "join" => "Unirse a un equipo: /join <equipo>",
    "project" => "Ver proyecto de un equipo: /project <equipo>",
    "chat" => "Entrar al chat de un equipo: /chat <equipo>",
    "help" => "Muestra esta ayuda"
  }

  @doc """
  Analiza un comando ingresado por el usuario y lo descompone en sus partes.

  Parámetros:
    - texto_comando: Texto completo del comando (ej: "/join Alpha")

  Retorna:
    - {:ok, comando, argumentos} si el comando es válido
    - {:error, mensaje} si el comando no es reconocido
  """
  def interpretar_comando(texto_comando) when is_binary(texto_comando) do
    case String.split(String.trim(texto_comando), " ", parts: 2) do
      [comando | argumentos] ->
        nombre_comando = String.replace_prefix(comando, "/", "")
        if Map.has_key?(@comandos, nombre_comando) do
          {:ok, nombre_comando, List.to_string(argumentos)}
        else
          {:error, "Comando no reconocido. Usa /help para ver los comandos disponibles."}
        end
      _ ->
        {:error, "Formato inválido. Los comandos deben empezar con /"}
    end
  end

  @doc """
  Devuelve la lista de todos los comandos disponibles con sus descripciones.
  Útil para mostrar la ayuda del sistema.
  """
  def obtener_comandos_disponibles do
    @comandos
  end
end
