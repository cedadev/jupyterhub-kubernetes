FROM fedora:25

RUN dnf install -y nfs-ganesha nfs-ganesha-vfs

RUN mkdir -p /exports
VOLUME /exports

EXPOSE 2049/tcp 20048/tcp 111/tcp 111/udp

COPY ganesha.conf /etc/ganesha/ganesha.conf

ENTRYPOINT ["ganesha.nfsd", "-F", "-L", "/var/log/ganesha.log", "-f", "/etc/ganesha/ganesha.conf"]
