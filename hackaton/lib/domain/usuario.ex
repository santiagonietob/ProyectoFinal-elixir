defmodule Hackaton.Domain.Usuario do
  @moduledoc "Entidad que representa un usuario del sistema"
  defstruct [:id, :nombre, :correo, :rol]
end
