# Manual de Usuario — Hackathon App

Bienvenido a Hackathon App. Este manual explica de forma clara y práctica cómo instalar, iniciar sesión y usar la aplicación desde la consola, según su rol (organizador, participante o mentor).

## Contenido

- Introducción
- Requisitos
- Instalación
- Inicio de sesión y registro
- Navegación según rol
- Interfaz del organizador
- Interfaz del participante
- Interfaz del mentor
- Uso del chat y salas temáticas
- Modo comandos (con ejemplos)
- Solución de problemas comunes

---

## Introducción

Hackathon App es una aplicación de consola desarrollada en Elixir que facilita la gestión de un hackathon: gestión de usuarios, equipos, proyectos, registro de avances y comunicación en tiempo real (chat) entre participantes, mentores y organizadores. Está pensada para ejecutarse tanto en un solo equipo como en modo distribuido entre varios nodos Elixir.

## Requisitos

- Elixir y Erlang instalados (compatible con versiones comunes; use la versión que soporta su `mix.exs`).
- Git (opcional, para clonar el repositorio).
- Permisos de lectura/escritura en la carpeta del proyecto (para archivos CSV).
- En modo distribuido: conectividad de red entre nodos y cookie compartida.

## Instalación paso a paso

1. Clonar el repositorio (si corresponde):

```bash
git clone <repo-url>
cd ProyectoFinal-elixir/hackaton
```

2. Instalar dependencias y compilar (si hay dependencias):

```bash
mix deps.get
mix compile
```

3. Archivos CSV: Si no existen, la aplicación crea automáticamente:

- `usuarios.csv`
- `equipos.csv`
- `proyectos.csv`
- `avances.csv`
- `mensajes.csv`
- `membresias.csv`

4. Iniciar la aplicación en modo local:

```bash
mix run --no-halt
```

5. Para ejecución distribuida, ver la sección correspondiente más abajo.

## Inicio de sesión y registro

Al iniciar la aplicación, verá el prompt de `InterfazConsolaLogin`. Opciones típicas:

- Iniciar sesión (login)
- Registrarse (crear cuenta)

Registro (pasos generales):

1. Seleccione `Registrarse` en la pantalla de login.
2. Proporcione: `nombre`, `username`, `contraseña` y `rol` (e.g., `participante`, `mentor`, `organizador`).
3. La contraseña se almacena de forma segura usando `salt` + hash SHA256; la aplicación guarda el `salt` y el `password_hash` en `usuarios.csv`.

Inicio de sesión (pasos generales):

1. Seleccione `Iniciar sesión` e ingrese `username` y `contraseña`.
2. Si las credenciales son correctas, accederá a la interfaz correspondiente a su rol.

Si olvida la contraseña: actualmente no hay flujo de recuperación automatizado; contacte al organizador para reiniciar su cuenta.

## Navegación según el rol

La navegación en la consola se maneja mediante menús y comandos. Dependiendo del rol, se mostrarán opciones distintas.

- Organizador: acceso completo.
- Participante: acceso a creación de proyectos, avances y chat.
- Mentor: acceso a revisión y retroalimentación.

En cualquier momento puede usar `/help` para ver los comandos disponibles.

## Interfaz del organizador

El organizador puede:

- Crear, editar y eliminar usuarios.
- Crear y gestionar equipos.
- Crear y asignar proyectos a equipos.
- Coordinar mentorías.
- Moderar y participar en el chat general y salas temáticas.

Acciones comunes (ejemplos):

- `Usuarios -> Crear usuario` (ingrese datos y rol).
- `Equipos -> Crear equipo` (nombre, descripción).
- `Proyectos -> Crear proyecto` (asociar a equipo, estado inicial).
- `Chat -> Moderar mensajes` (eliminar o advertir usuarios si aplica).

El menú de organizador está expuesto por `InterfazConsola` principal.

## Interfaz del participante

Funciones principales:

- Crear proyectos personales o de equipo.
- Registrar avances en proyectos (`ProyectoServicio.create_avance`).
- Cambiar estados de su proyecto (ej. `en progreso`, `finalizado`).
- Unirse a equipos y ver miembros.
- Participar en chats de equipo y salas temáticas.

Flujo típico para registrar un avance:

1. Navegar a `Proyectos`.
2. Seleccionar el proyecto objetivo.
3. Elegir `Registrar avance` y describir el avance.
4. El avance se persiste en `avances.csv` y se difunde en tiempo real vía `AvancesServidor`.

## Interfaz del mentor

El mentor tiene opciones orientadas a revisión y feedback:

- Listar proyectos asignados.
- Revisar avances recientes y dejar comentarios.
- Comunicarse con participantes por chat.

