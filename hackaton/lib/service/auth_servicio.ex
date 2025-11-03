# lib/service/auth_servicio.ex
defmodule HackathonApp.Service.AuthServicio do
  @moduledoc "Autenticación por nombre + contraseña (hash+salt)."

  alias HackathonApp.Service.UsuarioServicio

  @type login_resp :: {:ok, map()} | {:error, String.t()}

  @spec login(String.t(), String.t()) :: login_resp
  def login(nombre, password) when is_binary(nombre) and is_binary(password) do
    case UsuarioServicio.buscar_por_nombre(nombre) do
      nil ->
        {:error, "Usuario no encontrado"}

      %{salt: nil, hash: nil} = u ->
        if password in [nil, ""],
          do: {:ok, u},
          else: {:error, "Usuario sin contraseña. Pide restablecer."}

      %{salt: salt, hash: hash} = u ->
        calc = :crypto.hash(:sha256, salt <> password) |> Base.encode16(case: :lower)
        if calc == hash, do: {:ok, u}, else: {:error, "Contraseña inválida"}
    end
  end
end
