defmodule HackathonApp.Adapter.InterfazConsolaChat do
  @moduledoc """
  Menú de comunicación en tiempo real:
  - Canal general de anuncios
  - Salas temáticas de discusión
  """

  alias HackathonApp.Session
  alias HackathonApp.Service.Autorizacion
  alias HackathonApp.Adapter.{CanalGeneral, SalasTematicas}
  alias HackathonApp.Adapter.ComandosCLI

  # ===== Punto de entrada =====
  def iniciar do
    case Session.current() do
      nil ->
        IO.puts("No hay sesión. Inicia sesión primero.")

      u ->
        loop(u)
    end
  end

  defp loop(u) do
    IO.puts("\n=== COMUNICACIÓN EN TIEMPO REAL ===")
    IO.puts("Usuario: #{u.nombre} (rol=#{u.rol})\n")
    IO.puts("1) Escuchar canal general (anuncios)")
    IO.puts("2) Enviar anuncio general (solo organizador)")
    IO.puts("3) Entrar a sala temática")
    IO.puts("4) Enviar mensaje a sala temática")
    IO.puts("5) Modo comandos (/help, /teams, /project...)")
    IO.puts("0) Volver")

    case prompt("> ") do
      "1" ->
        escuchar_canal()
        loop(u)

      "2" ->
        enviar_anuncio(u)
        loop(u)

      "3" ->
        entrar_sala(u)
        loop(u)

      "4" ->
        enviar_a_sala(u)
        loop(u)

      "5" ->
        ComandosCLI.iniciar()
        loop(u)

      "0" ->
        :ok

      _ ->
        IO.puts("Opción inválida")
        loop(u)
    end
  end

  # ===== Canal general =====

  defp escuchar_canal do
    case CanalGeneral.suscribirse() do
      :ok ->
        IO.puts("Escuchando anuncios globales por 20 segundos...\n")
        escuchar_anuncios(20)

      {:error, r} ->
        IO.puts("No se pudo suscribir al canal general: #{inspect(r)}")
    end
  end

  defp enviar_anuncio(u) do
    if Autorizacion.can?(u.rol, :anunciar_general) do
      msg = prompt("Texto del anuncio: ")

      case CanalGeneral.anunciar(u.nombre, msg) do
        :ok -> IO.puts("Anuncio enviado.")
        {:error, r} -> IO.puts("Error al anunciar: #{inspect(r)}")
      end
    else
      IO.puts("Acceso denegado: solo el organizador puede enviar anuncios generales.")
    end
  end

  defp escuchar_anuncios(0), do: IO.puts("Fin de escucha de anuncios.\n")

  defp escuchar_anuncios(segundos) when segundos > 0 do
    receive do
      {:anuncio, a} ->
        IO.puts("[#{a.fecha_iso}] ANUNCIO de #{a.autor}: #{a.mensaje}")
        escuchar_anuncios(segundos)
    after
      1_000 ->
        escuchar_anuncios(segundos - 1)
    end
  end

  # ===== Salas temáticas =====

  defp entrar_sala(u) do
    sala = prompt("Nombre de la sala (ej: ia, web, educacion): ")

    case SalasTematicas.suscribirse(sala) do
      :ok ->
        IO.puts("Entraste a la sala '#{sala}'. Escuchando 30 segundos...\n")
        escuchar_sala(sala, 30, u.nombre)

      {:error, r} ->
        IO.puts("No se pudo entrar a la sala: #{inspect(r)}")
    end
  end

  defp enviar_a_sala(u) do
    sala = prompt("Sala: ")
    texto = prompt("Mensaje: ")

    case SalasTematicas.publicar(sala, u.nombre, texto) do
      :ok -> IO.puts("Mensaje enviado a sala #{sala}.")
      {:error, r} -> IO.puts("Error al enviar: #{inspect(r)}")
    end
  end

  defp escuchar_sala(_sala, 0, _usuario), do: IO.puts("Fin de la sala.\n")

  defp escuchar_sala(sala, segundos, usuario) when segundos > 0 do
    receive do
      {:sala_msg, sala_rec, m} ->
        IO.puts("[#{m.fecha_iso}] [#{sala_rec}] #{m.usuario}: #{m.texto}")
        escuchar_sala(sala, segundos, usuario)
    after
      1_000 ->
        escuchar_sala(sala, segundos - 1, usuario)
    end
  end

  # ===== I/O =====
  defp prompt(label) do
    case IO.gets(:stdio, label) do
      :eof -> ""
      nil -> ""
      data -> data |> to_string() |> String.trim()
    end
  end
end
