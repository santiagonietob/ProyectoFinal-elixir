defmodule HackathonApp.Service.ProyectoServicio do
  @moduledoc """
  Registro de proyectos, avances y consultas.
  """

  alias HackathonApp.Domain.{Proyecto, Avance}
  alias HackathonApp.Adapter.PersistenciaCSV, as: CSV
  alias HackathonApp.Adapter.AvancesCliente


  @ruta_proy "data/proyectos.csv"
  @ruta_av "data/avances.csv"

  # ---------- Crear / leer ----------

  @spec crear(integer(), String.t(), String.t()) :: {:ok, Proyecto.t()} | {:error, String.t()}
  def crear(equipo_id, titulo, categoria) do
    id = siguiente_id_proyecto()
    ahora = DateTime.utc_now() |> DateTime.to_iso8601()

    :ok =
      CSV.agregar(@ruta_proy, [
        Integer.to_string(id),
        Integer.to_string(equipo_id),
        limpiar(titulo),
        limpiar(categoria),
        "idea",
        ahora
      ])

    {:ok,
     %Proyecto{
       id: id,
       equipo_id: equipo_id,
       titulo: titulo,
       categoria: categoria,
       estado: "idea",
       fecha_registro: ahora
     }}
  end

  @spec listar() :: [Proyecto.t()]
  def listar do
    CSV.leer(@ruta_proy)
    |> Enum.map(fn [id, eq, t, c, e, f] ->
      %Proyecto{
        id: String.to_integer(id),
        equipo_id: String.to_integer(eq),
        titulo: t,
        categoria: c,
        estado: e,
        fecha_registro: f
      }
    end)
  end

  @spec buscar_por_equipo(String.t()) :: Proyecto.t() | nil
  def buscar_por_equipo(nombre_equipo) do
    case HackathonApp.Service.EquipoServicio.buscar_equipo_por_nombre(nombre_equipo) do
      nil -> nil
      %{id: eq_id} -> Enum.find(listar(), &(&1.equipo_id == eq_id))
    end
  end

  @spec cambiar_estado(integer(), String.t()) :: {:ok, Proyecto.t()} | {:error, String.t()}
  def cambiar_estado(proyecto_id, nuevo_estado)
      when nuevo_estado in ["idea", "en_progreso", "entregado"] do
    proyectos = listar()

    case Enum.find(proyectos, &(&1.id == proyecto_id)) do
      nil ->
        {:error, "Proyecto no existe"}

      %Proyecto{} = p ->
        actualizado = %Proyecto{p | estado: nuevo_estado}
        proyectos2 = reemplazar(proyectos, actualizado)
        reescribir_proyectos(proyectos2)
        {:ok, actualizado}
    end
  end

  def cambiar_estado(_proyecto_id, _otro_estado),
    do: {:error, "Estado inválido (usa: idea|en_progreso|entregado)"}

  # ---------- Avances ----------

 @spec agregar_avance(integer(), String.t()) :: {:ok, Avance.t()} | {:error, String.t()}
def agregar_avance(proyecto_id, contenido) do
  if proyecto?(proyecto_id) do
    id    = siguiente_id_avance()
    fecha = DateTime.utc_now() |> DateTime.to_iso8601()

    :ok =
      CSV.agregar(@ruta_av, [
        Integer.to_string(id),
        Integer.to_string(proyecto_id),
        limpiar(contenido),
        fecha
      ])

    avance = %Avance{id: id, proyecto_id: proyecto_id, contenido: contenido, fecha_iso: fecha}

    # Notificación en tiempo real (IPC nodos)
    AvancesCliente.publicar_avance(avance)  

    {:ok, avance}
  else
    {:error, "Proyecto no existe"}
  end
end

  @spec listar_avances(integer()) :: [Avance.t()]
  def listar_avances(proyecto_id) do
    CSV.leer(@ruta_av)
    |> Enum.filter(fn [_id, p, _c, _f] -> p == Integer.to_string(proyecto_id) end)
    |> Enum.map(fn [id, p, c, f] ->
      %Avance{
        id: String.to_integer(id),
        proyecto_id: String.to_integer(p),
        contenido: c,
        fecha_iso: f
      }
    end)
  end

  @spec filtrar_por_categoria(String.t()) :: [Proyecto.t()]
  def filtrar_por_categoria(cat) do
    listar() |> Enum.filter(&(&1.categoria == String.trim(cat)))
  end

  @spec filtrar_por_estado(String.t()) :: [Proyecto.t()]
  def filtrar_por_estado(est) when est in ["idea", "en_progreso", "entregado"] do
    listar() |> Enum.filter(&(&1.estado == est))
  end

  def filtrar_por_estado(_), do: []

  # ---------- Helpers internos ----------

  defp reescribir_proyectos(proys) do
    filas =
      proys
      |> Enum.map(fn p ->
        [
          Integer.to_string(p.id),
          Integer.to_string(p.equipo_id),
          p.titulo,
          p.categoria,
          p.estado,
          p.fecha_registro
        ]
      end)

    CSV.reescribir(@ruta_proy, filas)
  end

  defp reemplazar(lista, %Proyecto{id: id} = nuevo) do
    Enum.map(lista, fn p -> if p.id == id, do: nuevo, else: p end)
  end

  defp proyecto?(id), do: Enum.any?(listar(), &(&1.id == id))

  defp siguiente_id_proyecto do
    case listar() do
      [] -> 1
      xs -> Enum.max_by(xs, & &1.id).id + 1
    end
  end

  defp siguiente_id_avance do
    CSV.leer(@ruta_av)
    |> Enum.map(fn [id | _] -> String.to_integer(id) end)
    |> case do
      [] -> 1
      xs -> Enum.max(xs) + 1
    end
  end

  defp limpiar(t), do: t |> to_string() |> String.replace("\n", " ") |> String.trim()
end
