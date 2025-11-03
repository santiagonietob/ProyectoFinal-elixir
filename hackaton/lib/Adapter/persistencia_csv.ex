defmodule Persistencia.CSV do
  @moduledoc "Lectura/escritura CSV sencilla "

  def leer_rutas!(ruta) do
    ruta
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.drop_while(&(&1 == ""))
    |> Enum.map(&String.split(&1, ","))
  end

  def escribir_rutas!(ruta, filas, encabezado \\ nil) do
    contenido =
      (if encabezado, do: [encabezado | filas], else: filas)
      |> Enum.map(&Enum.join(&1, ","))
      |> Enum.join("\n")

    File.write!(ruta, contenido <> "\n")
  end

  def agregar_fila!(ruta, fila_lista) do
    File.write!(ruta, Enum.join(fila_lista, ",") <> "\n", [:append])
  end
end
