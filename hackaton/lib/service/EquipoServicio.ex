defmodule HackathonApp.Service.EquipoServicio do
  @moduledoc """
  Gestión de equipos y membresías sobre CSV.

  Archivos:
    - data/equipos.csv     -> id,nombre,descripcion,tema,activo
    - data/membresias.csv  -> usuario_id,equipo_id,rol_en_equipo
  """

  alias HackathonApp.Domain.{Equipo, Membresia}
  alias HackathonApp.Adapter.PersistenciaCSV, as: CSV
  alias HackathonApp.Service.UsuarioServicio

  @equipos_csv "data/equipos.csv"
  @membresias_csv "data/membresias.csv"

  @roles_validos ~w(miembro lider)

  # -------------------------
  # Crear / Listar / Buscar
  # -------------------------

  @doc "Crea un equipo si no existe otro con el mismo nombre (case-insensitive)."
  @spec crear_equipo(String.t(), String.t(), String.t(), boolean()) ::
          {:ok, Equipo.t()} | {:error, String.t()}
  def crear_equipo(nombre, descripcion, tema, activo \\ true) do
    n = nombre |> to_string() |> String.trim()
    n_down = String.downcase(n)

    existe? =
      listar_todos()
      |> Enum.any?(fn e -> String.downcase(e.nombre) == n_down end)

    if existe? do
      {:error, "Ya existe un equipo con ese nombre"}
    else
      id = siguiente_id_equipo()
      desc = to_string(descripcion) |> String.trim()
      tema_norm = to_string(tema) |> String.trim()
      activo_str = if(activo, do: "true", else: "false")

      :ok =
        CSV.agregar(@equipos_csv, [
          Integer.to_string(id),
          n,
          desc,
          tema_norm,
          activo_str
        ])

      {:ok, %Equipo{id: id, nombre: n, descripcion: descripcion, tema: tema, activo: activo}}
    end
  end

  @doc "Lista todos los equipos (retorna lista)."
  @spec listar_todos() :: [Equipo.t()]
  def listar_todos do
    CSV.leer(@equipos_csv)
    |> Enum.map(fn
      # id,nombre,descripcion,tema,activo
      [id, nombre, desc, tema, activo] ->
        %Equipo{
          id: String.to_integer(id),
          nombre: nombre,
          descripcion: desc,
          tema: tema,
          activo: activo in ["true", "1"]
        }

      # tolerancia mínima si no hay todas las columnas
      [id, nombre] ->
        %Equipo{
          id: String.to_integer(id),
          nombre: nombre,
          descripcion: "",
          tema: "",
          activo: true
        }
    end)
  end

  @doc "Wrapper de compatibilidad que devuelve {:ok, lista}."
  @spec listar_equipos() :: {:ok, [Equipo.t()]}
  def listar_equipos, do: {:ok, listar_todos()}

  @doc "Lista sólo equipos activos (retorna lista)."
  @spec listar_equipos_activos() :: [Equipo.t()]
  def listar_equipos_activos, do: listar_todos() |> Enum.filter(& &1.activo)

 @doc "Busca equipo por id (entero)."
@spec buscar_equipo_por_id(non_neg_integer) :: Equipo.t() | nil
def buscar_equipo_por_id(equipo_id) do
  Enum.find(listar_todos(), &(&1.id == equipo_id))
