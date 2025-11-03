defmodule Service.ChatDistribuido do
  @moduledoc "Reglas del chat: valida y arma el mensaje de dominio."
  alias Domain.Mensaje
  alias Adapter.ChatNodo

  def enviar(nodo_servidor, attrs) do
    with {:ok, msg} <- construir_mensaje(attrs),
         true <- ChatNodo.conectar(nodo_servidor) do
      ChatNodo.enviar_mensaje(nodo_servidor, Map.from_struct(msg))
    else
      false -> {:error, :no_conectado}
      {:error, _}=e -> e
    end
  end

  defp construir_mensaje(%{equipo_id: e, usuario_id: u, texto: t}) when is_binary(t) and t != "" do
    {:ok, %Mensaje{equipo_id: e, usuario_id: u, texto: String.replace(t, "\n", " "),
                   fecha_iso: DateTime.to_iso8601(DateTime.utc_now())}}
  end

  defp construir_mensaje(_), do: {:error, :invalido}
end
