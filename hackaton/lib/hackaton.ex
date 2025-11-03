defmodule Hackaton do
  @moduledoc """
  Punto de entrada de la aplicación Hackathon colaborativa.
  """

  alias Hackaton.Adapter.InterfazConsolaEquipos

  def iniciar do
    InterfazConsolaEquipos.iniciar()
  end
end
