apuntes

Los tres comandos que debes entender ahora
bashdocker build -t mi-imagen .
Lee el Dockerfile del directorio actual y construye una imagen llamada mi-imagen. No ejecuta nada todavía.
bashdocker run mi-imagen
Crea un contenedor a partir de mi-imagen y lo arranca. Cada vez que lo ejecutas, crea un contenedor nuevo e independiente.
bashdocker ps
Lista los contenedores que están corriendo ahora mismo. Con -a ves también los parados.

Arquitectura microservicios

Lo que nos ayuda el usar una estructura de microservicios y no monolitica es poder aislar partes de la infraestructura y asegurar que la aplicación/web siga funcionando en caso de que una sección especifica de la app fallé, por ejemplo, la BBDD si falla la BBDD, que no deje de funcionar toda la web/app.
También será muy importante el poder conectar los servicios para que se puedan comunicar entre ellos y sea una infraestructura funcional.

# DOCKER NETWORKS

Antes hablamos de que nuestro problema era la comunicación de los servicios para poder realizar correctamente nuestra infraestructura, para una buena comunicación las redes Docker son el mecanismo que controla quien habla con quien y como.

La más usada y que probablemente usaré será:

# Bridge
Es una red privada dentro del host. Dónde los contenedores conectados pueden verse entre sí por nombres. El tráfico nunca saldrá al exterior a no ser que tengas puertos expuestos. Docker Compose crea una bridge automáticamente.

También existen tipos de red interesantes como:

none: No tiene ninguna interfaz de red. Completamente aislado.

macvlan: Red física directa. Hace el contenedor visible en una red fisica real como si fuera una maquina.

# Restart: Policy --> Docker Compose

no / (default): Si el contenedor se para, se queda parado.

always / (El que usaré): Se reinicia siempre, pase lo que pase.

on-failure : Solo se reinicia si el contenedor fallo     (return != 0), si nosotros lo paramos, no se reinicia.

unless-stopped : igual que "always", pero si tú lo detuviste manualmente antes de apagar el PC, no volverá a arrancar solo al encenderlo.

He visto la nomenclatura y palabras clave que levantan cosas en el compose.

Me ha llamado la atención :

# volumes

Declara volumenes nombrados para persistir datos entre reinicios
Y estos volumenes viven fuera del ciclo de vida de los contenedores.
Sí un contenedor se destruye y se recrea los datos persisten.
Y lo usaré para guardar la BBDD de Wordpress y los archivos del sitio.

# secrets

Son la manera correcta de guardar las contraseñas en inception, ya que no aparecen en un .env ni en el historial de la imagen.

Ya que estamos hablando del secrets tenemos que tener cuenta en este proyecto que deben haber varios niveles de seguridad para los datos de configuracion del proyecto.

# NIVEL 1: .env
Variables de entorno de configuracion no sensible: Name de la database, el domain o el title del site.

# NIVEL 2: secrets/
Las contraseñas de MariaDB o datos un poco más sensibles. Viven en la máquina local.


_______________________________________________________________
4. Paso a paso para implementarlo:

    Crea los archivos de texto:
    Crea un archivo llamado db_password.txt y escribe dentro solo tu contraseña (ej: mi_password_seguro_123).

    Modifica el Compose:
    Añade la sección secrets: abajo del todo y dentro del servicio mariadb, como en el ejemplo de arriba.

    En el contenedor:
    Cuando levantes con docker-compose up, si entras en el contenedor de mariadb (docker exec -it mariadb bash), verás que existe un archivo en /run/secrets/db_password que contiene tu clave.
_______________________________________________________________


# Nuevas utilidades del MAKEFILE

He visto que para el makefile podré usar cosas nuevas como:

build: construye imagenes sin arrancarlas

up: arranca contenedores ya construidos

down: detiene y elimina contenedores e imagenes.

status / logs : Inspección del stack en ejecucción. Logs en tiempo real.


# Limpieza profunda del Makefile con docker compose

@docker system prune -a --volumes -f

El "system prune" busca y elimina lo que docker llama dangling(recursos colgados).

La flag "-a" all/todo

-- volumes : volumenes: Borrar el volumen te asegura que la base de datos se creará desde cero de verdad.

-f : FORZARLO

# MariaDB

estructura de archivos / funcionalidad de archivos.

# Dockerfile

Queria empezar entendiendo el .dockerignore pero me encontré con un problema que para poder entenderlo, debía profundizar en el concepto básico del dockerfile.
Y es que existe algo que se llama el "Build Context".

Cuando ejecutamos el comando --> docker compose build.
lo que pasa es que toma desde la ruta actual todo los archivos existentes de esa ruta y crea un archivo comprimido invisible y envia ese paquete a docker daemon(motor). Este proceso se conoce como "Sending build context to Docker daemon."

Ahora entendiendo esto, vamos con el ignore...

# .dockerignore
es similar al .gitignore.
Es para no incluir archivos. Ya que no queremos que hagan parte de la imagen.
Ahora si tenemos la carpeta(ruta donde realizamos el build context) entonces no pasa nada y verás que el contexto pesa unos poco kb.
Esto es bueno usarlo, ya que como sabemos al usar visual se crean a veces archivos ocultos como .vscode/ entonces con esto evitamos en todo momento que se pueda subir basura al proyecto.
También evita que por ejemplo en el build context de la imagen subamos notas de contraseñas como las de los secrets generando vulnerabilidades de la seguridad.
HACIENDOLO DE ESTA MANERA MUY IMPRESCINDIBLE.

# conf/ .conf

Es el archivo de conf original de MariaDB.
Exceptuando porque debemos cambiar una linea:

bind-address = 0.0.0.0 // Dirección de escucha. Tarjeta de red.

Esto lo que hará es permitir conexiones que vengan de cualquier IP dentro de la misma red. Para que después desde el contenedor de WordPress nos podamos conectar a ella.

# entrypoint.sh // script que crea el user y especifica que debe ser del docker de WordPress.

ENTRYPOINT	Especifique el ejecutable predeterminado. función del dockerfile.

Y esto exactamente lo que va a hacer es crear el punto de entrada único que se pueda conectar a la base de datos. En este caso nos referiremos a un usuario que crearemos y especificaremos que debe ser proveniente de WordPress para poder conectarse a MariaDB.

# DOCKER FILE : MARIA DB

# Penúltima versión estable de Alpine (no latest)
FROM alpine:3.19

Vale primero debemos tener en cuenta que el from es la base de la cual va a tomar como referencia para el sistema operativo que correrá en el docker, en este caso será Alphine.

Alphine es una distribución de linux ultra ligera: 5mb, al tener tan pocos programas instalados por defecto tiene menos brechas para ser hackeada.

# Descarga de paquetes.

Cuando Docker ejecuta ese comando apk add mariadb durante la construcción (el build), el gestor de paquetes de Alpine descarga MariaDB e instala cientos de archivos automáticamente. Entre ellos, crea la carpeta /etc/my.cnf.d/ y mete ahí dentro los archivos de configuración por defecto.

# Funcionamiento del COPY

COPY  <ruta_en_tu_ordenador>  <ruta_dentro_del_contenedor>

<ruta_en_tu_ordenador> = aqui podemos poner la ruta/archivo que queramos que este dentro del build context.

<ruta_dentro_del_contenedor> = Es una ruta absoluta dentro del disco duro virtual dentro de contenedor. Tenemos que tener en cuenta que en el caso de que no exista una ruta

Además con este comando podemos copiar varios archivos a un destino.

COPY <archivo1.txt> <archivo2.txt> <notas.txt> /app/
