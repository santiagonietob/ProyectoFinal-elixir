# Hackathon App

Documentación técnica del proyecto "Hackathon App" — Sistema distribuido en Elixir

## Resumen

Hackathon App es una aplicación de ejemplo implementada en Elixir que modela la gestión de hackathons de forma distribuida. Está diseñada con una arquitectura Hexagonal (Ports & Adapters) y separa claramente Dominios, Servicios, Adaptadores y Persistencia. El sistema soporta autenticación con roles (participante, mentor, organizador), persistencia en CSV, sesión en consola mediante `Agent`, y un chat distribuido entre nodos Elixir.

El objetivo es demostrar patrones de arquitectura, comunicación distribuida (nodos Elixir), y un pub/sub propio para difundir avances de proyectos en tiempo real.

## Arquitectura (ASCII)

Diagrama simplificado en capas (Ports & Adapters / Hexagonal):

```
                +----------------------+           
                |   Interfaz Usuario   |  <-- Consola (Adapters)
                |  - InterfazConsola   |
                |  - InterfazConsolaLogin
                |  - InterfazConsolaProyectos
                |  - InterfazConsolaEquipos
                |  - InterfazConsolaMentoria
                |  - InterfazConsolaChat
                +----------+-----------+
                           |
                +----------v-----------+
                |       Servicios      |  <-- Application Services
                |  - AuthServicio      |
                |  - UsuarioServicio   |
                |  - EquipoServicio    |
                |  - ProyectoServicio  |
                |  - AvancesCliente    |
                |  - AvancesServidor   |
                +----------+-----------+
                           |
                +----------v-----------+
                |       Dominios       |  <-- Entities / Business Logic
                |  - Usuario           |
                |  - Equipo            |
                |  - Proyecto          |
                |  - Avance            |
                |  - Mensaje           |
                +----------+-----------+
                           |
                +----------v-----------+
                |     Persistencia     |  <-- Repositorios / CSV
                |  - PersistenciaCSV   |
                +----------------------+ 

Comunicaciones distribuidas: `ChatServidor`, `CanalGeneral`, `SalasTematicas` y `AvancesServidor` forman la capa de pub/sub y mensajería entre nodos.
```

## Explicación de cada capa

- Dominios: entidades puras que representan conceptos del dominio: `Usuario`, `Equipo`, `Proyecto`, `Avance`, `Mensaje`, `Membresia`. Estas structs y funciones encapsulan reglas de negocio y validaciones.

- Servicios: lógica de aplicación y orquestación de casos de uso. Ejemplos: `UsuarioServicio` (operaciones CRUD sobre usuarios), `AuthServicio` (autenticación, creación de salt+hash), `EquipoServicio`, `ProyectoServicio` (gestión de proyectos y estados), `AvancesCliente`/`AvancesServidor` (difusión de avances), `CanalGeneral` y `SalasTematicas` (módulos de chat y temas).

- Adaptadores: componentes que conectan la aplicación con el mundo externo — las interfaces de consola (`InterfazConsola*`), `PersistenciaCSV` (repositorio que lee/escribe CSV), y adaptadores de red para comunicación entre nodos.

- Persistencia: repositorio genérico basado en CSV que genera y mantiene archivos: `usuarios.csv`, `equipos.csv`, `proyectos.csv`, `avances.csv`, `mensajes.csv`, `membresias.csv`.

## Chat distribuido — descripción técnica

El chat está diseñado para funcionar entre nodos Elixir. Conceptos clave:

- Conexión entre nodos: uso de `Node.connect(:'nombre@IP')` para establecer conectividad entre el nodo servidor y nodos clientes.
- Registro global: `ChatServidor` se registra globalmente para que los procesos remotos puedan localizarlo y enviar mensajes.
- Procesos remotos: cuando un nodo quiere difundir un mensaje, envía al `ChatServidor` que maneja la entrega local y remota; también existen procesos que representan `SalasTematicas` y `CanalGeneral`.
- Mensajería: los mensajes se envían como structs `Mensaje` y se persisten en `mensajes.csv` mediante `PersistenciaCSV`.

Patrón de operación (simplificado):

1. Cliente se conecta a otro nodo: `Node.connect(:'nodoservidor@IP')`.
2. Cliente local encuentra la referencia a `ChatServidor` registrado (puede usar `:global.whereis_name/1` o un módulo wrapper).
3. Cliente envía `{:broadcast, sala, mensaje}` a `ChatServidor`.
4. `ChatServidor` reenvía el mensaje a procesos locales y, si corresponde, usa RPC/`send` hacia procesos remotos registrados en otros nodos.

Ejemplo conceptual (no sustituye al código fuente existente):

