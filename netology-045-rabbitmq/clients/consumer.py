#!/usr/bin/env python3

import argparse
import os

from common import declare_quorum_queue, open_connection


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default=os.getenv("RABBITMQ_HOST", "127.0.0.1"))
    parser.add_argument(
        "--port",
        type=int,
        default=int(os.getenv("RABBITMQ_PORT", "5671")),
    )
    parser.add_argument("--queue", default="hello")
    parser.add_argument("--count", type=int, default=1)
    return parser.parse_args()


def main():
    args = parse_args()

    connection = open_connection(args.host, args.port)
    channel = connection.channel()

    declare_quorum_queue(channel, args.queue)
    channel.basic_qos(prefetch_count=1)

    received = 0

    def on_message(ch, method, properties, body):
        nonlocal received

        text = body.decode(errors="replace")

        print(
            f"received: {text} "
            f"redelivered={method.redelivered}"
        )

        ch.basic_ack(delivery_tag=method.delivery_tag)

        received += 1

        if received >= args.count:
            ch.stop_consuming()

    channel.basic_consume(
        queue=args.queue,
        on_message_callback=on_message,
        auto_ack=False,
    )

    try:
        print(
            f"waiting: queue={args.queue} "
            f"host={args.host}:{args.port}"
        )
        channel.start_consuming()
    finally:
        if connection.is_open:
            connection.close()


if __name__ == "__main__":
    main()
