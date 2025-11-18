DOCUMENTACIÓN TÉCNICA – HACKATHON APP
====================================

ARQUITECTURA
------------
El sistema usa Arquitectura Hexagonal, con capas:
- Domain (estructuras de datos)
- Services (lógica del negocio)
- Adapter (UI, CLI, chat, persistencia, comandos)
- Infraestructura (persistencia CSV, procesos distribuidos)

DOMINIO
-------
- Usuario
- Equipo
- Proyecto
- Avance
- Mensaje
- Membresía

SERVICIOS
---------
UsuarioServicio:
- Registrar usuarios con salt + hash
- Buscar y autenticar usuarios

EquipoServicio:
- Crear, listar, unir usuarios
- Eliminar equipos
- Manejo de membresías

ProyectoServicio:
- Crear proyectos
- Cambiar estado
- Registrar avances
- Broadcast de avances vía nodos distribuidos

AUTORIZACIÓN
------------
Autorizacion.can?(rol, accion)

ADAPTERS
--------
- InterfazConsolaLogin
- InterfazConsolaProyectos
- InterfazConsolaEquipos
- InterfazConsolaMentoria
- ComandosCLI
- ChatServidor
- InterfazConsolaChat
- AvancesCliente / Servidor
- CanalGeneral
- SalasTematicas

CHAT DISTRIBUIDO
----------------
Usa:
- spawn
- receive
- Process.monitor
- Node.connect
- Cookies distribuidas

PROCESOS
--------
Ejecuta varios GenServers:
- AvancesServidor
- CanalGeneral
- SalasTematicas

PERSISTENCIA
------------
Archivos CSV:
- usuarios.csv
- equipos.csv
- proyectos.csv
- avances.csv
- mensajes.csv
- membresias.csv

SUPERVISIÓN
-----------
Supervisor principal:
- AvancesServidor
- ChatServidor (solo nodo servidor)
- UI Login