```elixir
# Conectar a nodo remoto
Node.connect(:'nodoservidor@192.168.1.10')

# Enviar mensaje al servidor de chat
{:ok, chat_pid} = :global.whereis_name(:chat_servidor)
send(chat_pid, {:broadcast, "canal_general", %Mensaje{from: "alice", body: "Hola"}})
```

> Nota: La implementación real en el proyecto usa `ChatServidor` y adaptadores en `lib/Adapter` y `lib`.

## Flujo de avances en tiempo real

Avances de proyectos son gestionados por `ProyectoServicio` y difundidos por `AvancesServidor` usando un pub/sub propio:

- Cuando un participante registra un nuevo avance, `ProyectoServicio` valida y persiste la entidad `Avance` en `avances.csv` mediante `PersistenciaCSV`.
- `ProyectoServicio` notifica a `AvancesCliente`/`AvancesServidor` para que el avance se difunda.
- `AvancesServidor` actúa como broker local que recibe el evento y lo reenvía a clientes suscritos (locales) y a nodos remotos si el sistema está distribuido.

Secuencia resumida:

1. Participante -> `ProyectoServicio.create_avance/2`
2. Validación y persistencia -> `PersistenciaCSV.save(:avances, avance)`
3. Emisión del evento -> `AvancesServidor.publish(avance)`
4. `AvancesServidor` entrega a suscriptores locales y a `AvancesCliente` en nodos remotos

## Modo de ejecución

- Modo local (único nodo):

```bash
mix run --no-halt
```

- Modo distribuido (ejemplo):

```bash
# Nodo servidor
elixir --name nodoservidor@IP --cookie c -S mix run --no-halt

# Nodo cliente
elixir --name cliente1@IP --cookie c -S mix run --no-halt
```

Notas:
- La cookie (`--cookie c`) debe coincidir entre nodos para permitir la conexión.
- Use nombres de nodo resolvibles o direcciones IP según configuración de red.

## Estructura de archivos y carpetas (vista general)

```
hackaton/
├── lib/
│   ├── Adapter/
│   │   ├── ChatServidor.ex
│   │   ├── AvancesCliente.ex
│   │   ├── AvancesServidor.ex
│   │   ├── CanalGeneral.ex
│   │   └── PersistenciaCSV.ex
│   ├── domain/
│   │   ├── usuario.ex
│   │   ├── equipo.ex
│   │   └── proyecto.ex
│   ├── service/
│   │   ├── auth_servicio.ex
│   │   ├── usuarios_service.ex
│   │   ├── EquipoServicio.ex
│   │   └── proyecto_servicio.ex
│   ├── InterfazConsola.ex
│   └── InterfazConsolaLogin.ex
├── data/
│   ├── usuarios.csv
│   ├── equipos.csv
│   └── proyectos.csv
├── mix.exs
└── test/
```

Los archivos CSV se generan/actualizan por `PersistenciaCSV` y se encuentran en `hackaton/data/`.

## Roles del sistema

- `organizador`: privilegios administrativos — gestionar usuarios, equipos, proyectos, mentorías y moderar chat.
- `participante`: crear proyectos, registrar avances, cambiar estados, comunicarse en chat y usar comandos.
- `mentor`: revisar proyectos y avances, ofrecer retroalimentación y participar en chat.

Control de permisos: `Autorizacion.can?(usuario, accion)` — función central para controlar acceso a operaciones.

## Modo comandos (técnico)

La interfaz de consola soporta comandos tipo `/comando` que el parser de `InterfazConsola*` procesa. Comandos disponibles (implementados en las interfaces):

- `/help` — muestra ayuda contextual.
- `/teams` — lista equipos.
- `/join <equipo>` — unirse a un equipo.
- `/project <equipo>` — ver proyectos relacionados con un equipo.
- `/chat <equipo>` — entrar al chat del equipo.
- `/back` — volver al menú anterior.
- `/exit` — finalizar sesión / salir.

Técnicamente, las interfaces reciben la entrada del usuario, reconocen prefijo `/` y despachan al handler correspondiente en los Servicios (ej. `EquipoServicio.join/2`, `ProyectoServicio.list/1`).

## Ejemplos de código relevantes

Autenticación (ejemplo ilustrativo):

```elixir
defmodule AuthServicio do
  # Genera salt y hash SHA256
  def hash_password(password, salt) do
    :crypto.hash(:sha256, password <> salt) |> Base.encode16()
  end

  def login(username, password) do
    usuario = UsuarioServicio.find_by_username(username)
    if usuario && usuario.password_hash == hash_password(password, usuario.salt) do
      {:ok, usuario}
    else
      {:error, :invalid_credentials}
    end
  end
end
```

