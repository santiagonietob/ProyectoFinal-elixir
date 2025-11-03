# lib/adapter/avances_servidor.ex
defmodule HackathonApp.Adapter.AvancesServidor do
  @moduledoc "Proceso servidor (remoto o local) que difunde avances a suscriptores."
  @nombre_servicio :servicio_avances

  def iniciar do
    # ⇐ registrar servicio
    Process.register(self(), @nombre_servicio)
    # estado = lista de PIDs suscritos
    loop([])
  end

  defp loop(suscriptores) do
    receive do
      {:suscribir, pid} ->
        loop(Enum.uniq([pid | suscriptores]))

      {:cancelar, pid} ->
        loop(List.delete(suscriptores, pid))

      {:avance, avance} ->
        Enum.each(suscriptores, &send(&1, {:avance, avance}))
        loop(suscriptores)

      :fin ->
        Enum.each(suscriptores, &send(&1, :fin))
        :ok

      _otro ->
        loop(suscriptores)
    end
  end
end