Dependiendo de la implementación de `InterfazConsolaMentoria`, el mentor puede marcar tareas como revisadas o solicitar cambios.

## Cómo usar el chat

El chat permite comunicación en:

- Canal general (`CanalGeneral`).
- Salas temáticas (`SalasTematicas`).
- Chats por equipo.

Uso básico:

1. Desde el menú, seleccione `Chat` o use el comando `/chat <equipo>`.
2. Escriba su mensaje y presione Enter.
3. Los mensajes se muestran en la consola y se guardan en `mensajes.csv`.

Comportamiento distribuido:

- Si su instancia está conectada a otros nodos (mediante `Node.connect`), los mensajes se propagan entre nodos y todos los participantes conectados verán los mensajes en tiempo real.

## Cómo usar las salas temáticas

Las salas temáticas son canales específicos por tema (ej. `IA`, `Frontend`, `Backend`). Para unirse o enviar mensajes:

- Listar salas: `/rooms` o desde menú `Salas`.
- Unirse: comando o menú `Unirse a sala`.
- Enviar mensaje: seleccione la sala y envíe el texto.

Los mensajes en salas siguen el mismo mecanismo de difusión y persistencia que el canal general.

## Modo comandos (guía para usuarios)

La aplicación soporta comandos rápidos que empiezan con `/`.

Comandos más útiles:

- `/help` — muestra comandos y uso.
- `/teams` — lista equipos disponibles.
- `/join <equipo>` — unirse a un equipo.
- `/project <equipo>` — ver proyectos del equipo.
- `/chat <equipo>` — entrar al chat del equipo.
- `/back` — volver al nivel de menú anterior.
- `/exit` — cerrar sesión o salir de la aplicación.

Ejemplos prácticos:

1. Unirse a un equipo llamado `Alpha`:

```
/join Alpha
```

2. Entrar al chat del equipo `Alpha`:

```
/chat Alpha
```

3. Ver ayuda rápida:

```
/help
```

## Ejecución en modo distribuido (para usuarios avanzados)

Si desea usar la aplicación en modo distribuido (varios equipos conectados entre sí):

1. En una máquina que actúe como servidor, inicie:

```powershell
elixir --name nodocliente1@192.168.11.103 --cookie hackathon -S mix run --no-halt
```

2. En otras máquinas (clientes), inicie con names distintos y la misma cookie:

```powershell
elixir --name cliente1@IP --cookie c -S mix run --no-halt
```

3. En los clientes, conecte al servidor (si no se conectan automáticamente):

```elixir
Node.connect(:'nodoservidor@IP')
```

Nota: Reemplace `IP` por la dirección adecuada y asegúrese de que la red permita conexión entre los puertos Erlang/Elixir.

## Solución de problemas comunes

- La aplicación no crea CSV o no tiene permisos:
  - Verifique permisos de escritura en la carpeta `hackaton/data`.

- Fallo en login:
  - Verifique que el `username` exista en `usuarios.csv`.
  - Asegúrese de usar la contraseña correcta; la aplicación compara hash SHA256 con salt.

- Problemas al conectar nodos:
  - Compruebe que la cookie sea la misma (`--cookie c`).
  - Verifique la resolución de nombres/IP y puertos.
  - Desde la consola Elixir, use `Node.list()` para ver nodos conectados.

- Mensajes no se difunden:
  - Confirme que `ChatServidor` esté registrado y corriendo.
  - Revise logs de la aplicación para errores al enviar mensajes.

## Preguntas frecuentes (FAQ)

- ¿Puedo usar esta aplicación sin conocer Elixir? Sí — la interacción es por consola y las instrucciones aquí son suficientes para operar como usuario.
- ¿Se pueden migrar los CSV a una base de datos? Sí — `PersistenciaCSV` es un adaptador; se puede implementar otro adaptador para una BD relacional sin cambiar la lógica de dominio.

---

Si necesita más ayuda o desea que se añadan funcionalidades (por ejemplo recuperación de contraseña, interfaz web, o integración con bases de datos), abra un issue o contacte al equipo de desarrollo.
# ProyectoFinal-elixir
# Manual de Usuario - Hackathon App

## Introducción

Hackathon App es un sistema de gestión para eventos tipo hackathon que permite:
- Registrar usuarios (participantes y mentores)
- Crear y gestionar equipos
- Registrar proyectos por categoría
- Chatear en tiempo real por equipos
- Todo desde una interfaz de consola

## Requisitos Previos

1. **Elixir**
   - Versión recomendada: 1.15 o superior
   - Verificar instalación:
     ```bash
     elixir -v
     ```
   - Si no está instalado, seguir las instrucciones en: https://elixir-lang.org/install.html

2. **Git**
   - Para clonar el repositorio
   - Verificar instalación:
     ```bash
     git --version
     ```

