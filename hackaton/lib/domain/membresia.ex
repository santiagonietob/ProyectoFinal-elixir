defmodule HackathonApp.Domain.Membresia do
  @moduledoc "Relación usuario–equipo."
  defstruct [:usuario_id, :equipo_id, :rol_en_equipo] # rol_en_equipo: "miembro"|"lider"
end
