defmodule HackathonApp.Domain.Proyecto do
  @moduledoc "Entidad de proyecto. estado: \"idea\"|\"en_progreso\"|\"entregado\""
  @type t :: %_MODULE_{
          id: integer(), equipo_id: integer(), titulo: String.t(),
          categoria: String.t(), estado: String.t(), fecha_registro: String.t()
        }
  defstruct [:id, :equipo_id, :titulo, :categoria, :estado, :fecha_registro]
end