## Instalación

1. **Clonar el repositorio**
   ```bash
   git clone <url-del-repositorio>
   cd hackathon_app
   ```

2. **Instalar dependencias**
   ```bash
   mix deps.get
   ```

3. **Iniciar el sistema modo servidor**
   ```bash
   elixir --name nodoservidor@192.168.11.103 --cookie hackathon -S mix run --no-halt
   ```

4. **Iniciar el sistema modo cliente**
   ```bash
   elixir --name nodocliente1@192.168.11.103 --cookie hackathon -S mix run --no-halt
   ```


## Uso del Sistema

### 1. Gestión de Usuarios

```elixir
# Registrar un nuevo usuario
HackathonApp.registrar_usuario(%{
  "nombre" => "Ana",
  "rol" => "participante"
})

# Registrar un mentor
HackathonApp.registrar_usuario(%{
  "nombre" => "Juan",
  "rol" => "mentor"
})

# Iniciar sesión
{:ok, usuario} = HackathonApp.iniciar_sesion("Ana")
```

### 2. Gestión de Equipos

```elixir
# Crear un equipo
HackathonApp.crear_equipo(%{"nombre" => "Alpha"})

# Unirse a un equipo
HackathonApp.unirse_a_equipo("Alpha", usuario.id)
```

### 3. Gestión de Proyectos

```elixir
# Registrar un proyecto
HackathonApp.registrar_proyecto(%{
  "equipo" => "Alpha",
  "titulo" => "EcoAI",
  "categoria" => "Ambiente"
})

# Listar proyectos por categoría
HackathonApp.listar_proyectos_por_categoria("Ambiente")
```

### 4. Sistema de Chat

```elixir
# Conectarse al chat de un equipo
HackathonApp.ejecutar_comando("/chat Alpha", usuario.nombre)

# Enviar un mensaje
HackathonApp.enviar_mensaje("Alpha", usuario.id, "¡Hola equipo!")
```

### 5. Comandos Disponibles

El sistema reconoce los siguientes comandos:

- `/help`: Muestra la lista de comandos disponibles
- `/teams`: Lista todos los equipos activos
- `/join <equipo>`: Permite unirse a un equipo específico
- `/project <equipo>`: Muestra información del proyecto del equipo
- `/chat <equipo>`: Conecta al canal de chat del equipo

Ejemplo de uso:
```elixir
HackathonApp.ejecutar_comando("/help", usuario.nombre)
HackathonApp.ejecutar_comando("/teams", usuario.nombre)
HackathonApp.ejecutar_comando("/join Alpha", usuario.nombre)
```

## Pruebas de Rendimiento

### 1. Pruebas Unitarias
```bash
mix test                    # Ejecutar todas las pruebas
mix test test/hackathon_app/servicios/chat_servicio_test.exs  # Probar chat
```

### 2. Simulador de Carga
```elixir
# Configurar y ejecutar simulación
HackathonApp.Tests.CargaSimulador.ejecutar(
  num_equipos: 5,          # Número de equipos a simular
  msgs_por_equipo: 200,    # Mensajes por equipo
  concurrencia: 10         # Procesos concurrentes
)
```

#### Interpretación de Resultados
El simulador mostrará:
- Número de equipos simulados
- Total de mensajes enviados
- Tiempo total de ejecución
- Throughput (mensajes por segundo)

Ejemplo de salida:
```
Resultados:
Equipos simulados: 5
Mensajes totales: 1000
Tiempo total: 2.1s
Throughput: 476 msg/s
```

## Características del Sistema

### 1. Escalabilidad
- Manejo eficiente de múltiples equipos y usuarios
- Procesamiento concurrente de mensajes
- Persistencia optimizada en CSV

### 2. Alto Rendimiento
- Comunicación en tiempo real con PubSub
- Procesamiento asíncrono de mensajes
- Cache eficiente de datos en memoria

### 3. Seguridad
- Validación de datos en entrada
- Separación de roles (participante/mentor)
- Aislamiento de canales de chat por equipo

### 4. Tolerancia a Fallos
- Recuperación automática de procesos caídos
- Persistencia confiable de datos
- Manejo de errores en cada capa

## Solución de Problemas

1. **Error al iniciar sesión**
   - Verificar que el usuario está registrado
   - Comprobar que el nombre coincide exactamente

2. **Mensajes no llegan**
   - Verificar conexión al canal correcto
   - Asegurarse de ser miembro del equipo

3. **Errores de persistencia**
   - Verificar permisos en carpeta `data/`
   - Comprobar formato de datos

## Licencia y Créditos

### Autores

- [Santiago Nieto Beltrán]
- [Yeimy Daniela Rodriguez]
- [Michael Murillo]

### Licencia
MIT License - 2025
