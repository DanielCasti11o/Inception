FROM debian:bullseye

#instalamos los paquetes de nginx(servidor) y openssl(Certificados SSL)
RUN apt-get update && apt-get install -y nginx openssl

# Con este cmd no se apagará el contenedor
CMD ["nginx", "-g", "daemon off;"]
