defmodule HackathonApp.Guard do
  alias HackathonApp.Session
  alias HackathonApp.Adapter.InterfazConsolaLogin

  # Verifica que el usuario logueado tenga el rol requerido.
  # Devuelve :ok o no vuelve (muestra mensaje y regresa al login).
  def ensure_role!(required) do
    case Session.current() do
      nil ->
        IO.puts(IO.ANSI.yellow() <> "\nNo hay sesión. Inicia sesión primero." <> IO.ANSI.reset())
        InterfazConsolaLogin.iniciar()
        throw(:halt)

      %{rol: ^required} ->
        :ok

      %{rol: other} ->
        IO.puts(
          IO.ANSI.red() <>
            "\nAcceso denegado. Tu rol es #{other}, se requiere #{required}." <> IO.ANSI.reset()
        )

        InterfazConsolaLogin.iniciar()
        throw(:halt)
    end
  end
end
