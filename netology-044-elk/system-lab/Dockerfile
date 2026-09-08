FROM debian:13-slim
RUN apt-get update \
    && apt-get install -y --no-install-recommends systemd python3 ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/log/journal /run/systemd/journal
WORKDIR /opt/system-lab
COPY entrypoint.sh app.py ./
RUN chmod +x /opt/system-lab/entrypoint.sh
ENTRYPOINT ["/opt/system-lab/entrypoint.sh"]
