# ComandoServicio: Servicio para interpretar y ejecutar comandos de usuario.
# Relaciones:
# - Usa CommandAdapter para procesar comandos
# - Coordina con otros servicios según el comando
defmodule HackathonApp.Servicios.ComandoServicio do
  alias HackathonApp.Adaptadores.CommandAdapter
  alias HackathonApp.Servicios.UsuarioServicio

  def procesar_comando(input, nombre_usuario) do
    case UsuarioServicio.buscar_por_nombre(nombre_usuario) do
      nil ->
        {:error, "Usuario no encontrado. Por favor regístrate primero."}

      usuario ->
        CommandAdapter.procesar(input, usuario.id)
    end
  end

  def iniciar_sesion(nombre) do
    case UsuarioServicio.buscar_por_nombre(nombre) do
      nil -> {:error, "Usuario no encontrado"}
      usuario -> {:ok, usuario}
    end
  end
end
