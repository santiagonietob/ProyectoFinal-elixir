# lib/hackaton.ex
defmodule Hackaton do
  @moduledoc "Punto de entrada de la app."
  def hello, do: :world   # Para que pase el test de ejemplo
  def iniciar, do: Hackaton.Adapter.InterfazConsola.iniciar()
end
