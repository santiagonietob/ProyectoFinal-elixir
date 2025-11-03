defmodule HackathonApp.Domain.Avance do
  @moduledoc "Avance de un proyecto (bitácora)."
  @type t :: %_MODULE_{id: integer(), proyecto_id: integer(), contenido: String.t(), fecha_iso: String.t()}
  defstruct [:id, :proyecto_id, :contenido, :fecha_iso]
end
