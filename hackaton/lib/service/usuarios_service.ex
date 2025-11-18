# lib/service/usuarios_service.ex
defmodule HackathonApp.Service.UsuarioServicio do
  @moduledoc "Registro y consulta de usuarios (CSV)."

  alias HackathonApp.Domain.Usuario
  alias HackathonApp.Adapter.PersistenciaCSV, as: CSV

  @ruta "data/usuarios.csv"

  # ------- Lectura tolerante 4/6 columnas -------
  def listar do
    CSV.leer(@ruta)
    |> Enum.map(fn
      # id,nombre,correo,rol
      [id, n, c, r] ->
        %Usuario{id: String.to_integer(id), nombre: n, correo: c, rol: r, salt: nil, hash: nil}

      # id,nombre,correo,rol,salt,hash
      [id, n, c, r, s, h] ->
        %Usuario{id: String.to_integer(id), nombre: n, correo: c, rol: r, salt: s, hash: h}
    end)
  end

  def buscar_por_nombre(nombre),
    do: Enum.find(listar(), &(&1.nombre == String.trim(nombre)))

  def buscar_por_correo(correo) do
    correo = String.trim(correo || "")
    Enum.find(listar(), &(&1.correo == correo))
  end

  # Nuevo: con password (string) -> genera salt+hash
  def registrar(nombre, correo, rol, password) do
    # validar campos
    errors = validar_campos(nombre, correo, password)

    if errors != %{} do
      {:error, errors}
    else
      if buscar_por_nombre(nombre) do
        {:error, %{nombre: "Ya existe un usuario con ese nombre"}}
      else
        if buscar_por_correo(correo) do
          {:error, %{correo: "Ya existe un usuario con ese correo"}}
        else
          id = siguiente_id()
          {salt, hash} = credenciales(password)

          :ok =
            CSV.agregar(@ruta, [
              to_string(id),
              nombre,
              correo,
              rol,
              salt || "",
              hash || ""
            ])

          {:ok,
           %Usuario{id: id, nombre: nombre, correo: correo, rol: rol, salt: salt, hash: hash}}
        end
      end
    end
  end

  # Inicio de sesión: valida email/formato y comprueba contraseña
  def iniciar_sesion(correo, password) do
    correo = String.trim(correo || "")
    password = password || ""

    # validaciones básicas
    cond do
      correo == "" ->
        {:error, %{correo: "El correo es obligatorio"}}

      not validar_email_formato?(correo) ->
        {:error, %{correo: "Formato de correo inválido"}}

      true ->
        case buscar_por_correo(correo) do
          nil ->
            {:error, %{correo: "Correo no registrado"}}

          %Usuario{salt: nil, hash: nil} ->
            {:error, %{password: "Usuario sin credenciales guardadas"}}

          %Usuario{} = user ->
            hash_calculado =
              :crypto.hash(:sha256, user.salt <> password)
              |> Base.encode16(case: :lower)

            if secure_eq?(hash_calculado, user.hash) do
              {:ok, user}
            else
              {:error, %{password: "Contraseña incorrecta"}}
            end
        end
    end
  end

  defp siguiente_id do
    case listar() do
      [] -> 1
      xs -> Enum.max_by(xs, & &1.id).id + 1
    end
  end

  # ------- Helpers de credenciales -------
  # compat
  defp credenciales(nil), do: {nil, nil}
  defp credenciales(""), do: {nil, nil}

  defp credenciales(password) do
    salt = :crypto.strong_rand_bytes(16) |> Base.encode64()

    hash =
      :crypto.hash(:sha256, salt <> password)
      |> Base.encode16(case: :lower)

    {salt, hash}
  end

  # ------- Validaciones -------
  defp validar_campos(nombre, correo, password) do
    %{}
    |> maybe_put(:nombre, validar_nombre(nombre))
    |> maybe_put(:correo, validar_correo(correo))
    |> maybe_put(:password, validar_password(password))
  end

  defp maybe_put(acc, _key, :ok), do: acc
  defp maybe_put(acc, key, {:error, msg}), do: Map.put(acc, key, msg)

  defp validar_nombre(nombre) do
    nombre = String.trim(to_string(nombre || ""))

    cond do
      nombre == "" ->
        {:error, "El nombre es obligatorio"}

      String.length(nombre) < 2 ->
        {:error, "El nombre debe tener al menos 2 caracteres"}

      not Regex.match?(~r/^[A-Za-zÁÉÍÓÚáéíóúÑñ\s]+$/u, nombre) ->
        {:error, "El nombre solo puede contener letras y espacios"}

      true ->
        :ok
    end
  end

  defp validar_correo(correo) do
    correo = String.trim(to_string(correo || ""))

    cond do
      correo == "" -> {:error, "El correo es obligatorio"}
      not String.contains?(correo, "@") -> {:error, "El correo debe contener @"}
      not validar_email_formato?(correo) -> {:error, "Formato de correo inválido"}
      true -> :ok
    end
  end

  defp validar_email_formato?(correo) do
    Regex.match?(~r/^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$/, correo)
  end

  defp validar_password(password) do
    pw = to_string(password || "")

    cond do
      pw == "" -> {:error, "La contraseña es obligatoria"}
      String.length(pw) < 6 -> {:error, "La contraseña debe tener al menos 6 caracteres"}
      true -> :ok
    end
  end

  # comparación en tiempo constante para evitar timing attacks básicos
  defp secure_eq?(a, b) when is_binary(a) and is_binary(b) and byte_size(a) == byte_size(b) do
    # convierte a listas de bytes y acumula XOR en tiempo constante
    acc =
      a
      |> :binary.bin_to_list()
      |> Enum.zip(:binary.bin_to_list(b))
      |> Enum.reduce(0, fn {x, y}, acc -> Bitwise.bor(acc, Bitwise.bxor(x, y)) end)

    acc == 0
  end

  defp secure_eq?(_, _), do: false
end
