defmodule HackathonApp.Adapter.InterfazConsolaChat do
  @moduledoc """
  Cliente de chat en tiempo real para la Hackathon.
  Se invoca desde el menú principal: "3) Comunicación en tiempo real".
  """

  # ═══════════════════════════════════════════════════════════
  #  CONFIGURACIÓN - Modifica solo estas líneas
  # ═══════════════════════════════════════════════════════════

  @nombre_servicio_local :cliente_chat

  # Este tuple no se usa directamente, pero lo dejamos por si quieres extenderlo
  @servicio_local {@nombre_servicio_local, :"nodocliente1@192.168.157.60"}

  # Nodo del servidor de chat (la PC donde corre HackathonApp con ChatServidor)
  @nodo_remoto :"nodoservidor@192.168.157.60"

  # Nombre registrado del servidor de chat en ese nodo
  @servicio_remoto {:chat_servidor, @nodo_remoto}

  # ═══════════════════════════════════════════════════════════
  #   PUNTO DE ENTRADA DESDE EL MENÚ
  # ═══════════════════════════════════════════════════════════

  def iniciar() do
    mostrar_banner()
    IO.puts(IO.ANSI.yellow() <> " Conectando a: #{@nodo_remoto}" <> IO.ANSI.reset())

    nombre = solicitar_nombre()

    registrar_servicio()
    |> establecer_conexion(nombre)
    |> iniciar_chat(nombre)
  end

  # ═══════════════════════════════════════════════════════════
  #   UI BÁSICA
  # ═══════════════════════════════════════════════════════════

  defp mostrar_banner() do
    IO.puts("\n" <> IO.ANSI.cyan())
    IO.puts("       CHAT EN TIEMPO REAL       ")
    IO.puts(IO.ANSI.reset())
  end

  defp solicitar_nombre() do
    IO.gets("\n Ingresa tu nombre: ")
    |> String.trim()
    |> validar_nombre()
  end

  defp validar_nombre(""), do: solicitar_nombre()

  defp validar_nombre(nombre) when byte_size(nombre) > 20 do
    IO.puts(IO.ANSI.red() <> " Nombre muy largo (máximo 20 caracteres)" <> IO.ANSI.reset())
    solicitar_nombre()
  end

  defp validar_nombre(nombre), do: nombre

  # ═══════════════════════════════════════════════════════════
  #   REGISTRO LOCAL Y CONEXIÓN
  # ═══════════════════════════════════════════════════════════

  defp registrar_servicio() do
    case Process.whereis(@nombre_servicio_local) do
      nil ->
        # Nadie está usando el nombre, lo registramos
        Process.register(self(), @nombre_servicio_local)

      pid when pid == self() ->
        # Este mismo proceso ya está registrado, no hacemos nada
        :ok

      _otro_pid ->
        # Había otro proceso viejo registrado, lo limpiamos y registramos este
        Process.unregister(@nombre_servicio_local)
        Process.register(self(), @nombre_servicio_local)
    end

    :ok
  end

  defp establecer_conexion(:ok, nombre) do
    case Node.connect(@nodo_remoto) do
      true ->
        send(@servicio_remoto, {:conectar, self(), nombre})
        esperar_confirmacion(nombre)

      false ->
        {:error, "No se pudo conectar al servidor"}

      :ignored ->
        {:error, "Nodo ya conectado"}
    end
  end

  defp esperar_confirmacion(nombre) do
    receive do
      {:conectado, ^nombre} -> :ok
      {:error, razon} -> {:error, razon}
    after
      5_000 -> {:error, "Timeout: el servidor no respondió"}
    end
  end

  # ═══════════════════════════════════════════════════════════
  #   INICIO DEL CHAT
  # ═══════════════════════════════════════════════════════════

  defp iniciar_chat(:ok, nombre) do
    IO.puts(
      IO.ANSI.green() <>
        "\n Conectado exitosamente como '#{nombre}'" <>
        IO.ANSI.reset()
    )

    mostrar_ayuda()

    # Proceso para leer del teclado
    spawn(fn -> bucle_lectura(nombre) end)

    # Proceso principal queda escuchando mensajes del servidor
    bucle_receptor()
  end

  defp iniciar_chat({:error, razon}, _nombre) do
    IO.puts(IO.ANSI.red() <> "\n Error: #{razon}" <> IO.ANSI.reset())
    IO.puts("Intenta de nuevo.\n")
  end

  defp mostrar_ayuda() do
    IO.puts("\n" <> IO.ANSI.blue() <> "━━━ Comandos disponibles ━━━")
    IO.puts("  /usuarios  - Ver usuarios conectados")
    IO.puts("  /ayuda     - Mostrar esta ayuda")
    IO.puts("  /salir     - Salir del chat")
    IO.puts("  Cualquier otro texto será enviado como mensaje")
    IO.puts("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" <> IO.ANSI.reset() <> "\n")
  end

  # ═══════════════════════════════════════════════════════════
  #   BUCLES DEL CLIENTE
  # ═══════════════════════════════════════════════════════════

  defp bucle_lectura(nombre) do
  entrada =
    case IO.gets("") do
      :eof -> "/salir"      # Se cerró la entrada estándar
      nil  -> "/salir"      # No hay más input
      data -> String.trim(data)
    end

  case procesar_entrada(entrada) do
    :continuar ->
      bucle_lectura(nombre)

    :salir ->
      send(self_registered(), :salir)
      :ok
  end
end


  defp bucle_receptor() do
    receive do
      {:mensaje_chat, mensaje, :sistema} ->
        IO.puts(IO.ANSI.yellow() <> mensaje <> IO.ANSI.reset())
        bucle_receptor()

      {:mensaje_chat, mensaje, _tipo} ->
        IO.puts(mensaje)
        bucle_receptor()

      {:info, info} ->
        IO.puts(IO.ANSI.cyan() <> info <> IO.ANSI.reset())
        bucle_receptor()

      :salir ->
        IO.puts(
          IO.ANSI.green() <>
            " Desconectado. ¡Hasta pronto!" <>
            IO.ANSI.reset() <> "\n"
        )

        :ok

      _ ->
        bucle_receptor()
    end
  end

  defp self_registered() do
    Process.whereis(@nombre_servicio_local)
  end

  # ═══════════════════════════════════════════════════════════
  #   PARSEO DE COMANDOS
  # ═══════════════════════════════════════════════════════════

  defp procesar_entrada(""), do: :continuar

  defp procesar_entrada("/salir") do
    IO.puts(IO.ANSI.yellow() <> "\n Saliendo del chat..." <> IO.ANSI.reset())
    send(@servicio_remoto, {:desconectar, self_registered()})
    Process.sleep(300)
    :salir
  end

  defp procesar_entrada("/usuarios") do
    send(@servicio_remoto, {:listar_usuarios, self_registered()})
    :continuar
  end

  defp procesar_entrada("/ayuda") do
    mostrar_ayuda()
    :continuar
  end

  defp procesar_entrada(texto) do
    send(@servicio_remoto, {:mensaje, self_registered(), texto})
    :continuar
  end
end
