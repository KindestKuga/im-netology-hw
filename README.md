# im-netology-hw

Здесь собираю практические работы по системному администрированию, Linux, инфраструктуре и DevOps из курса Нетологии.

В каждой папке — отдельная работа: краткое описание задачи, решение, конфигурации, скрипты и документация.

## Работы

| Работа | Тема | Что реализовано |
|---|---|---|
| [netology-032-yandex-cloud](netology-032-yandex-cloud/README.md) | Terraform, Yandex Cloud, Ansible | облачная инфраструктура с public/private subnet, NAT Gateway, bastion/ProxyJump, отдельными web- и PostgreSQL-узлами и автоматической настройкой через Ansible |
| [netology-033-gitlab](netology-033-gitlab/README.md) | GitLab CI, GitLab Runner, Docker | локальный GitLab Runner с Docker executor и CI pipeline для Go: тестирование, сборка бинарника и Docker image |
| [netology-036-zabbix](netology-036-zabbix/README.md) | Zabbix, Terraform, Ansible | автоматизированное развёртывание Zabbix Server и Agent 2, пользовательские метрики через UserParameter, discovery и dashboard |
| [netology-039-clustering-load-balancing](netology-039-clustering-load-balancing/README.md) | HAProxy, Nginx, балансировка нагрузки | L4/L7-балансировка через HAProxy, Round Robin и Weighted Round Robin, маршрутизация по Host и связка Nginx → HAProxy → backend-серверы |
| [netology-041-cloud-fault-tolerance](netology-041-cloud-fault-tolerance/README.md) | Yandex Cloud, отказоустойчивость, Network Load Balancer | отказоустойчивый HTTP-сервис за Yandex Network Load Balancer: две VM, Target Group и вариант с Compute Instance Group и автоматическим развёртыванием Nginx |
| [netology-044-elk](netology-044-elk/README.md) | ELK, Filebeat, Elastic Agent | несколько вариантов доставки и разбора логов в Elasticsearch, поиск в Kibana, сбор journald и Prometheus-метрик |
| [netology-045-rabbitmq](netology-045-rabbitmq/README.md) | RabbitMQ, Ansible, отказоустойчивость | кластер RabbitMQ из трёх нод с quorum queue, TLS, автоматической настройкой и проверкой переключения при отказе лидера |

## Как читать

Откройте `README.md` конкретной работы по ссылке из таблицы: там собраны основные шаги, команды проверки и ссылки на дополнительные файлы.
