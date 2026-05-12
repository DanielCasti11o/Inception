apuntes

Los tres comandos que debes entender ahora
bashdocker build -t mi-imagen .
Lee el Dockerfile del directorio actual y construye una imagen llamada mi-imagen. No ejecuta nada todavía.
bashdocker run mi-imagen
Crea un contenedor a partir de mi-imagen y lo arranca. Cada vez que lo ejecutas, crea un contenedor nuevo e independiente.
bashdocker ps
Lista los contenedores que están corriendo ahora mismo. Con -a ves también los parados.
