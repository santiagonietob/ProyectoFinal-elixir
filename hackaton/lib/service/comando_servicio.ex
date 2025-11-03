defmodule HackathonApp.Servicios.ComandoServicio do
  @moduledoc """
  Servicio de orquestación de comandos: resuelve usuario y delega en CommandAdapter.
  Garantiza respuestas consistentes {:ok, msg} | {:error, msg}.
  """

  alias HackathonApp.Adaptadores.CommandAdapter
  alias HackathonApp.Servicios.UsuarioServicio

  @type resp :: {:ok, String.t()} | {:error, String.t()}

  @doc """
  Procesa un comando de texto para `nombre_usuario`.
  """
  @spec procesar_comando(String.t() | nil, String.t()) :: resp
  def procesar_comando(input, nombre_usuario) do
    with {:ok, usuario} <- obtener_usuario(nombre_usuario),
         {:ok, cmd} <- normalizar(input) do
      case CommandAdapter.procesar(cmd, usuario.id) do
        {:ok, texto} -> {:ok, texto}
        {:error, texto} when is_binary(texto) -> {:error, texto}
        otro -> {:error, "Error inesperado del adaptador: #{inspect(otro)}"}
      end
    else
      {:error, msg} -> {:error, msg}
    end
  end

  @doc """
  Inicia sesión devolviendo el usuario (si existe).
  """
  @spec iniciar_sesion(String.t()) :: {:ok, map()} | {:error, String.t()}
  def iniciar_sesion(nombre) do
    case UsuarioServicio.buscar_por_nombre(nombre) do
      nil -> {:error, "Usuario no encontrado"}
      usuario -> {:ok, usuario}
    end
  end

  # ---------- Helpers ----------

  # Cambia a {:ok, usuario} | {:error, msg}, así encadena en el with/else.
  defp obtener_usuario(nombre) when is_binary(nombre) do
    nombre = String.trim(nombre)

    if nombre == "" do
      {:error, "Nombre de usuario inválido."}
    else
      case UsuarioServicio.buscar_por_nombre(nombre) do
        nil -> {:error, "Usuario no encontrado. Por favor regístrate primero."}
        usuario -> {:ok, usuario}
      end
    end
  end

  defp obtener_usuario(_), do: {:error, "Nombre de usuario inválido."}

  # Normaliza el comando de entrada y valida vacío/nil
  defp normalizar(nil), do: {:error, "Comando vacío. Usa /help para ver opciones."}

  defp normalizar(input) when is_binary(input) do
    cmd = String.trim(input)
    if cmd == "", do: {:error, "Comando vacío. Usa /help para ver opciones."}, else: {:ok, cmd}
  end
end
