defmodule HackathonApp.Domain.Usuario do
  @moduledoc "Entidad de usuario del sistema."
  # rol: "participante"|"mentor"|"organizador"
  defstruct [:id, :nombre, :correo, :rol]
end
