# lib/service/autorizacion.ex
defmodule HackathonApp.Service.Autorizacion do
  @moduledoc "Chequeo de permisos por rol."

  @type rol :: "participante" | "mentor" | "organizador"
  @type accion ::
          :crear_equipo
          | :unir_usuario
          | :registrar_proyecto
          | :cambiar_estado_proyecto
          | :agregar_avance
          | :ver_proyecto
          | :enviar_mensaje
          | :anunciar_general
          | :dar_mentoria

  @spec can?(rol, accion) :: boolean
  def can?("organizador", _), do: true

  def can?("mentor", accion) do
    accion in [
      :ver_proyecto,
      :dar_mentoria,
      :enviar_mensaje
    ]
  end

  def can?("participante", accion) do
    accion in [
      :registrar_proyecto,
      :cambiar_estado_proyecto,
      :agregar_avance,
      :ver_proyecto,
      :enviar_mensaje
    ]
  end

  def can?(_, _), do: false
end
