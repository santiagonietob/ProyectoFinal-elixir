defmodule HackathonApp.Domain.Membresia do
  @moduledoc "Relación usuario–equipo."
  # rol_en_equipo: "miembro"|"lider"
  defstruct [:usuario_id, :equipo_id, :rol_en_equipo]
end
