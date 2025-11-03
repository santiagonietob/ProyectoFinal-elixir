# lib/service/usuarios_service.ex
defmodule HackathonApp.Service.UsuarioServicio do
  @moduledoc "Registro y consulta de usuarios (CSV)."

  alias HackathonApp.Domain.Usuario
  alias HackathonApp.Adapter.PersistenciaCSV, as: CSV

  @ruta "data/usuarios.csv"

  # ------- Lectura tolerante 4/6 columnas -------
  def listar do
    CSV.leer(@ruta)
    |> Enum.map(fn
      # id,nombre,correo,rol
      [id, n, c, r] ->
        %Usuario{id: String.to_integer(id), nombre: n, correo: c, rol: r, salt: nil, hash: nil}
      # id,nombre,correo,rol,salt,hash
      [id, n, c, r, s, h] ->
        %Usuario{id: String.to_integer(id), nombre: n, correo: c, rol: r, salt: s, hash: h}
    end)
  end

  def buscar_por_nombre(nombre),
    do: Enum.find(listar(), &(&1.nombre == String.trim(nombre)))

  # ------- Registro (compatible) -------
  # Antiguo: registra sin password (no recomendado)
  def registrar(nombre, correo, rol \\ "participante") do
    registrar(nombre, correo, rol, nil)
  end

  # Nuevo: con password (string) -> genera salt+hash
  def registrar(nombre, correo, rol, password) do
    if buscar_por_nombre(nombre) do
      {:error, "Ya existe un usuario con ese nombre"}
    else
      id = siguiente_id()
      {salt, hash} = credenciales(password)

      :ok =
        CSV.agregar(@ruta, [
          to_string(id),
          nombre,
          correo,
          rol,
          salt || "",
          hash || ""
        ])

      {:ok, %Usuario{id: id, nombre: nombre, correo: correo, rol: rol, salt: salt, hash: hash}}
    end
  end

  defp siguiente_id do
    case listar() do
      [] -> 1
      xs -> Enum.max_by(xs, & &1.id).id + 1
    end
  end

  # ------- Helpers de credenciales -------
  defp credenciales(nil), do: {nil, nil}   # compat
  defp credenciales(""), do: {nil, nil}
  defp credenciales(password) do
    salt = :crypto.strong_rand_bytes(16) |> Base.encode64()
    hash =
      :crypto.hash(:sha256, salt <> password)
      |> Base.encode16(case: :lower)
    {salt, hash}
  end
end
