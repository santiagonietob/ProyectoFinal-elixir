# lib/service/usuario_servicio.ex
defmodule Hackaton.Service.UsuarioServicio do
  alias Hackaton.Domain.Usuario
  alias Hackaton.Adapter.PersistenciaCSV

  @usuarios_csv "priv/usuarios.csv"

  def registrar(nombre, correo, rol \\ "participante") do
    id = System.unique_integer([:positive])
    PersistenciaCSV.agregar(@usuarios_csv, [to_string(id), nombre, correo, rol])
    {:ok, %Usuario{id: id, nombre: nombre, correo: correo, rol: rol}}
  end

  def listar() do
    PersistenciaCSV.leer(@usuarios_csv)
    |> Enum.map(fn [id,nombre,correo,rol] ->
      %Usuario{id: String.to_integer(id), nombre: nombre, correo: correo, rol: rol}
    end)
  end

  def buscar_por_nombre(nombre),
    do: listar() |> Enum.find(&(&1.nombre == nombre))
end
