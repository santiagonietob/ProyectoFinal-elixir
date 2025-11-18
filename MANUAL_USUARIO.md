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

3. **Iniciar el sistema**
   ```bash
   mix run --no-halt
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
