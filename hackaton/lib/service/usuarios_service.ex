defmodule HackathonApp.Service.UsuarioServicio do
  @moduledoc "Registro y consulta de usuarios (CSV)."

  alias HackathonApp.Domain.Usuario
  alias HackathonApp.Adapter.PersistenciaCSV, as: CSV

  @ruta "data/usuarios.csv"

  def listar do
    CSV.leer(@ruta)
    |> Enum.map(fn [id, n, c, r] ->
      %Usuario{id: String.to_integer(id), nombre: n, correo: c, rol: r}
    end)
  end

  def buscar_por_nombre(nombre) do
    Enum.find(listar(), &(&1.nombre == String.trim(nombre)))
  end

  def registrar(nombre, correo, rol \\ "participante") do
    if buscar_por_nombre(nombre) do
      {:error, "Ya existe un usuario con ese nombre"}
    else
      id = siguiente_id()
      :ok = CSV.agregar(@ruta, [to_string(id), nombre, correo, rol])
      {:ok, %Usuario{id: id, nombre: nombre, correo: correo, rol: rol}}
    end
  end

  defp siguiente_id do
    case listar() do
      [] -> 1
      xs -> Enum.max_by(xs, & &1.id).id + 1
    end
  end
end
