# Kafky

Aplicacion Rails para practicar sistemas dirigidos por eventos con Kafka.

## Requisitos

- Ruby 3.4.3
- Docker y Docker Compose

Antes de ejecutar comandos Rails:

```bash
rvm use 3.4.3
```

## Setup Rails

```bash
bundle install
bin/rails db:migrate
bin/rails db:seed
```

Levantar la app:

```bash
bin/rails server
```

Abrir la app en:

```text
http://localhost:3000
```

## Kafka Local

El proyecto incluye `docker-compose.yml` con:

- Kafka en `localhost:9092`
- Kafka UI en `http://localhost:8080`
- Imagen Kafka: `apache/kafka:4.2.1`

Levantar Kafka y Kafka UI:

```bash
docker compose up -d
```

Si necesitas descargar las imagenes antes de levantar los servicios:

```bash
docker compose pull
```

Ver logs internos del broker Kafka:

```bash
docker compose logs -f kafka
```

Ver logs de Kafka UI:

```bash
docker compose logs -f kafka-ui
```

Ver logs de todos los servicios:

```bash
docker compose logs -f
```

Ver estado de los contenedores:

```bash
docker compose ps
```

Bajar los servicios:

```bash
docker compose down
```

Bajar los servicios y borrar volumenes asociados:

```bash
docker compose down -v
```

## Inspeccionar Kafka

Los logs del contenedor muestran actividad interna del broker, arranque, errores y conexiones. Para ver eventos publicados en un topic, usa las herramientas CLI dentro del contenedor Kafka.

Entrar al contenedor Kafka:

```bash
docker compose exec kafka bash
```

Listar topics desde dentro del contenedor:

```bash
/opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:29092 --list
```

Consumir mensajes de `orders.events` desde el inicio:

```bash
/opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server kafka:29092 --topic orders.events --from-beginning
```

Consumir solo mensajes nuevos de `orders.events`:

```bash
/opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server kafka:29092 --topic orders.events
```

Describir un topic:

```bash
/opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:29092 --describe --topic orders.events
```

Ver consumer groups:

```bash
/opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server kafka:29092 --list
```

Describir un consumer group:

```bash
/opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server kafka:29092 --describe --group NOMBRE_DEL_GROUP
```

Publicar un mensaje de prueba manualmente:

```bash
/opt/kafka/bin/kafka-console-producer.sh --bootstrap-server kafka:29092 --topic orders.events
```

Luego escribe un JSON y presiona Enter:

```json
{"event_id":"manual-test-1","event_type":"order.created","event_version":1,"source":"manual","occurred_at":"2026-06-09T10:00:00Z","data":{"order":{"id":1,"customer_id":1,"products":[{"id":1,"quantity":1}]}}}
```

Para salir del producer o consumer, presiona `Ctrl+C`.

## Topics Recomendados

Para los siguientes pasos del aprendizaje:

```text
orders.events
inventory.events
purchase_orders.events
orders.events.dlq
inventory.events.dlq
```

Por ahora la app guarda eventos `order.created` en la tabla `outbox_events`. El siguiente paso es publicar esos eventos en Kafka.

## Publicar Outbox En Kafka

La app usa Karafka para publicar eventos pendientes de `outbox_events` hacia Kafka.

Por defecto Rails publica contra:

```text
localhost:9092
```

Puedes cambiarlo con:

```bash
KAFKA_BOOTSTRAP_SERVERS=localhost:9092 bin/rails outbox:publish
```

Publicar eventos pendientes:

```bash
bin/rails outbox:publish
```

Flujo actual:

- `orders#create` crea la orden.
- En la misma transaccion crea un evento `order.created` en `outbox_events`.
- `bin/rails outbox:publish` publica eventos pendientes en Kafka.
- Si Kafka confirma el envio, el evento se marca con `published_at`.
- Si falla el envio, el evento queda pendiente para reintentar.

El evento `order.created` se publica en:

```text
orders.events
```

Formato actual del mensaje:

```json
{
  "event_id": "uuid",
  "event_type": "order.created",
  "event_version": 1,
  "source": "kafky",
  "occurred_at": "2026-06-09T10:00:00Z",
  "data": {
    "order": {
      "id": 1,
      "customer_id": 1,
      "products": [
        { "id": 1, "quantity": 2 }
      ]
    }
  }
}
```

## Consumir Eventos De Orders

La app incluye un consumer Karafka que escucha `orders.events` y loguea los mensajes recibidos.

Levantar el consumer:

```bash
rvm use 3.4.3
bundle exec karafka server
```

Flujo manual para probarlo:

```bash
docker compose up -d
bin/rails server
```

Luego crea una orden desde la app y publica la outbox:

```bash
bin/rails outbox:publish
```

En la terminal donde corre `bundle exec karafka server` deberias ver un log similar a:

```text
Kafka orders.events message received: key="1" payload={...}
```
