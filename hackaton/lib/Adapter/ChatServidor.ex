defmodule HackathonApp.Adapter.ChatServidor do
  @moduledoc """
  Servidor de chat simple para trabajar con InterfazConsolaChat.

  Debe ejecutarse en el nodo:  :nodoservidor@192.168.157.250
  y se registra con el nombre :chat_servidor
  """

  @nombre_servicio :chat_servidor

  # Estado: %{usuarios: %{pid => %{nombre: String.t(), monitor: reference()}}}
  def main() do
  
    mostrar_banner()

    Process.register(self(), @nombre_servicio)

    IO.puts(
      IO.ANSI.green() <>
        " Servidor iniciado y registrado como #{@nombre_servicio}" <>
        IO.ANSI.reset()
    )

    estado_inicial = %{usuarios: %{}}
    bucle_servidor(estado_inicial)
  end

  # ═══════════════════════════════════════════════════════════
  #   BANNER
  # ═══════════════════════════════════════════════════════════

  defp mostrar_banner() do
    IO.puts("\n" <> IO.ANSI.cyan())
    IO.puts("══════════════════════════════════════")
    IO.puts("        SERVIDOR DE CHAT ELIXIR       ")
    IO.puts("══════════════════════════════════════")
    IO.puts(IO.ANSI.reset())
  end

  # ═══════════════════════════════════════════════════════════
  #   LOOP PRINCIPAL DEL SERVIDOR
  # ═══════════════════════════════════════════════════════════

  defp bucle_servidor(estado) do
    receive do
      {:conectar, pid_cliente, nombre} ->
        estado
        |> manejar_conexion(pid_cliente, nombre)
        |> bucle_servidor()

      {:desconectar, pid_cliente} ->
        estado
        |> manejar_desconexion(pid_cliente, :manual)
        |> bucle_servidor()

      {:listar_usuarios, pid_solicitante} ->
        manejar_listar_usuarios(estado, pid_solicitante)
        bucle_servidor(estado)

      {:mensaje, pid_origen, texto} ->
        manejar_mensaje(estado, pid_origen, texto)
        bucle_servidor(estado)

      {:DOWN, ref, :process, pid, _reason} ->
        # Cliente cayó/terminó sin enviar {:desconectar, ...}
        estado
        |> manejar_caida_cliente(pid, ref)
        |> bucle_servidor()

      otro ->
        IO.puts("Mensaje no reconocido: #{inspect(otro)}")
        bucle_servidor(estado)
    end
  end

  # ═══════════════════════════════════════════════════════════
  #   MANEJO DE CONEXIÓN
  # ═══════════════════════════════════════════════════════════

  defp manejar_conexion(estado = %{usuarios: usuarios}, pid_cliente, nombre) do
    # Validar nombre ya en uso
    nombre_ya_en_uso? =
      usuarios
      |> Map.values()
      |> Enum.any?(fn %{nombre: n} -> n == nombre end)

    cond do
      nombre_ya_en_uso? ->
        send(pid_cliente, {:error, "El nombre '#{nombre}' ya está en uso"})
        estado

      Map.has_key?(usuarios, pid_cliente) ->
        send(pid_cliente, {:error, "Ya estás conectado al servidor"})
        estado

      true ->
        ref = Process.monitor(pid_cliente)

        usuarios_actualizados =
          Map.put(usuarios, pid_cliente, %{nombre: nombre, monitor: ref})

        estado_actualizado = %{estado | usuarios: usuarios_actualizados}

        # Confirmar al cliente
        send(pid_cliente, {:conectado, nombre})

        # Notificar al resto
        mensaje = "[Sistema] #{nombre} se ha unido al chat."
        broadcast(estado_actualizado, mensaje, :sistema, except: pid_cliente)

        IO.puts("Cliente conectado: #{inspect(pid_cliente)} como '#{nombre}'")

        estado_actualizado
    end
  end

  # ═══════════════════════════════════════════════════════════
  #   MANEJO DE DESCONEXIÓN
  # ═══════════════════════════════════════════════════════════

  defp manejar_desconexion(estado = %{usuarios: usuarios}, pid_cliente, tipo) do
    case Map.fetch(usuarios, pid_cliente) do
      :error ->
        # No estaba registrado, ignoramos
        estado

      {:ok, %{nombre: nombre, monitor: ref}} ->
        Process.demonitor(ref, [:flush])

        usuarios_actualizados = Map.delete(usuarios, pid_cliente)
        estado_actualizado = %{estado | usuarios: usuarios_actualizados}

        mensaje_sistema =
          case tipo do
            :manual -> "[Sistema] #{nombre} ha salido del chat."
            :caida -> "[Sistema] #{nombre} se ha desconectado inesperadamente."
          end

        broadcast(estado_actualizado, mensaje_sistema, :sistema)

        IO.puts("Cliente desconectado: #{inspect(pid_cliente)} (#{nombre})")

        estado_actualizado
    end
  end

  defp manejar_caida_cliente(estado = %{usuarios: usuarios}, pid, ref) do
    case Map.get(usuarios, pid) do
      nil ->
        estado

      %{monitor: ^ref} ->
        manejar_desconexion(estado, pid, :caida)

      _otro ->
        estado
    end
  end

  # ═══════════════════════════════════════════════════════════
  #   LISTAR USUARIOS
  # ═══════════════════════════════════════════════════════════

  defp manejar_listar_usuarios(%{usuarios: usuarios}, pid_solicitante) do
    nombres =
      usuarios
      |> Enum.map(fn {_pid, %{nombre: nombre}} -> nombre end)
      |> Enum.sort()

    mensaje =
      case nombres do
        [] ->
          "No hay usuarios conectados."

        lista ->
          """
          Usuarios conectados (#{length(lista)}):
          - #{Enum.join(lista, "\n- ")}
          """
      end

    send(pid_solicitante, {:info, mensaje})
  end

  # ═══════════════════════════════════════════════════════════
  #   MENSAJES DE CHAT
  # ═══════════════════════════════════════════════════════════

  defp manejar_mensaje(%{usuarios: usuarios} = estado, pid_origen, texto) do
    case Map.get(usuarios, pid_origen) do
      nil ->
        send(pid_origen, {:error, "No estás registrado en el chat"})
        estado

      %{nombre: nombre} ->
        mensaje_formateado = "[#{nombre}] #{texto}"
        broadcast(estado, mensaje_formateado, :usuario)
        estado
    end
  end

  # ═══════════════════════════════════════════════════════════
  #   BROADCAST
  # ═══════════════════════════════════════════════════════════

  defp broadcast(%{usuarios: usuarios}, mensaje, tipo, opts \\ []) do
    except = Keyword.get(opts, :except, nil)

    usuarios
    |> Enum.each(fn {pid, _info} ->
      if pid != except do
        send(pid, {:mensaje_chat, mensaje, tipo})
      end
    end)
  end
end
