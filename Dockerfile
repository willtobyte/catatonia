FROM ubuntu

ENV DEBIAN_FRONTEND=noninteractive

ENV PATH="/root/.cargo/bin:${PATH}"

RUN <<EOF
apt update
apt install --yes --no-install-recommends build-essential pkg-config git ca-certificates luajit libluajit-5.1-dev curl ffmpeg npm

curl -sSf https://sh.rustup.rs | sh -s -- -y
  . "$HOME/.cargo/env"

rustup set profile minimal
rustup default stable

cargo install oxipng --locked --root /usr/local
cargo install stylua --features luajit --locked --root /usr/local

npm install --location=global prettier
EOF

WORKDIR /opt
COPY main.sh .
RUN chmod +x main.sh

WORKDIR /data

CMD ["/opt/main.sh"]
