# lib/domain/usuario.ex
defmodule HackathonApp.Domain.Usuario do
  @moduledoc "Entidad de usuario del sistema."
  # rol: "participante"|"mentor"|"organizador"
  # NUEVO: :salt y :hash para autenticación
  defstruct [:id, :nombre, :correo, :rol, :salt, :hash]
end
