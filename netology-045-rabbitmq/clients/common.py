import os
import ssl
from pathlib import Path

import pika


DEFAULT_CA_FILE = (
    Path(__file__).resolve().parents[1]
    / "ansible"
    / "pki"
    / "ca.crt.pem"
)


def open_connection(host: str, port: int) -> pika.BlockingConnection:
    credentials = pika.PlainCredentials(
        os.environ["RABBITMQ_USER"],
        os.environ["RABBITMQ_PASSWORD"],
    )

    ca_file = os.getenv("RABBITMQ_CA_FILE", str(DEFAULT_CA_FILE))

    ssl_context = ssl.create_default_context(cafile=ca_file)
    ssl_context.minimum_version = ssl.TLSVersion.TLSv1_2

    parameters = pika.ConnectionParameters(
        host=host,
        port=port,
        virtual_host=os.getenv("RABBITMQ_VHOST", "/netology"),
        credentials=credentials,
        ssl_options=pika.SSLOptions(ssl_context, host),
        heartbeat=30,
        blocked_connection_timeout=30,
        connection_attempts=3,
        retry_delay=2,
    )

    return pika.BlockingConnection(parameters)


def declare_quorum_queue(channel, queue: str) -> None:
    channel.queue_declare(
        queue=queue,
        durable=True,
        exclusive=False,
        auto_delete=False,
        arguments={
            "x-queue-type": "quorum",
        },
    )
