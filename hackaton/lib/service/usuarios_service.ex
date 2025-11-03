defmodule Hackaton.Service.UsuariosService do
  @moduledoc "Lógica de negocio para manejar usuarios"
  alias Hackaton.Domain.Usuario
  alias Hackaton.Adapter.PersistenciaCSV

  @ruta "datos/usuarios.csv"

  def registrar_usuario(nombre, correo, rol) do
    usuarios = listar_usuarios()
    id = length(usuarios) + 1
    nuevo = %Usuario{id: id, nombre: nombre, correo: correo, rol: rol}
    PersistenciaCSV.guardar(@ruta, [id, nombre, correo, rol])
    {:ok, nuevo}
  end

  def listar_usuarios do
    PersistenciaCSV.leer(@ruta)
    |> Enum.map(fn [id, n, c, r] -> %Usuario{id: String.to_integer(id), nombre: n, correo: c, rol: r} end)
  end
end
