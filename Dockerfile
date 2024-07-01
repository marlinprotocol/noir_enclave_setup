# # base image
# FROM alpine:3.17

# # install dependency tools
# RUN apk add --no-cache net-tools iptables iproute2 wget curl bash git

# # RUN curl -L https://raw.githubusercontent.com/noir-lang/noirup/main/install | bash && \
# #     /bin/bash -c "source ~/.profile && noirup"
# RUN mkdir -p nargo/bin
    
# RUN curl -o nargo/bin/nargo-x86_64-unknown-linux-musl.tar.gz -L https://github.com/noir-lang/noir/releases/download/v0.30.0/nargo-x86_64-unknown-linux-musl.tar.gz
 
# RUN tar -xvf nargo/bin/nargo-x86_64-unknown-linux-musl.tar.gz -C nargo/bin/
# Use an Ubuntu base image
FROM ubuntu:22.04

# Install dependency tools
RUN apt-get update && apt-get install -y \
    net-tools iptables iproute2 wget bash git curl \
    libc++1 libc++abi1

# Install noirup
RUN curl -L https://raw.githubusercontent.com/noir-lang/noirup/main/install | bash

# Add noirup directory to PATH and ensure it's sourced
ENV PATH="/root/.nargo/bin:${PATH}"
RUN echo 'export PATH="$HOME/.nargo/bin:$PATH"' >> ~/.bashrc

RUN bash -c "source ~/.profile && noirup"
# ENV PATH="$PATH:/nargo/bin"

WORKDIR /app

# supervisord to manage programs
RUN wget -O supervisord http://public.artifacts.marlin.pro/projects/enclaves/supervisord_master_linux_amd64
RUN chmod +x supervisord

# transparent proxy component inside the enclave to enable outgoing connections
RUN wget -O ip-to-vsock-transparent http://public.artifacts.marlin.pro/projects/enclaves/ip-to-vsock-transparent_v1.0.0_linux_amd64
RUN chmod +x ip-to-vsock-transparent

# key generator to generate static keys
RUN wget -O keygen http://public.artifacts.marlin.pro/projects/enclaves/keygen_v1.0.0_linux_amd64
RUN chmod +x keygen

# attestation server inside the enclave that generates attestations
RUN wget -O attestation-server http://public.artifacts.marlin.pro/projects/enclaves/attestation-server_v1.0.0_linux_amd64
RUN chmod +x attestation-server

# proxy to expose attestation server outside the enclave
RUN wget -O vsock-to-ip http://public.artifacts.marlin.pro/projects/enclaves/vsock-to-ip_v1.0.0_linux_amd64
RUN chmod +x vsock-to-ip

# dnsproxy to provide DNS services inside the enclave
RUN wget -O dnsproxy http://public.artifacts.marlin.pro/projects/enclaves/dnsproxy_v0.46.5_linux_amd64
RUN chmod +x dnsproxy

RUN wget -O oyster-keygen http://public.artifacts.marlin.pro/projects/enclaves/oyster-keygen_0.0.1_linux_amd64
RUN chmod +x oyster-keygen

# supervisord config
COPY supervisord.conf /etc/supervisord.conf

COPY hello_world ./hello_world

# setup.sh script that will act as entrypoint
COPY setup.sh ./
RUN chmod +x setup.sh

# entry point
ENTRYPOINT [ "/app/setup.sh" ]