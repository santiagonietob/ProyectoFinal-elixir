defmodule Hackaton.Adapter.PersistenciaCSV do
  @moduledoc "Gestión de archivos CSV para persistencia de datos"

  def leer(ruta) do
    case File.read(ruta) do
      {:ok, contenido} ->
        contenido
        |> String.split("\n", trim: true)
        |> Enum.map(&String.split(&1, ","))
      _ -> []
    end
  end

  def guardar(ruta, fila) do
    File.write!(ruta, Enum.join(fila, ",") <> "\n", [:append])
  end
end
