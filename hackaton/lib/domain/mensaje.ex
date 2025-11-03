defmodule Domain.Mensaje do
  @moduledoc "Mensaje de chat."
  defstruct [:equipo_id, :usuario_id, :texto, :fecha_iso]
end
