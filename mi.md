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
este nos sirve para que siempre que paremos el contenedor y lo volvamos a iniciar siempre se reinicie el servidor.

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


# EntryPoint

El entrypoint es básicamente una función de docker dónde especificamos lo primero que se va ejecutar en el docker una vez se construya con todas las condiciones del docker file.

Esto lo puedes ver directamente una vez que hayas terminado de crear el docker file, y especifiques en el dockerfile ENTRYPOINT[script.sh], que en la terminal una vez se construya la imagen, lo siguiente que se hará en el procedimiento es correr el entrypoint y hará todo lo que este en el script.

Básicamente lo que haremos en este script de bash será abrir el heredoc para crear un archivo SQL, dónde especificaremos de crear la tabla en caso de que no exista y también de crear el usuario con su contraseña y establecerle los privilegios, solo sí la conexion se realiza a tráves del contenedor de Wordpress.

También es importante recordar lo que es un:

Daemon: es el motor principal que se encarga de gestionar el contenedor, funciona en segundo plano y se encarga del trabajo a nivel de sistema operativo.

# .conf

Vale para el .conf de MariaDB le pasarémos instrucciones muy claras.

Y algo a tener en cuenta en los archivos .conf es que cuando ponemos: [mysqld] y [client], estos corchetes lo que hacen es separar el archivo en secciones.

Además a tener en cuenta que el "bind-address    = 0.0.0.0", que básicamente es decir que permitimos que un contenedor permita conexiones mediante de interfaces de cualquier contenedor dentro de la red interna de docker.

En cuanto al repaso de socket es importante recordar que es básicamente el identificador de una conexión: cliente-servidor.
Por eso mismo en el .conf es que separó en secciones del cliente y el deamon de la BBDD(motor), y a los les configuró el socket.

# WORDPRESS

En cuanto al contenedor de WordPress es importante tener en cuenta la importancia de este contenedor antes de empezar a profundizar en como lo montaremos y como se hará la arquitectura e implementación del mismo.

Como ya hicimos el de MariaDB que básicamente era la base de datos.

Ahora haremos el contenedor que se encargará de descargar y alojar todo el código fuente de WordPress en la carpeta: "/var/www/html" mediante los volumenes de docker.

# Volumenes DOCKER y montaje vinculado

[Esto_lo_saque_de_la_documentación_de_Docker__Traducido_de_DeepL]
{
    Los volúmenes son almacenes de datos persistentes para contenedores, creados y gestionados por Docker. Puedes crear un volumen de forma explícita mediante el comando `docker volume create`, o bien Docker puede crear un volumen durante la creación del contenedor o del servicio.

    Cuando se crea un volumen, este se almacena en un directorio del host de Docker. Al montar el volumen en un contenedor, lo que se monta en el contenedor es este directorio. Esto es similar al funcionamiento de los montajes vinculados, salvo que los volúmenes son gestionados por Docker y están aislados de la funcionalidad principal de la máquina host.

    Los volúmenes no son una buena opción si necesitas acceder a los archivos desde el host, ya que el volumen está gestionado completamente por Docker. Utiliza montajes vinculados si necesitas acceder a archivos o directorios tanto desde los contenedores como desde el host.

    Traducción realizada con la versión gratuita del traductor DeepL.com
}

Ahora para complementar esto, vi que ponía que era similar a los montajes vinculados, pero claro y eso, ¿Que es?.

Pues un montaje vinculado es básicamente la manera de conectar una carpeta específica de tu computadora real (host) directamente con una carpeta dentro del contenedor sí cambias algo del archivo, docker lo ejecuta al instante (PROGRAMAR EN VIVO).

Ahora los volumenes son una carpeta en una zona interna y reservada del disco duro para el docker. Lo gestiona el docker todo. Y se usa unicamente para almacenamiento persistente.

Y el funcionar similar, es por la interpretación del sistema operativo, porque los ve a los dos como una carpeta con una dirección de memoria en el disco duro. La diferencia real es que el [montaje_vinculado] no guarda esos datos de forma segura, es decir si estamos escribiendo un html se esta transcribiendo al docker como con una carpeta dentro del docker igual, pero si la eliminamos en nuestro ordenador por error, perdemos ese archivo. En cambio con el [Volumen_docker] no tenemos acceso a esos datos de manera tan fácil ya que solo son accesibles dentro del sistema docker, entonces no podremos modificarla o eliminarla desde nuestro host sin conectarnos a docker. EVITANDO ELIMINARLA POR ERROR AL NO TENERLA VISIBLE Y ACCESIBLE.

# Procesamiento lógico de PHP-FPM

En este contenedor además de guardar los archivos encenderemos un motor llamado PHP-FPM : gestor de procesos avanzado para PHP. Permite que el servidor web (como Nginx o Apache) delegue la ejecución de archivos .php a procesos independientes, lo que mejora radicalmente el rendimiento, la estabilidad y la gestión de recursos en sitios de alto tráfico. Que se quedará escuchando en el puerto 9000 interno de Docker.

# Entrypoint.sh

En este script de WordPress lo que configuraremos es básicamente la estructura del contenedor post-construcción de imagen que se dividirá en modulos.

[wp_core_download] : descargar de los servidores oficiales de WordPress el codigo fuente limpio y lo descomprime en /var/www/html.

[wp_config_create] : Se encargá de conectar la lógica con el almacenamiento. BBDD.

[wp_core_install] : Se encarga de inicializar la BBDD y configurar el usuario administrador.

