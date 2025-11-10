defmodule HackathonApp.Service.Autorizacion do
  @moduledoc """
  Define los permisos (autorizaciones) por rol de usuario dentro de la hackathon.
  """

  @typedoc "Rol de usuario (texto: \"participante\", \"mentor\" u \"organizador\")."
  @type rol :: String.t()

  @typedoc "Acción controlada por permisos."
  @type accion ::
          :crear_equipo
          | :unir_usuario
          | :registrar_proyecto
          | :cambiar_estado_proyecto
          | :agregar_avance
          | :ver_proyecto
          | :ver_equipos
          | :enviar_mensaje
          | :anunciar_general
          | :dar_mentoria

  @spec can?(rol(), accion()) :: boolean()

  # =====================================================
  #  ORGANIZADOR  →  Puede hacer todo
  # =====================================================
  def can?("organizador", _accion), do: true

  # =====================================================
  #  MENTOR  →  Puede ver proyectos, equipos, mensajes y dar mentoría
  # =====================================================
  def can?("mentor", :ver_proyecto), do: true
  def can?("mentor", :ver_equipos), do: true
  def can?("mentor", :dar_mentoria), do: true
  def can?("mentor", :enviar_mensaje), do: true
  def can?("mentor", _), do: false

  # =====================================================
  #  PARTICIPANTE  →  Puede gestionar su proyecto y comunicarse
  # =====================================================
  def can?("participante", :registrar_proyecto), do: true
  def can?("participante", :cambiar_estado_proyecto), do: true
  def can?("participante", :agregar_avance), do: true
  def can?("participante", :ver_proyecto), do: true
  def can?("participante", :ver_equipos), do: true
  def can?("participante", :enviar_mensaje), do: true
  def can?("participante", _), do: false

  # =====================================================
  #  Cualquier otro rol o desconocido → sin permisos
  # =====================================================
  def can?(_, _), do: false
end
