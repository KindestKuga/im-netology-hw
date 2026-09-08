#!/usr/bin/env python3

import argparse
import os
import sys

import pika
import pika.exceptions

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
    parser.add_argument("--message", default="Hello Netology RabbitMQ")
    return parser.parse_args()


def main():
    args = parse_args()

    connection = open_connection(args.host, args.port)

    try:
        channel = connection.channel()

        declare_quorum_queue(channel, args.queue)
        channel.confirm_delivery()

        for number in range(1, args.count + 1):
            body = f"{args.message} #{number}"

            try:
                channel.basic_publish(
                    exchange="",
                    routing_key=args.queue,
                    body=body.encode(),
                    properties=pika.BasicProperties(
                        content_type="text/plain",
                        delivery_mode=pika.DeliveryMode.Persistent,
                    ),
                    mandatory=True,
                )
            except (
                pika.exceptions.UnroutableError,
                pika.exceptions.NackError,
            ) as exc:
                print(f"ERROR: publish failed: {exc}", file=sys.stderr)
                return 1

            print(f"published: {body}")

        return 0

    finally:
        if connection.is_open:
            connection.close()


if __name__ == "__main__":
    raise SystemExit(main())
