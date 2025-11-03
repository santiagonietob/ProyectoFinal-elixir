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

  def agregar_fila_si_no_existe!(ruta, fila_lista, id_posicion \\ 0) do
  id_nuevo = Enum.at(fila_lista, id_posicion)

  filas =
    if File.exists?(ruta),
      do: File.read!(ruta) |> String.split("\n", trim: true),
      else: []

  existe = Enum.any?(filas, fn linea ->
    String.starts_with?(linea, id_nuevo <> ",")
  end)

  if not existe do
    File.write!(ruta, Enum.join(fila_lista, ",") <> "\n", [:append])
  end
end

end