end

  @doc "Devuelve [{nombre_equipo, conteo_miembros}] (para /teams)."
  @spec listar_equipos_con_conteo() :: [{String.t(), non_neg_integer}]
  def listar_equipos_con_conteo do
    miembros = CSV.leer(@membresias_csv)

    listar_todos()
    |> Enum.map(fn e ->
      c =
        miembros
        |> Enum.count(fn [_u, e_id, _rol] -> e_id == Integer.to_string(e.id) end)

      {e.nombre, c}
    end)
  end

  # -------------------------
  # Membresías
  # -------------------------

  @doc """
  Une un usuario a un equipo por nombre.
  Valida: rol válido, existencia de equipo y usuario, y no duplicar membresía.
  """
  @spec unirse_a_equipo(String.t(), non_neg_integer, String.t()) ::
          {:ok, Equipo.t()} | {:error, String.t()}
  def unirse_a_equipo(nombre_equipo, usuario_id, rol_en_equipo \\ "miembro") do
    rol = rol_en_equipo |> to_string() |> String.downcase()

    cond do
      rol not in @roles_validos ->
        {:error, "Rol inválido"}

      is_nil(buscar_equipo_por_nombre(nombre_equipo)) ->
        {:error, "Equipo inexistente"}

      not usuario_existe?(usuario_id) ->
        {:error, "Usuario inexistente"}

      true ->
        %Equipo{id: eq_id} = buscar_equipo_por_nombre(nombre_equipo)

        if ya_miembro?(usuario_id, eq_id) do
          {:error, "Ya pertenece al equipo"}
        else
          :ok =
            CSV.agregar(@membresias_csv, [
              Integer.to_string(usuario_id),
              Integer.to_string(eq_id),
              rol
            ])

          {:ok, %Equipo{id: eq_id, nombre: nombre_equipo}}
        end
    end
  end

  @doc "Lista las membresías de un equipo por **id**."
  @spec listar_miembros_por_id(non_neg_integer) :: [Membresia.t()]
  def listar_miembros_por_id(equipo_id) do
    CSV.leer(@membresias_csv)
    |> Enum.filter(fn [_u, e, _] -> e == Integer.to_string(equipo_id) end)
    |> Enum.map(fn [u_id, e_id, rol] ->
      %Membresia{
        usuario_id: String.to_integer(u_id),
        equipo_id: String.to_integer(e_id),
        rol_en_equipo: rol
      }
    end)
  end

  @doc "Lista las membresías de un equipo por **nombre** (azúcar)."
  @spec listar_miembros(String.t()) :: [Membresia.t()]
  def listar_miembros(nombre_equipo) do
    case buscar_equipo_por_nombre(nombre_equipo) do
      %Equipo{id: eq_id} -> listar_miembros_por_id(eq_id)
      _ -> []
    end
  end

  @doc """
Elimina un equipo por nombre *o* id. También borra sus membresías.
Retorna: {:ok, nombre, id, cantidad_membresias_borradas} | {:error, motivo}
"""
@spec eliminar_equipo(String.t() | integer()) ::
        {:ok, String.t(), non_neg_integer, non_neg_integer} | {:error, String.t()}
def eliminar_equipo(ident) do
  {eq, id} =
    case ident do
      i when is_integer(i) ->
        case buscar_equipo_por_id(i) do
          nil -> {nil, nil}
          e   -> {e, i}
        end

      s when is_binary(s) ->
        s = String.trim(s)

        case Integer.parse(s) do
          {i, ""} ->
            case buscar_equipo_por_id(i) do
              nil -> {nil, nil}
              e   -> {e, i}
            end

          _ ->
            case buscar_equipo_por_nombre(s) do
              nil -> {nil, nil}
              %Equipo{id: i} = e -> {e, i}
            end
        end
    end

  if is_nil(eq) do
    {:error, "Equipo inexistente"}
  else
    id_str = Integer.to_string(id)

    # 1) Reescribir equipos.csv SIN el equipo
    filas_eq = CSV.leer(@equipos_csv)
    nuevas_eq = Enum.reject(filas_eq, fn [idc | _] -> idc == id_str end)
    :ok = CSV.reescribir(@equipos_csv, nuevas_eq)

    # 2) Reescribir membresias.csv SIN las del equipo
    filas_mem = CSV.leer(@membresias_csv)
    {quedan, borradas} =
      Enum.split_with(filas_mem, fn [_u, e_id, _rol] -> e_id != id_str end)

    :ok = CSV.reescribir(@membresias_csv, quedan)

    {:ok, eq.nombre, id, length(borradas)}
  end
end

  # -------------------------
  # Helpers privados
  # -------------------------

  defp usuario_existe?(usuario_id) do
    UsuarioServicio.listar()
    |> Enum.any?(fn u -> u.id == usuario_id end)
  end

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
end
