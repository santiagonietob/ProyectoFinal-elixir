defmodule HackathonApp.Domain.Proyecto do
  @moduledoc "Entidad de proyecto (estado: idea | en_progreso | entregado)."

  @enforce_keys [:id, :equipo_id, :titulo, :categoria, :estado, :fecha_registro]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          id: integer(),
          equipo_id: integer(),
          titulo: String.t(),
          categoria: String.t(),
          estado: String.t(),
          fecha_registro: String.t()
        }
end
