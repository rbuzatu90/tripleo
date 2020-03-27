podman run --privileged --name bind -p 10.0.1.2:53:53/udp -p 10.0.1.2:53:53/tcp  --volume /root/container-volume/dns/:/data docker.io/sameersbn/bind
