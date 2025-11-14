defmodule HackathonApp.Service.ProyectoServicio do
  @moduledoc """
  Gestión de proyectos y avances sobre CSV.
  Estructuras de dominio:
    - HackathonApp.Domain.Proyecto: %{id, equipo_id, titulo, categoria, estado, fecha_registro}
    - HackathonApp.Domain.Avance:   %{id, proyecto_id, contenido, fecha_iso}
  """

  alias HackathonApp.Domain.{Proyecto, Avance}
  alias HackathonApp.Adapter.PersistenciaCSV, as: CSV
  alias HackathonApp.Service.EquipoServicio
  alias HackathonApp.Adapter.AvancesCliente

  @proy_csv "data/proyectos.csv"
  @av_csv "data/avances.csv"

  @estados ~w(idea en_progreso entregado)
  @categorias ~w(web movil ia datos iot otros)

  # ---------- Crear ----------
  @spec crear(integer(), String.t(), String.t()) :: {:ok, Proyecto.t()} | {:error, String.t()}
  def crear(equipo_id, titulo, categoria) when is_integer(equipo_id) do
    t = titulo |> to_string() |> String.trim()
    c = categoria |> to_string() |> String.downcase()

    cond do
      not equipo_existe?(equipo_id) ->
        {:error, "Equipo inexistente"}

      c not in @categorias ->
        {:error, "Categoría inválida"}

      existe_proyecto?(t, equipo_id) ->
        {:error, "Ya existe un proyecto con ese título en el equipo"}

      true ->
        id = siguiente_id_proyecto()
        ahora = DateTime.utc_now() |> DateTime.to_iso8601()

        :ok =
          CSV.agregar(@proy_csv, [
            Integer.to_string(id),
            Integer.to_string(equipo_id),
            t,
            c,
            "idea",
            ahora
          ])

        {:ok,
         %Proyecto{
           id: id,
           equipo_id: equipo_id,
           titulo: t,
           categoria: c,
           estado: "idea",
           fecha_registro: ahora
         }}
    end
  end

  # Wrapper para UI nueva (titulo, _desc, categoria, equipo_id)
  @spec crear(String.t(), any(), String.t(), integer()) ::
          {:ok, Proyecto.t()} | {:error, String.t()}
  def crear(titulo, _desc, categoria, equipo_id) when is_integer(equipo_id) do
    crear(equipo_id, titulo, categoria)
  end

  # ---------- Listar / buscar ----------
  @spec listar() :: [Proyecto.t()]
  def listar do
    CSV.leer(@proy_csv)
    |> Enum.map(fn
      [id, eq, t, c, e, f] ->
        %Proyecto{
          id: String.to_integer(id),
          equipo_id: String.to_integer(eq),
          titulo: t,
          categoria: c,
          estado: e,
          fecha_registro: f
        }

      _ ->
        nil
    end)
    |> Enum.reject(&is_nil/1)
  end

  def listar_proyectos, do: {:ok, listar()}

  def listar_por_equipo(equipo_id) do
    eid = to_int(equipo_id)
    listar() |> Enum.filter(&(&1.equipo_id == eid))
  end

  def buscar_por_equipo(nombre_equipo) do
    case EquipoServicio.buscar_equipo_por_nombre(nombre_equipo) do
      nil -> nil
      %{id: eq_id} -> Enum.find(listar(), &(&1.equipo_id == eq_id))
    end
  end

  def buscar_por_id(proyecto_id) do
    pid = to_int(proyecto_id)
    Enum.find(listar(), &(&1.id == pid))
  end

  # ---------- Filtros ----------
  def filtrar_por_categoria(cat) do
    c = cat |> to_string() |> String.downcase()
    listar() |> Enum.filter(&(&1.categoria == c))
  end

  def filtrar_por_estado(est) do
    e = normalizar_estado(est)
    listar() |> Enum.filter(&(&1.estado == e))
  end

  # ---------- Estados ----------
  def cambiar_estado(proyecto_id, nuevo_estado) do
    pid = to_int(proyecto_id)
    ns = normalizar_estado(nuevo_estado)

    if ns not in @estados,
      do: {:error, "Estado inválido (usa: idea|en_progreso|entregado)"},
      else: do_cambiar_estado(pid, ns)
  end

  defp do_cambiar_estado(pid, ns) do
    filas = CSV.leer(@proy_csv)

    case Enum.split_with(filas, fn [id | _] -> String.to_integer(id) == pid end) do
      {[[_id, eq, t, c, _viejo, f] | _], resto} ->
        nueva = [Integer.to_string(pid), eq, t, c, ns, f]
        :ok = CSV.reescribir(@proy_csv, Enum.reverse([nueva | resto]))
        {:ok, ns}

      _ ->
        {:error, "Proyecto inexistente"}
    end
  end

  # ---------- Avances ----------
  @spec agregar_avance(integer(), String.t()) :: {:ok, Avance.t()} | {:error, String.t()}
  def agregar_avance(proyecto_id, contenido) do
    pid = to_int(proyecto_id)

    if proyecto?(pid) do
      id = siguiente_id_avance()
      fecha = DateTime.utc_now() |> DateTime.to_iso8601()
      limpio = limpiar(contenido)

      :ok =
        CSV.agregar(@av_csv, [
          Integer.to_string(id),
          Integer.to_string(pid),
          limpio,
          fecha
        ])

      avance = %Avance{
        id: id,
        proyecto_id: pid,
        contenido: limpio,
        fecha_iso: fecha
      }

      # Notificar en tiempo real (no bloquear la UI si algo falla)
      _ =
        Task.start(fn ->
          AvancesCliente.publicar_avance(pid, %{
            id: id,
            proyecto_id: pid,
            contenido: limpio,
            mensaje: limpio,
            fecha_iso: fecha,
            timestamp: fecha
          })
        end)

      {:ok, avance}
    else
      {:error, "Proyecto no existe"}
    end
  end

  # ---------- helpers ----------
  defp existe_proyecto?(titulo, equipo_id) do
    t = titulo |> String.downcase()
    listar_por_equipo(equipo_id) |> Enum.any?(fn p -> String.downcase(p.titulo) == t end)
  end

  defp proyecto?(pid), do: buscar_por_id(pid) != nil

  defp equipo_existe?(eid),
    do: HackathonApp.Service.EquipoServicio.listar_todos() |> Enum.any?(&(&1.id == eid))

  defp siguiente_id_proyecto do
    case listar() do
      [] -> 1
      xs -> Enum.max_by(xs, & &1.id).id + 1
    end
  end

  defp siguiente_id_avance do
    CSV.leer(@av_csv)
    |> Enum.map(fn [id | _] -> String.to_integer(id) end)
    |> case do
      [] -> 1
      xs -> Enum.max(xs) + 1
    end
  end

  defp to_int(v) when is_integer(v), do: v
  defp to_int(v), do: v |> to_string() |> String.trim() |> String.to_integer()

  defp normalizar_estado(s) do
    s
    |> to_string()
    |> String.downcase()
    |> case do
      "en_desarrollo" -> "en_progreso"
      "progreso" -> "en_progreso"
      other -> other
    end
  end

  defp limpiar(t), do: t |> to_string() |> String.replace("\n", " ") |> String.trim()
end
