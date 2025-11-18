# Hackaton
Hackathon App – Sistema Distribuido en Elixir (README)

Resumen del Proyecto

Hackathon App es una plataforma distribuida construida en Elixir para
gestionar eventos tipo hackathon.
Incluye manejo de usuarios, autenticación con roles, equipos, proyectos,
chat en tiempo real, mentorías, salas temáticas, modo comandos tipo
“/slash”, persistencia en CSV y soporte para nodos distribuidos.

Este README describe la arquitectura técnica, la estructura del sistema,
y detalles de funcionamiento interno para desarrolladores.

------------------------------------------------------------------------

Arquitectura General

El sistema implementa arquitectura Hexagonal / Ports & Adapters:

-   Dominios: Reglas del negocio sin dependencias externas.
-   Servicios: Casos de uso, coordinan la lógica.
-   Adaptadores: Entradas/salidas (CLI, chat distribuido, CSV).
-   Persistencia: CSV con un repositorio genérico.

Diagrama de Arquitectura

(Se incluye estilo ASCII en txt)

+————————– ADAPTADORES ——————————+ 
| InterfazConsola* | Chat |
ComandosCLI | CanalGeneral | CSVRepo |
 +————↓———————↓————————↓———-+ |
AuthServicio | UsuarioServicio | ProyectoServicio | EquipoServicio | |
AvancesServidor | AvancesCliente | Autorizacion | |
+————↓———————↓————————↓———-+ 
| Usuario | Proyecto | Equipo | Membresia |

Avance | Mensaje | +———————————————————————+ | Persistencia CSV |
+———————————————————————+

------------------------------------------------------------------------

Componentes Principales

1. Dominios

-   Usuario: Roles, autenticación, validación.
-   Proyecto: Categoría, estado, relación con equipo.
-   Equipo: Miembros, descripción, tema.
-   Avance: Registro incremental del progreso.
-   Mensaje: Comunicación interna.
-   Membresia: Relación usuario–equipo.

2. Servicios

-   UsuarioServicio: Registro y validación.
-   AuthServicio: Autenticación con salt + SHA256.
-   EquipoServicio: Gestión total de equipos.
-   ProyectoServicio: Creación, estados, avances.
-   AvancesServidor: Pub/sub local de avances.
-   AvancesCliente: Suscripciones y broadcast.
-   Autorizacion: Permisos basados en rol.
-   Session: Sesión global de consola.

3. Adaptadores

-   InterfazConsolaLogin
-   InterfazConsola (organizador)
-   InterfazConsolaProyectos (participante)
-   InterfazConsolaEquipos
-   InterfazConsolaMentoria
-   InterfazConsolaChat
-   ComandosCLI
-   ChatServidor y nodos distribuidos
-   CanalGeneral
-   SalasTematicas
-   PersistenciaCSV

------------------------------------------------------------------------

Persistencia (CSV)

Carpeta /data/ contiene:

-   usuarios.csv
-   equipos.csv
-   proyectos.csv
-   avances.csv
-   mensajes.csv
-   membresias.csv

Cada archivo se reescribe con encabezado seguro por PersistenciaCSV.

------------------------------------------------------------------------

Instalación y Ejecución

Instalación

    mix deps.get

Ejecución Normal

    mix run --no-halt

Ejecución Distribuida

Servidor:

    elixir --name nodoservidor@IP --cookie cookie -S mix run --no-halt

Cliente:

    elixir --name clienteX@IP --cookie cookie -S mix run --no-halt

------------------------------------------------------------------------

Uso del Sistema (Técnico)

Modo Comandos

    /help
    /teams
    /join <equipo>
    /project <equipo>
    /chat <equipo>
    /back
    /exit

------------------------------------------------------------------------

Roles

Organizador

Administra: - equipos - usuarios - proyectos - chat - mentorías

Participante

-   proyectos
-   avances
-   chat
-   comandos

Mentor

-   revisiones
-   avances
-   mensajes
-   chat

------------------------------------------------------------------------

Chat Distribuido

Implementado con: - Node.connect/1 - Registro global del ChatServidor -
Broadcast entre nodos

------------------------------------------------------------------------

Autores

-   Santiago Nieto Beltrán
-   Yeimy Daniela Rodríguez
-   Michael Murillo

Licencia

MIT 2025

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `hackaton` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:hackaton, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/hackaton>.

