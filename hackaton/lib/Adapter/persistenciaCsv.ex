defmodule HackathonApp.Adapter.PersistenciaCSV do
  @moduledoc "Lectura/escritura simple de CSV con encabezado."
  @type fila :: [String.t()]
  

  def leer(ruta) do
    case File.read(ruta) do
      {:ok, contenido} ->
        contenido
        |> String.split("\n", trim: true)
        |> Enum.drop_while(&(&1 == "")) # evita líneas vacías
        |> drop_encabezado()
        |> Enum.map(&String.split(&1, ","))
      _ -> []
    end
  end

 @spec agregar(String.t(), fila) :: :ok
  def agregar(ruta, fila) when is_list(fila) do
    if not File.exists?(ruta), do: crear_con_encabezado(ruta)
    File.write!(ruta, Enum.join(fila, ",") <> "\n", [:append])
    :ok
  end
  @spec reescribir(String.t(), [fila]) :: :ok
def reescribir(ruta, filas) do
  unless File.exists?(ruta), do: crear_con_encabezado(ruta)
  encabezado = File.read!(ruta) |> String.split("\n", parts: 2) |> hd()

  cuerpo =
    filas
    |> Enum.map(&Enum.join(&1, ","))
    |> Enum.join("\n")

  File.write!(ruta, [encabezado, "\n", cuerpo, if(cuerpo == "", do: "", else: "\n")])
  :ok
end


  defp drop_encabezado([_enc | resto]), do: resto
  defp drop_encabezado([]), do: []

  # Si el archivo no existía, asumimos encabezado por nombre del archivo
  defp crear_con_encabezado(ruta) do
    enc =
      cond do
        String.ends_with?(ruta, "usuarios.csv")    -> "id,nombre,correo,rol"
        String.ends_with?(ruta, "equipos.csv")     -> "id,nombre,descripcion,tema,activo"
        String.ends_with?(ruta, "membresias.csv")  -> "usuario_id,equipo_id,rol_en_equipo"
        true -> "col1,col2,col3"
      end
    File.write!(ruta, enc <> "\n")
  end

  defp encabezado_y_cols(ruta) do
    {:ok, contenido} = File.read(ruta)
    [enc | _] = String.split(contenido, "\n", parts: 2)
    {enc, length(String.split(enc, ","))}
  end
end
