defmodule Hackaton do
  @moduledoc """
  Punto de entrada de la aplicación Hackathon colaborativa.
  """

  alias Hackaton.Adapter.InterfazConsola

  def iniciar do
    InterfazConsola.iniciar()
  end
end