[wp_user_create] : Gestión de datos de usuarios adicionales.

y despúes el exec que es la ejecución del motor.

En general lo más importante de este contenedor es el funcionamiento del entrypoint y por ejemplo en el [dockerfile] tener en cuenta que que debemos que creamos el volumen en /var/www/html y también que debemos crear el usuario www-data y a parte en el [www.conf] importante que escuche el TCP en vez del socket UNIX, ya que lo que vamos a hacer es comunicar dos contenedores como si fueran máquinas distintas y el socket UNIX funciona para comunicación ultra rápida pero dentro de la misma máquina, en cambio el TCP funciona a tráves de red y usarémos la red interna de docker para la comunicación, además de esto importante redirigir los logs de error a la stderr para en caso tal, poder hacer debug, ya que por defecto PHP-FPM manda esto a un archivo temporal que desaparece con la destrucción del contenedor entonces al ser un error que no nos deje crear el contenedor,pues no podremos ver los logs, entonces simplemente lo cambiamos para poder verlos al instante.

[listen/modo] = [0.0.0.0/escucha_cualquier_ip] : [9000/puerto]

# NGINX

Vale lo primero a tener en cuenta con este contenedor es que será el único con un puerto expuesto al exterior:443 pero bajo el protocolo de SSL/TLS asegurándonos de que sea HTTPS.

Debemos entender los certificados SSL/TLS, básicamente es un certificado que asegurá que el paquete de datos que va a salir/entrar al servidor este cifrado y protegido, y solo se pueda abrir con la llave privada.

y HTTPS es el HTTP pero con el uso de estos certificados.


[gemini]
------------------------------------------------
[Usuario en el navegador]
       │
       │ (1) Envía contraseña cifrada vía HTTPS (Puerto 443)
       ▼
 ┌───────────┐
 │   NGINX   │ <── (2) Recibe el paquete, usa su Llave Privada, lo descifra
 └─────┬─────┘         y comprueba que todo es seguro y correcto.
       │
       │ (3) Envía la petición ya procesada en limpio a WordPress
       ▼     a través de la red interna de Docker (Puerto 9000).
 ┌───────────┐
 │ WordPress │
 └───────────┘
------------------------------------------------

# Entrypoint

Aqui dentro del script hubo algo concretamente que me llamo bastante la atención y fue el proceso de como se generan los certificados TLS.

[nginx/tools/entrypoint.sh] lineas 12-18
openssl req -x509 \
		-nodes \
		-days 365 \
		-newkey rsa:2048 \
		-keyout /etc/nginx/ssl/nginx.key \
		-out /etc/nginx/ssl/nginx.crt \
		-subj "/C=ES/ST=Madrid/L=Madrid/O=42/CN=${DOMAIN_NAME}"

Entonces quise profundizar en este procedimiento por partes:

req : Usa la gestión de solicitudes de firma de certificados y generación de claves

-x509 : Esta opción genera un certificado autofirmado (self-signed) en lugar de una solicitud de certificado (CSR).

[Lei_documentacion_y_pregunté_a_gemini_y_me_dio_este_ejemplo]
-------------------------------------------------------------
En el mundo de la seguridad web tradicional, el proceso para conseguir un certificado seguro consta de dos pasos separados:

    Paso 1 (La Solicitud): Generas un archivo llamado CSR (Certificate Signing Request / Solicitud de Firma de Certificado). Es como rellenar un formulario oficial con tus datos (tu nombre, tu dominio, tu país) pero sin firmar por ninguna autoridad.

    Paso 2 (La Firma): Coges ese archivo de solicitud (CSR), se lo envías a una entidad certificadora (como Let's Encrypt o DigiCert), ellos lo revisan y te devuelven el Certificado Oficial firmado.

¿Qué hace exactamente la bandera -x509 en nuestro caso?

La bandera -x509 le dice a OpenSSL: "Salta los intermediarios. No quiero una solicitud para enviar a nadie; quiero que firmes los datos tú mismo ahora mismo y me des el certificado final".
-------------------------------------------------------------

-nodes : Significa que no queremos cifrar la llave privada con una contraseña. pedirá que ingresemos una contraseña todo el rato que iniciemos el contenedor para que se pueda gestionar la llave privada.

-days 365 : El tiempo de validez del certificado.

-newkey rsa:2048 : Genera al mismo tiempo una nueva llave criptográfica utilizando el algoritmo RSA con una longitud de 2048 bits (el estándar seguro actual).

Algoritmo RSA : Es el algoritmo base de la ciberseguridad actual con el uso de llaves públicas y privadas.
Sin profundizar lo que entendí es factorizar el producto(resultado) de la multiplicación de dos números primos enormes y secretos.
Entonces claro con ese producto(resultado) poder encontrar los dos números que hicieron parte de la multiplicación inicial es un proceso que podría tardar demasiado tiempo.

-keyout: La ruta dentro del contenedor donde guardará la Llave Privada

-out: La ruta donde guardará el Certificado Público

-----------------------------------------------
-subj: Te ahorra tener que rellenar el cuestionario interactivo por la terminal de forma manual. Automatiza los campos obligatorios del certificado:

    C=ES (Country / País: España)

    ST=Madrid (State / Comunidad o Estado)

    L=Madrid (Locality / Ciudad)

    O=42 (Organization / Escuela 42)

    CN=${DOMAIN_NAME} (Common Name: El dominio exacto de tu web, que en tu caso se resolverá como tu login de 42, por ejemplo dacastil.42.fr).
-------------------------------------------------

