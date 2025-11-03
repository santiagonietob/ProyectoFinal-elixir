defmodule HackathonApp.Domain.Equipo do
  @moduledoc "Entidad de equipo participante."
  # activo: true|false
  defstruct [:id, :nombre, :descripcion, :tema, :activo]
end
