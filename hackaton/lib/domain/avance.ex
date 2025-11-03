defmodule HackathonApp.Domain.Avance do
  @moduledoc "Avance de un proyecto (bitácora de progreso)."

  @enforce_keys [:id, :proyecto_id, :contenido, :fecha_iso]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          id: integer(),
          proyecto_id: integer(),
          contenido: String.t(),
          fecha_iso: String.t()
        }
end
