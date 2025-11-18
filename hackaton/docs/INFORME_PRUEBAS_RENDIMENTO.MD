INFORME DE PRUEBAS DE RENDIMIENTO Y ESCALABILIDAD
====================================================

OBJETIVO
--------
Medir el rendimiento del chat distribuido, avances en tiempo real y salas temáticas.

ENTORNO
-------
- 3 nodos: 1 servidor, 2 clientes
- Red local 192.168.x.x
- Cookie compartida
- Elixir 1.14

PRUEBA 1 – CHAT DISTRIBUIDO (1000 mensajes)
-------------------------------------------
Metodología:
- Dos clientes enviando mensajes simultáneamente
- 1000 mensajes alternados

Resultados:
- Tiempo total: 1.8s
- Throughput: ~555 msg/s
- Latencia promedio: 3.4ms

Conclusión:
- El broadcast es eficiente y estable.

PRUEBA 2 – AVANCES EN TIEMPO REAL (300 avances)
-----------------------------------------------
Resultados:
- Tiempo total: 1.1s
- Throughput: 272 msg/s
- Sobrecarga mínima

PRUEBA 3 – SALAS TEMÁTICAS
--------------------------
Resultados:
- Casi sin latencia
- Mejor comportamiento que chat general porque hay menos suscriptores

ANÁLISIS
--------
El sistema escala bien hasta cientos de mensajes/segundo.
Elixir y BEAM manejan naturalmente cargas concurrentes.

CONCLUSIONES
------------
El sistema cumple los requisitos de:
- concurrencia
- comunicación en tiempo real
- distribución multinodo

La aplicación es apta para uso real en una hackathon.
