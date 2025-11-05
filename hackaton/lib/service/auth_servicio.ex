defmodule HackathonApp.Service.AuthServicio do
  @moduledoc """
  Servicio de autenticación por nombre + contraseña (usa hash SHA256 + salt).
  Devuelve el mapa completo del usuario si las credenciales son válidas.
  """

  alias HackathonApp.Service.UsuarioServicio
  alias HackathonApp.Session

  @type login_resp :: {:ok, map()} | {:error, String.t()}

  @spec login(String.t(), String.t()) :: login_resp
  def login(nombre, password) when is_binary(nombre) and is_binary(password) do
    case UsuarioServicio.buscar_por_nombre(nombre) do
      nil ->
        {:error, "Usuario no encontrado"}

      %{salt: nil, hash: nil} = u ->
        if password in [nil, ""],
          do: success(u),
          else: {:error, "Usuario sin contraseña. Pide restablecer."}

      %{salt: salt, hash: hash} = u ->
        calc = :crypto.hash(:sha256, salt <> password) |> Base.encode16(case: :lower)

        if calc == hash do
          success(u)
        else
          {:error, "Contraseña inválida"}
        end
    end
  end

  # ---- Helper privado ----
  defp success(u) do
    # Guardar la sesión activa para todo el sistema
    Session.start(%{id: u.id, nombre: u.nombre, rol: u.rol})
    {:ok, u}
  end
end
