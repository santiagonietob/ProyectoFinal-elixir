defmodule HackathonApp.Domain.Usuario do
  @moduledoc "Entidad de usuario del sistema."
  defstruct [:id, :nombre, :correo, :rol] # rol: "participante"|"mentor"|"organizador"
end
