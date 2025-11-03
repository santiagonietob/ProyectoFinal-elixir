defmodule HackathonApp.Adapter.PersistenciaCSV do
  @moduledoc "Lectura/escritura simple de CSV con encabezado."
  @type fila :: [String.t()]

  @spec leer(String.t()) :: [fila]
  def leer(ruta) do
    case File.read(ruta) do
      {:ok, contenido} ->
        contenido
        |> String.split("\n", trim: true)
        |> Enum.drop_while(&(&1 == ""))
        |> drop_encabezado()
        |> Enum.map(&String.split(&1, ","))
      _ -> []
    end
  end

  @spec agregar(String.t(), fila) :: :ok
  def agregar(ruta, fila) when is_list(fila) do
    ensure_dir!(ruta)
    unless File.exists?(ruta), do: crear_con_encabezado(ruta)
    File.write!(ruta, Enum.join(fila, ",") <> "\n", [:append])
    :ok
  end

  @spec reescribir(String.t(), [fila]) :: :ok
  def reescribir(ruta, filas) do
    ensure_dir!(ruta)
    unless File.exists?(ruta), do: crear_con_encabezado(ruta)

    encabezado =
      case File.read(ruta) do
        {:ok, contenido} -> contenido |> String.split("\n", parts: 2) |> hd()
        _ -> default_header(ruta)
      end

    cuerpo =
      filas
      |> Enum.map(&Enum.join(&1, ","))
      |> Enum.join("\n")

    contenido = if cuerpo == "", do: encabezado <> "\n", else: encabezado <> "\n" <> cuerpo <> "\n"
    File.write!(ruta, contenido)
    :ok
  end

  # --------- helpers ---------

  defp ensure_dir!(ruta) do
    ruta |> Path.dirname() |> File.mkdir_p!()
  end

  defp drop_encabezado([_enc | resto]), do: resto
  defp drop_encabezado([]), do: []

  defp crear_con_encabezado(ruta) do
    File.write!(ruta, default_header(ruta) <> "\n")
  end

  defp default_header(ruta) do
    cond do
      String.ends_with?(ruta, "usuarios.csv")    -> "id,nombre,correo,rol"
      String.ends_with?(ruta, "equipos.csv")     -> "id,nombre,descripcion,tema,activo"
      String.ends_with?(ruta, "membresias.csv")  -> "usuario_id,equipo_id,rol_en_equipo"
      String.ends_with?(ruta, "proyectos.csv")   -> "id,equipo_id,titulo,categoria,estado,fecha_registro"
      String.ends_with?(ruta, "avances.csv")     -> "id,proyecto_id,contenido,fecha_iso"
      String.ends_with?(ruta, "mensajes.csv")    -> "id,equipo_id,usuario_id,texto,fecha_iso"
      true -> "col1,col2,col3"
    end
  end
end