Ejemplo de verificación de permisos:

```elixir
if Autorizacion.can?(usuario, :create_project) do
  ProyectoServicio.create(params)
else
  {:error, :forbidden}
end
```

Ejemplo conceptual de publicación de avance:

```elixir
case ProyectoServicio.create_avance(proyecto_id, avance_params) do
  {:ok, avance} -> AvancesServidor.publish(avance)
  {:error, reason} -> {:error, reason}
end
```

## Archivos CSV (nombres esperados)

- `usuarios.csv`
- `equipos.csv`
- `proyectos.csv`
- `avances.csv`
- `mensajes.csv`
- `membresias.csv`

Estos archivos son la fuente de persistencia del prototipo y son manipulados por `PersistenciaCSV`.

## Licencia

Este repositorio se publica bajo la licencia MIT.

---
Tabla de contenido rápida:

- Resumen
- Arquitectura
- Chat distribuido
- Flujo de avances
- Ejecución
- Estructura de archivos
- Roles y permisos
- Modo comandos
- Ejemplos de código
- Licencia

Para más detalles, revise los módulos en `lib/` y los adaptadores en `lib/Adapter`.
# Hackathon App

Sistema distribuido de gestión de hackathons desarrollado en Elixir con arquitectura hexagonal, persistencia en CSV y capacidades de chat en tiempo real entre nodos distribuidos.

