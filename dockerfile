# syntax=docker/dockerfile:1.4
# ┌───────────────────────────────────────────────┐
# │ 1) Etapa de compilación y exportación       │
# └───────────────────────────────────────────────┘
FROM --platform=linux/amd64 debian:stable-slim AS builder

ARG GODOT_VERSION=4.4.1
ARG GODOT_TAG=${GODOT_VERSION}-stable

# Instala wget, unzip y librerías mínimas para el binario estándar
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates wget unzip \
      libglib2.0-0 libgtk-3-0 libx11-6 libxcursor1 libxinerama1 libxrandr2 libxi6 libxext6 \
      libasound2 libpulse0 libfreetype6 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /godot

# 1) Descarga y prepara el build estándar de Godot 4.4.1 para Linux x86_64
RUN wget -q \
    https://github.com/godotengine/godot/releases/download/${GODOT_TAG}/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip && \
    unzip Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip && \
    mv Godot_v${GODOT_VERSION}-stable_linux.x86_64 godot-export && \
    chmod +x godot-export

# 2) Descarga las plantillas de exportación
#RUN wget -q \
#    https://github.com/godotengine/godot/releases/download/${GODOT_TAG}/Godot_v${GODOT_VERSION}-stable_export_templates.tpz && \
#    unzip Godot_v${GODOT_VERSION}-stable_export_templates.tpz -d export_templates

# 2) Descarga las plantillas de exportación
RUN wget -q \
    https://github.com/godotengine/godot/releases/download/${GODOT_TAG}/Godot_v${GODOT_VERSION}-stable_export_templates.tpz && \
    unzip Godot_v${GODOT_VERSION}-stable_export_templates.tpz -d export_templates && \
    mkdir -p /root/.local/share/godot/export_templates/${GODOT_VERSION}.stable && \
    cp export_templates/templates/* /root/.local/share/godot/export_templates/${GODOT_VERSION}.stable/


# Copia las plantillas a la ruta esperada por Godot
RUN mkdir -p /root/.local/share/godot/export_templates/${GODOT_VERSION}.stable && \
    cp export_templates/templates/* /root/.local/share/godot/export_templates/${GODOT_VERSION}.stable/

# 3) Copia tu proyecto y exporta el servidor dedicado en modo headless
WORKDIR /project
COPY . .

ENV GODOT_EXPORT_TEMPLATES_PATH=/godot/export_templates

RUN mkdir -p bin && \
    /godot/godot-export \
      --headless \
      --export-release "Linux Server" /project/bin/server.x86_64

# Exportar PCK


# ┌────────────────────────────────────────────────┐
# │ 2) Etapa de runtime: contenedor ligero        │
# └────────────────────────────────────────────────┘
FROM debian:stable-slim

# Solo libstdc++ y certificados para runtime
RUN apt-get update && \
    apt-get install -y --no-install-recommends libstdc++6 ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copia el binario exportado
COPY --from=builder /project/bin/server.x86_64 .

# Exponemos el puerto UDP por defecto (ajústalo si tu juego usa otro)
EXPOSE 7777/udp

# Arrancamos en modo dedicado
CMD ["./server.x86_64", "--server"]


# build
# docker-server % export DOCKER_BUILDKIT=1
# docker buildx build --platform linux/amd64 -t mi-godot-server:4.4.1 .

# exec
#docker run -d \         
#  -p 127.0.0.1:7777:7777/udp \                                       
#  --name servidor-godot \
#  mi-godot-server:4.4.1

# push image to docker hub
# docker buildx build --platform linux/amd64 -t joelnicolass/mi-godot-server:latest --push .
# docker tag mi-godot-server:4.4.1 joelnicolass/mi-godot-server:latest
# docker push joelnicolass/mi-godot-server:latest

# eliminar contenedores
# docker rm $(docker ps -a -q)

# eliminar imagenes
# docker rmi $(docker images -a -q)



#pull sh
#docker pull joelnicolass/mi-godot-server:latest

#logs
#docker ps
#docker logs godot-server

# run in sh
#docker run -d \
#  --name godot-server \
#  -p 7777:7777/udp \
#  joelnicolass/mi-godot-server:latest

# eliminar
#docker stop godot-server
#docker rm godot-server
#docker rmi joelnicolass/mi-godot-server:latest