defmodule HackathonApp.Service.EquipoServicio do
  @moduledoc """
  Gestión de equipos (CSV):
  - Crear equipo (evita duplicados)
  - Listar equipos / activos
  - Unirse a equipo (membresías)
  - Listar miembros y conteo por equipo
  """

  alias HackathonApp.Domain.{Equipo, Membresia}
  alias HackathonApp.Adapter.PersistenciaCSV, as: CSV
  # Si luego usas búsqueda por usuario, descomenta:
  # alias Hackaton.Service.UsuarioServicio

  @equipos_csv "data/equipos.csv"
  @membresias_csv "data/membresias.csv"


  # ---------- EQUIPOS ----------

  @doc "Crea un equipo nuevo (evita duplicado por nombre)"
  @spec crear_equipo(String.t(), String.t(), String.t(), boolean()) ::
          {:ok, Equipo.t()} | {:error, String.t()}
  def crear_equipo(nombre, descripcion, tema, activo \\ true) do
    if Enum.any?(listar_todos(), &(&1.nombre == String.trim(nombre))) do
      {:error, "Ya existe un equipo con ese nombre"}
    else
      id = siguiente_id_equipo()

      :ok =
        CSV.agregar(@equipos_csv, [
          Integer.to_string(id),
          String.trim(nombre),
          String.trim(descripcion || ""),
          String.trim(tema || ""),
          if(activo, do: "true", else: "false")
        ])

      {:ok,
       %Equipo{
         id: id,
         nombre: String.trim(nombre),
         descripcion: descripcion,
         tema: tema,
         activo: activo
       }}
    end
  end

  @doc "Listado completo de equipos"
  @spec listar_todos() :: [Equipo.t()]
  def listar_todos do
    CSV.leer(@equipos_csv)
    |> Enum.map(fn [id, nombre, desc, tema, activo] ->
      %Equipo{
        id: String.to_integer(id),
        nombre: nombre,
        descripcion: desc,
        tema: tema,
        activo: activo in ["true", "1"]
      }
    end)
  end

  @doc "Lista solo equipos activos"
  @spec listar_equipos_activos() :: [Equipo.t()]
  def listar_equipos_activos, do: listar_todos() |> Enum.filter(& &1.activo)

  @doc "Devuelve [{nombre_equipo, conteo_miembros}] para /teams"
  @spec listar_equipos_con_conteo() :: [{String.t(), non_neg_integer()}]
  def listar_equipos_con_conteo do
    listar_equipos_activos()
    |> Enum.map(fn e -> {e.nombre, length(listar_miembros(e.nombre))} end)
  end

  # ---------- MEMBRESÍAS ----------

  @doc "Une un usuario (por id) a un equipo (por nombre). Evita duplicados."
  @spec unirse_a_equipo(String.t(), pos_integer(), String.t()) ::
          {:ok, Equipo.t()} | {:error, String.t()}
  def unirse_a_equipo(nombre_equipo, usuario_id, rol_en_equipo \\ "miembro") do
    with %Equipo{} = equipo <- buscar_equipo_por_nombre(nombre_equipo),
         false <- ya_miembro?(usuario_id, equipo.id) do
      :ok =
        CSV.agregar(@membresias_csv, [
          Integer.to_string(usuario_id),
          Integer.to_string(equipo.id),
          rol_en_equipo
        ])

      {:ok, equipo}
    else
      nil -> {:error, "No existe el equipo #{String.trim(nombre_equipo)}"}
      true -> {:error, "El usuario ya pertenece a #{String.trim(nombre_equipo)}"}
    end
  end

  @doc "Lista membresías (structs) de un equipo por nombre"
  @spec listar_miembros(String.t()) :: [Membresia.t()]
  def listar_miembros(nombre_equipo) do
    case buscar_equipo_por_nombre(nombre_equipo) do
      nil ->
        []

      %Equipo{id: eq_id} ->
        CSV.leer(@membresias_csv)
        |> Enum.filter(fn [_u_id, e_id, _] -> e_id == Integer.to_string(eq_id) end)
        |> Enum.map(fn [u_id, e_id, rol] ->
          %Membresia{
            usuario_id: String.to_integer(u_id),
            equipo_id: String.to_integer(e_id),
            rol_en_equipo: rol
          }
        end)
    end
  end

  # ---------- Helpers ----------

  @doc "Busca equipo por nombre exacto (trim)"
  @spec buscar_equipo_por_nombre(String.t()) :: Equipo.t() | nil
  def buscar_equipo_por_nombre(nombre),
    do: Enum.find(listar_todos(), &(&1.nombre == String.trim(nombre)))

  defp ya_miembro?(usuario_id, equipo_id) do
    CSV.leer(@membresias_csv)
    |> Enum.any?(fn [u, e, _] ->
      u == Integer.to_string(usuario_id) and e == Integer.to_string(equipo_id)
    end)
  end

  defp siguiente_id_equipo do
    case listar_todos() do
      [] -> 1
      xs -> Enum.max_by(xs, & &1.id).id + 1
    end
  end

   @doc "Lista todos los equipos (sin filtrar)."
  @spec listar_equipos() :: {:ok, [Equipo.t()]} | {:error, String.t()}
  def listar_equipos do
    try do
      filas = CSV.leer(@equipos_csv)

      equipos =
        Enum.map(filas, fn
          # Espera columnas: id,nombre,descripcion,tema,activo
          [id, nombre, descripcion, tema, activo_str] ->
            %Equipo{
              id: id,
              nombre: nombre,
              descripcion: descripcion,
              tema: tema,
              activo: String.downcase(to_string(activo_str)) in ["true", "1", "sí", "si", "yes"]
            }

          # Si vienen menos columnas (defensivo)
          [id, nombre, descripcion, tema] ->
            %Equipo{ id: id, nombre: nombre, descripcion: descripcion, tema: tema, activo: true }

          otra ->
            # Línea malformada: la ignoramos (o podrías loguearla)
            _ = otra
            nil
        end)
        |> Enum.reject(&is_nil/1)

      {:ok, equipos}
    rescue
      e -> {:error, "No se pudieron leer los equipos: #{Exception.message(e)}"}
    end
  end

  @doc "Lista sólo los equipos activos (activo=true)."
  @spec listar_equipos_activos() :: {:ok, [Equipo.t()]} | {:error, String.t()}
  def listar_equipos_activos do
    with {:ok, equipos} <- listar_equipos() do
      {:ok, Enum.filter(equipos, & &1.activo)}
    end
  end

end