[![Elixir](https://img.shields.io/badge/Elixir-1.15+-blueviolet.svg)](https://elixir-lang.org/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

---

## Descripción del Proyecto

**Hackathon App** es un sistema integral para la gestión de eventos tipo hackathon que proporciona funcionalidades completas para organizadores, participantes y mentores. Implementa un modelo de arquitectura hexagonal (Ports & Adapters) con soporte para ejecución distribuida entre múltiples nodos Elixir, comunicación en tiempo real mediante chat distribuido y un sistema de publicación/suscripción para difusión de avances de proyectos.

El sistema está diseñado para ser escalable, tolerante a fallos y capaz de operar tanto en modo local como distribuido a través de múltiples máquinas conectadas en red.

### Características Principales

- **Arquitectura Hexagonal (Ports & Adapters)**: Separación clara entre dominio, servicios y adaptadores
- **Persistencia en CSV**: Almacenamiento ligero mediante archivos CSV con repositorio genérico
- **Autenticación Multi-Rol**: Sistema de roles (participante, mentor, organizador) con autorización basada en permisos
- **Seguridad de Contraseñas**: Hash SHA256 con salt para almacenamiento seguro de credenciales
- **Chat Distribuido**: Comunicación en tiempo real entre nodos Elixir mediante procesos remotos
- **Sistema Pub/Sub Propio**: Difusión de avances de proyectos en tiempo real
- **Múltiples Interfaces de Usuario**: Consolas especializadas según el contexto y rol del usuario
- **Modo Comandos**: Sistema de comandos tipo CLI para navegación rápida
- **Salas Temáticas**: Canales de chat organizados por temas y equipos

---

## Arquitectura del Sistema

### Diagrama de Capas

```
┌──────────────────────────────────────────────────────────────────┐
│                      INTERFACES (Adaptadores)                     │
│  ┌────────────────┐  ┌───────────────┐  ┌──────────────────┐    │
│  │ InterfazConsola│  │ InterfazLogin │  │InterfazProyectos │    │
│  │  (Organizador) │  │               │  │  (Participante)  │    │
│  └────────────────┘  └───────────────┘  └──────────────────┘    │
│  ┌────────────────┐  ┌───────────────┐  ┌──────────────────┐    │
│  │ InterfazEquipos│  │InterfazMentoria│ │  InterfazChat    │    │
│  └────────────────┘  └───────────────┘  └──────────────────┘    │
├──────────────────────────────────────────────────────────────────┤
│                      SERVICIOS (Application)                      │
│  ┌────────────────┐  ┌───────────────┐  ┌──────────────────┐    │
│  │UsuarioServicio │  │  AuthServicio │  │ EquipoServicio   │    │
│  └────────────────┘  └───────────────┘  └──────────────────┘    │
│  ┌────────────────┐  ┌───────────────┐  ┌──────────────────┐    │
│  │ProyectoServicio│  │AvancesServidor│  │  ChatServidor    │    │
│  └────────────────┘  └───────────────┘  └──────────────────┘    │
│  ┌────────────────┐  ┌───────────────┐                           │
│  │AvancesCliente  │  │CanalGeneral   │  │SalasTematicas    │    │
│  └────────────────┘  └───────────────┘  └──────────────────┘    │
├──────────────────────────────────────────────────────────────────┤
│                      DOMINIO (Core Business)                      │
│  ┌────────────────┐  ┌───────────────┐  ┌──────────────────┐    │
│  │    Usuario     │  │    Equipo     │  │    Proyecto      │    │
│  │   (Entity)     │  │   (Entity)    │  │    (Entity)      │    │
│  └────────────────┘  └───────────────┘  └──────────────────┘    │
│  ┌────────────────┐  ┌───────────────┐  ┌──────────────────┐    │
│  │    Avance      │  │   Mensaje     │  │   Membresia      │    │
│  │   (Entity)     │  │   (Entity)    │  │    (Entity)      │    │
│  └────────────────┘  └───────────────┘  └──────────────────┘    │
│  ┌────────────────┐                                               │
│  │ Autorizacion   │  (Lógica de permisos por rol)                │
│  └────────────────┘                                               │
├──────────────────────────────────────────────────────────────────┤
│                    PERSISTENCIA (Infrastructure)                  │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │                    PersistenciaCSV                        │    │
│  │  (Repositorio Genérico para entidades en archivos CSV)   │    │
│  └──────────────────────────────────────────────────────────┘    │
│  ┌─────────┐ ┌─────────┐ ┌──────────┐ ┌────────┐ ┌─────────┐   │
│  │usuarios │ │equipos  │ │proyectos │ │avances │ │mensajes │   │
│  │  .csv   │ │  .csv   │ │   .csv   │ │  .csv  │ │  .csv   │   │
│  └─────────┘ └─────────┘ └──────────┘ └────────┘ └─────────┘   │
│              ┌────────────┐                                       │
│              │membresias  │                                       │
│              │   .csv     │                                       │
│              └────────────┘                                       │
└──────────────────────────────────────────────────────────────────┘
```

### Descripción de Capas

#### 1. Capa de Dominio (Core Business)

Contiene las entidades del negocio y la lógica central del sistema. Esta capa es independiente de cualquier tecnología de persistencia o interfaz de usuario.

- **Usuario**: Entidad que representa a un usuario del sistema (participante, mentor u organizador)
- **Equipo**: Agrupación de usuarios para trabajar en proyectos
- **Proyecto**: Representa un proyecto desarrollado por un equipo
- **Avance**: Registro de progreso en un proyecto
- **Mensaje**: Unidad de comunicación en el sistema de chat
- **Membresia**: Relación entre usuarios y equipos
- **Autorizacion**: Módulo que verifica permisos según el rol usando `can?/2`

#### 2. Capa de Servicios (Application)

Implementa los casos de uso del sistema y coordina las operaciones entre el dominio y los adaptadores.

**UsuarioServicio**: Gestión del ciclo de vida de usuarios
```elixir
# Crear usuario con hash seguro de contraseña
UsuarioServicio.crear(nombre, email, password, rol)
UsuarioServicio.obtener_por_id(id)
UsuarioServicio.listar_todos()
```

**AuthServicio**: Autenticación y gestión de sesiones
```elixir
# Autenticar usuario con verificación de password
AuthServicio.autenticar(email, password)
AuthServicio.iniciar_sesion(usuario)
AuthServicio.cerrar_sesion()
```

**EquipoServicio**: Administración de equipos
```elixir
EquipoServicio.crear(nombre, descripcion)
EquipoServicio.agregar_miembro(equipo_id, usuario_id)
EquipoServicio.listar_miembros(equipo_id)
```

**ProyectoServicio**: Gestión de proyectos y avances
```elixir
ProyectoServicio.crear(equipo_id, titulo, descripcion, categoria)
ProyectoServicio.registrar_avance(proyecto_id, descripcion, porcentaje)
ProyectoServicio.cambiar_estado(proyecto_id, nuevo_estado)
```

**ChatServidor**: Servidor de chat distribuido registrado globalmente
```elixir
# Registro global para acceso desde cualquier nodo
:global.register_name(:chat_servidor, pid)
ChatServidor.enviar_mensaje(sala, usuario, contenido)
ChatServidor.suscribir(sala, pid)
```

**AvancesServidor**: Sistema pub/sub para difusión de avances
```elixir
AvancesServidor.publicar_avance(proyecto_id, avance)
AvancesServidor.suscribir_a_proyecto(proyecto_id, pid)
```

**CanalGeneral**: Canal público para mensajes generales
**SalasTematicas**: Gestión de salas de chat por tema o equipo

#### 3. Capa de Adaptadores (Interfaces)

Interfaces de usuario basadas en consola que adaptan las operaciones del sistema al usuario final.

- **InterfazConsolaLogin**: Pantalla de inicio de sesión y registro
- **InterfazConsola**: Interfaz principal para organizadores
- **InterfazConsolaProyectos**: Interfaz para participantes gestionar proyectos
- **InterfazConsolaEquipos**: Gestión de equipos y membresías
- **InterfazConsolaMentoria**: Interfaz para mentores revisar proyectos
- **InterfazConsolaChat**: Cliente de chat en tiempo real

#### 4. Capa de Persistencia (Infrastructure)

**PersistenciaCSV**: Repositorio genérico que abstrae la persistencia en archivos CSV

```elixir
defmodule PersistenciaCSV do
  @moduledoc """
  Repositorio genérico para persistencia en CSV
  """
  
  def guardar(archivo, entidad) do
    # Serializa y guarda la entidad en CSV
  end
  
  def obtener(archivo, id) do
    # Recupera una entidad por ID
  end
  
  def listar(archivo) do
    # Lista todas las entidades del archivo
  end
  
  def actualizar(archivo, id, campos) do
    # Actualiza campos específicos
  end
  
  def eliminar(archivo, id) do
    # Elimina una entidad
  end
end
```

Archivos CSV generados automáticamente:
- `usuarios.csv`: ID, nombre, email, password_hash, salt, rol
- `equipos.csv`: ID, nombre, descripción, fecha_creación
- `proyectos.csv`: ID, equipo_id, titulo, descripción, categoría, estado
- `avances.csv`: ID, proyecto_id, descripción, porcentaje, fecha
- `mensajes.csv`: ID, sala, usuario_id, contenido, timestamp
- `membresias.csv`: ID, equipo_id, usuario_id, fecha_union

---

## Chat Distribuido

### Arquitectura del Chat

El sistema de chat utiliza las capacidades de distribución nativas de Elixir/Erlang para permitir comunicación en tiempo real entre múltiples nodos.

```
┌─────────────────────────────────────────────────────────────┐
│                     Nodo Servidor                            │
│  ┌───────────────────────────────────────────────────┐      │
│  │  ChatServidor (registrado globalmente)            │      │
│  │  - Gestiona todas las salas                       │      │
│  │  - Rutea mensajes a suscriptores                  │      │
│  │  - Mantiene estado de salas activas               │      │
│  └───────────────────────────────────────────────────┘      │
│                          │                                   │
│                          │ :global.whereis_name()            │
│                          ▼                                   │
└─────────────────────────────────────────────────────────────┘
                           │
         ┌─────────────────┼─────────────────┐
         │                 │                 │
         ▼                 ▼                 ▼
┌────────────────┐  ┌────────────────┐  ┌────────────────┐
│   Nodo Cliente │  │  Nodo Cliente  │  │  Nodo Cliente  │
│       1        │  │       2        │  │       3        │
│  ┌──────────┐  │  │  ┌──────────┐  │  │  ┌──────────┐  │
│  │InterfazChat│ │  │  │InterfazChat│ │  │  │InterfazChat│ │
│  │            │  │  │  │            │  │  │  │            │  │
│  │ Suscrito a │  │  │  │ Suscrito a │  │  │  │ Suscrito a │  │
│  │ Sala Alpha │  │  │  │ Sala Beta  │  │  │  │ Sala Alpha │  │
│  └──────────┘  │  │  └──────────┘  │  │  └──────────┘  │
└────────────────┘  └────────────────┘  └────────────────┘
```

### Implementación Técnica

**Conexión entre Nodos**
```elixir
# Conectar nodos usando Node.connect/1
Node.connect(:"nodoservidor@192.168.1.100")

# Verificar nodos conectados
Node.list()
```

**Registro Global del Servidor**
```elixir
# En el nodo servidor
{:ok, pid} = ChatServidor.start_link()
:global.register_name(:chat_servidor, pid)

# Desde cualquier nodo cliente
servidor = :global.whereis_name(:chat_servidor)
GenServer.call(servidor, {:enviar_mensaje, sala, usuario, contenido})
```

**Suscripción a Salas**
```elixir
defmodule InterfazConsolaChat do
  def conectar(sala, usuario) do
    servidor = :global.whereis_name(:chat_servidor)
    GenServer.call(servidor, {:suscribir, sala, self()})
    escuchar_mensajes()
  end
  
  defp escuchar_mensajes do
    receive do
      {:nuevo_mensaje, sala, usuario, contenido, timestamp} ->
        IO.puts("[#{sala}] #{usuario}: #{contenido}")
        escuchar_mensajes()
    end
  end
end
```

**Envío de Mensajes**
```elixir
defmodule ChatServidor do
  def handle_call({:enviar_mensaje, sala, usuario, contenido}, _from, state) do
    mensaje = %{
      sala: sala,
      usuario: usuario,
      contenido: contenido,
      timestamp: DateTime.utc_now()
    }
    
    # Persistir mensaje
    PersistenciaCSV.guardar("mensajes.csv", mensaje)
    
    # Difundir a suscriptores
    suscriptores = Map.get(state.salas, sala, [])
    Enum.each(suscriptores, fn pid ->
      send(pid, {:nuevo_mensaje, sala, usuario, contenido, mensaje.timestamp})
    end)
    
    {:reply, :ok, state}
  end
end
```

### Salas Temáticas y Canal General

**CanalGeneral**: Canal público accesible para todos los usuarios
```elixir
CanalGeneral.publicar(usuario, mensaje)
CanalGeneral.suscribir(pid)
```

**SalasTematicas**: Salas organizadas por equipo o tema
```elixir
SalasTematicas.crear_sala(nombre, tema)
SalasTematicas.unirse(sala_id, usuario_id)
SalasTematicas.enviar(sala_id, usuario_id, mensaje)
```

---

## Sistema de Avances en Tiempo Real

El sistema implementa un mecanismo pub/sub propio para la difusión de avances de proyectos.

### Flujo de Publicación/Suscripción

```
Participante registra avance
        │
        ▼
┌──────────────────┐
│ ProyectoServicio │
│  registrar_avance│
└──────────────────┘
        │
        ▼ publicar_avance()
┌──────────────────┐
│ AvancesServidor  │────┐
│  (Pub/Sub)       │    │ difundir
└──────────────────┘    │
                        │
        ┌───────────────┼───────────────┐
        ▼               ▼               ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│AvancesCliente│ │AvancesCliente│ │AvancesCliente│
│  (Mentor)    │ │(Organizador) │ │(Participante)│
└──────────────┘ └──────────────┘ └──────────────┘
        │               │               │
        ▼               ▼               ▼
  Notificación    Notificación    Notificación
  en pantalla     en pantalla     en pantalla
```

### Implementación

**Suscripción a Avances**
```elixir
defmodule AvancesCliente do
  def suscribir_a_proyecto(proyecto_id) do
    AvancesServidor.suscribir(proyecto_id, self())
    escuchar_avances()
  end
  
  defp escuchar_avances do
    receive do
      {:nuevo_avance, proyecto_id, avance} ->
        IO.puts("Nuevo avance en proyecto #{proyecto_id}:")
        IO.puts("#{avance.descripcion} - #{avance.porcentaje}%")
        escuchar_avances()
    end
  end
end
```

**Publicación de Avances**
```elixir
defmodule ProyectoServicio do
  def registrar_avance(proyecto_id, descripcion, porcentaje) do
    avance = %{
      proyecto_id: proyecto_id,
      descripcion: descripcion,
      porcentaje: porcentaje,
      fecha: DateTime.utc_now()
    }
    
    # Guardar en persistencia
    PersistenciaCSV.guardar("avances.csv", avance)
    
    # Publicar a suscriptores
    AvancesServidor.publicar_avance(proyecto_id, avance)
    
    {:ok, avance}
  end
end
```

---

## Sistema de Roles y Autorización

### Roles Disponibles

El sistema soporta tres roles con permisos diferenciados:

| Rol | Permisos |
|-----|----------|
| **Organizador** | Gestionar usuarios, equipos, proyectos, mentorías, acceso completo al chat |
| **Participante** | Crear proyectos, registrar avances, cambiar estados, chat de equipo, modo comandos |
| **Mentor** | Revisar proyectos, avances, mensajes, chat, proporcionar retroalimentación |

### Verificación de Permisos

```elixir
defmodule Autorizacion do
  def can?(usuario, accion) do
    case {usuario.rol, accion} do
      {:organizador, _} -> true
      {:participante, :crear_proyecto} -> true
      {:participante, :registrar_avance} -> true
      {:participante, :usar_chat} -> true
      {:mentor, :revisar_proyecto} -> true
      {:mentor, :comentar_avance} -> true
      {:mentor, :usar_chat} -> true
      _ -> false
    end
  end
end

# Uso en servicios
def crear_proyecto(usuario, params) do
  if Autorizacion.can?(usuario, :crear_proyecto) do
    # Proceder con la creación
  else
    {:error, :no_autorizado}
  end
end
```

---

## Seguridad de Contraseñas

El sistema implementa hash seguro con salt para el almacenamiento de contraseñas.

```elixir
defmodule AuthServicio do
  def hashear_password(password) do
    salt = :crypto.strong_rand_bytes(16) |> Base.encode64()
    hash = :crypto.hash(:sha256, salt <> password) |> Base.encode64()
    {hash, salt}
  end
  
  def verificar_password(password, hash_almacenado, salt) do
    hash_calculado = :crypto.hash(:sha256, salt <> password) |> Base.encode64()
    hash_calculado == hash_almacenado
  end
end
```

---

## Modo Comandos

Sistema de comandos CLI para navegación rápida dentro de las interfaces.

### Comandos Disponibles

| Comando | Descripción | Ejemplo |
|---------|-------------|---------|
| `/help` | Muestra lista de comandos disponibles | `/help` |
| `/teams` | Lista todos los equipos activos | `/teams` |
| `/join <equipo>` | Unirse a un equipo específico | `/join Alpha` |
| `/project <equipo>` | Ver información del proyecto de un equipo | `/project Beta` |
| `/chat <equipo>` | Conectarse al chat de un equipo | `/chat Alpha` |
| `/back` | Volver al menú anterior | `/back` |
| `/exit` | Salir del sistema | `/exit` |

### Implementación

```elixir
defmodule ModoComandos do
  def ejecutar(comando, usuario) do
    case String.split(comando, " ", parts: 2) do
      ["/help"] -> mostrar_ayuda()
      ["/teams"] -> listar_equipos()
      ["/join", equipo] -> unirse_equipo(usuario, equipo)
      ["/project", equipo] -> mostrar_proyecto(equipo)
      ["/chat", equipo] -> iniciar_chat(usuario, equipo)
      ["/back"] -> {:back}
      ["/exit"] -> {:exit}
      _ -> {:error, "Comando no reconocido. Usa /help"}
    end
  end
end
```

---

## Ejecución del Sistema

### Modo Local

Para ejecutar el sistema en una sola máquina:

```bash
# Clonar el repositorio
git clone <url-repositorio>
cd hackathon_app

# Instalar dependencias
mix deps.get

# Compilar el proyecto
mix compile

# Ejecutar en modo local
mix run --no-halt
```

### Modo Distribuido

Para ejecutar el sistema distribuido entre múltiples máquinas:

**Paso 1: Iniciar el nodo servidor**
```bash
# En la máquina servidor (ej. 192.168.1.100)
elixir --name nodoservidor@192.168.1.100 --cookie secreto_compartido -S mix run --no-halt
```

**Paso 2: Iniciar nodos cliente**
```bash
# En la máquina cliente 1 (ej. 192.168.1.101)
elixir --name cliente1@192.168.1.101 --cookie secreto_compartido -S mix run --no-halt

# En la máquina cliente 2 (ej. 192.168.1.102)
elixir --name cliente2@192.168.1.102 --cookie secreto_compartido -S mix run --no-halt
```

**Paso 3: Conectar nodos**
```elixir
# Desde un nodo cliente, conectar al servidor
Node.connect(:"nodoservidor@192.168.1.100")

# Verificar conexión
Node.list()
# => [:"nodoservidor@192.168.1.100"]
```

### Consideraciones de Red

- Todos los nodos deben usar la misma **cookie** para conectarse
- Los nombres de nodos deben ser únicos y seguir el formato `nombre@ip_o_hostname`
- El firewall debe permitir conexiones en el puerto EPMD (4369) y puertos dinámicos (default: 9100-9155)
- Para producción, considerar el uso de TLS con `ssl_dist` para comunicación segura

---

## Estructura del Proyecto

```
hackathon_app/
├── lib/
│   ├── hackathon_app/
│   │   ├── dominio/
│   │   │   ├── usuario.ex
│   │   │   ├── equipo.ex
│   │   │   ├── proyecto.ex
│   │   │   ├── avance.ex
│   │   │   ├── mensaje.ex
│   │   │   ├── membresia.ex
│   │   │   └── autorizacion.ex
│   │   │
│   │   ├── servicios/
│   │   │   ├── usuario_servicio.ex
│   │   │   ├── auth_servicio.ex
│   │   │   ├── equipo_servicio.ex
│   │   │   ├── proyecto_servicio.ex
│   │   │   ├── chat_servidor.ex
│   │   │   ├── avances_servidor.ex
│   │   │   ├── avances_cliente.ex
│   │   │   ├── canal_general.ex
│   │   │   └── salas_tematicas.ex
│   │   │
│   │   ├── adaptadores/
│   │   │   ├── interfaz_consola_login.ex
│   │   │   ├── interfaz_consola.ex
│   │   │   ├── interfaz_consola_proyectos.ex
│   │   │   ├── interfaz_consola_equipos.ex
│   │   │   ├── interfaz_consola_mentoria.ex
│   │   │   └── interfaz_consola_chat.ex
│   │   │
│   │   └── persistencia/
│   │       └── persistencia_csv.ex
│   │
│   └── hackathon_app.ex
│
├── data/                          # Archivos CSV generados
│   ├── usuarios.csv
│   ├── equipos.csv
│   ├── proyectos.csv
│   ├── avances.csv
│   ├── mensajes.csv
│   └── membresias.csv
│
├── test/
│   ├── dominio/
│   ├── servicios/
│   └── persistencia/
│
├── config/
│   └── config.exs
│
├── mix.exs
└── README.md
```

---

## Gestión de Sesiones

El sistema utiliza Agents de Elixir para mantener el estado de sesión del usuario actual.

```elixir
defmodule SesionAgente do
  use Agent
  
  def start_link(_opts) do
    Agent.start_link(fn -> nil end, name: __MODULE__)
  end
  
  def iniciar_sesion(usuario) do
    Agent.update(__MODULE__, fn _ -> usuario end)
  end
  
  def obtener_usuario_actual do
    Agent.get(__MODULE__, & &1)
  end
  
  def cerrar_sesion do
    Agent.update(__MODULE__, fn _ -> nil end)
  end
end
```

---

## Ejemplos de Uso

### Flujo Completo para Participante

```elixir
# 1. Iniciar sesión
{:ok, usuario} = AuthServicio.autenticar("participante@example.com", "password123")
SesionAgente.iniciar_sesion(usuario)

# 2. Crear un equipo
{:ok, equipo} = EquipoServicio.crear("Innovadores", "Equipo enfocado en IA")

# 3. Unirse al equipo
EquipoServicio.agregar_miembro(equipo.id, usuario.id)

# 4. Crear un proyecto
{:ok, proyecto} = ProyectoServicio.crear(
  equipo.id,
  "Sistema de Recomendación con IA",
  "Plataforma que usa ML para recomendar contenido",
  "Inteligencia Artificial"
)

# 5. Registrar avance
ProyectoServicio.registrar_avance(
  proyecto.id,
  "Implementado modelo base de recomendación",
  35
)

# 6. Conectarse al chat del equipo
InterfazConsolaChat.conectar("equipo_#{equipo.id}", usuario.nombre)

# 7. Enviar mensaje
ChatServidor.enviar_mensaje("equipo_#{equipo.id}", usuario.nombre, "¡Avance completado!")
```

### Flujo Completo para Mentor

```elixir
# 1. Iniciar sesión
{:ok, mentor} = AuthServicio.autenticar("mentor@example.com", "mentorpass")
SesionAgente.iniciar_sesion(mentor)

# 2. Suscribirse a avances de un proyecto
AvancesCliente.suscribir_a_proyecto("proyecto_123")

# 3. Revisar proyectos
proyectos = ProyectoServicio.listar_por_categoria("Inteligencia Artificial")

# 4. Acceder al chat de un equipo
InterfazConsolaChat.conectar("equipo_456", mentor.nombre)

# 5. Proporcionar retroalimentación
ChatServidor.enviar_mensaje(
  "equipo_456",
  mentor.nombre,
  "Excelente avance. Consideren optimizar el modelo para mayor eficiencia."
)
```

### Uso del Modo Comandos

```elixir
# Dentro de InterfazConsolaProyectos
IO.gets("> ")
|> ModoComandos.ejecutar(usuario_actual)

# Usuario ingresa: /teams
# Output: Lista de todos los equipos

# Usuario ingresa: /join Innovadores
# Output: Te has unido al equipo 'Innovadores'

# Usuario ingresa: /chat Innovadores
# Output: Conectado al chat del equipo 'Innovadores'

# Usuario ingresa: /back
# Output: Regresa al menú de proyectos
```

---

## Testing

```bash
# Ejecutar todos los tests
mix test

# Ejecutar tests con cobertura
mix test --cover

# Ejecutar tests de un módulo específico
mix test test/servicios/chat_servidor_test.exs

# Ejecutar tests en modo watch
mix test.watch
```

---

## Contribución

Las contribuciones son bienvenidas. Por favor:

1. Fork el repositorio
2. Crea una rama para tu feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -am 'Agrega nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

---

## Licencia

Este proyecto está licenciado bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

---

## Autores

- Santiago Nieto Beltrán
- Yeimy Daniela Rodriguez
- Michael Murillo

---

## Contacto

Para preguntas, sugerencias o reportes de bugs, por favor abre un issue en el repositorio de GitHub.

---

**Hackathon App** - Sistema Distribuido de Gestión de Hackathons en Elixir
