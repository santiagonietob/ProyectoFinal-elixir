defmodule HackathonApp.Domain.Equipo do
  @moduledoc "Entidad de equipo participante."
  defstruct [:id, :nombre, :descripcion, :tema, :activo] # activo: true|false
end
