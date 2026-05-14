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
