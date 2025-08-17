FROM ubuntu

RUN <<EOF
apt update

apt install --yes cargo ffmpeg npm
cargo install --locked oxipng --root /usr/local
cargo install stylua --features luajit --root /usr/local
npm install --location=global prettier
EOF

WORKDIR /opt
COPY main.sh .
RUN chmod +x main.sh

WORKDIR /data

CMD ["/opt/main.sh"]
