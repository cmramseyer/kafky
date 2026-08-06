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

Kafka es infraestructura compartida entre las aplicaciones de este entorno.
Consulta [kafky_kafka/README.md](../kafky_kafka/README.md) para levantarlo,
detenerlo e inspeccionar topics y consumer groups.

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

El evento `inventory.low_stock` se publica en:

```text
inventory.events
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

La app incluye un consumer Karafka que escucha `orders.events`, convierte el JSON a un PORO versionado y descuenta stock.

Levantar el consumer:

```bash
rvm use 3.4.3
bundle exec karafka server
```

Con Kafka levantado siguiendo las instrucciones de
[kafky_kafka/README.md](../kafky_kafka/README.md), inicia la app:

```bash
bin/rails server
```

Luego crea una orden desde la app y publica la outbox:

```bash
bin/rails outbox:publish
```

En la terminal donde corre `bundle exec karafka server` deberias ver logs similares a:

```text
Kafka orders.events message received: key="1" event_id="..." source=kafky event_version=1
OrderCreatedEvent stock decremented: event_id="..." order_id=1 product_id=1 quantity=2 stock_before=10 stock_after=8
InventoryLowStockEvent created: event_id="..." product_id=1 stock=4 reorder_threshold=5
```

El consumer usa esta capa antes de tocar modelos Active Record:

```text
JSON Kafka -> OrderCreatedEvent::Adapter -> OrderCreatedEvent::V1 -> OrderCreatedEventHandler
```

El adapter decide como construir `OrderCreatedEvent::V1` usando:

- `source`
- `event_version`

Por ahora soporta:

- `source: "kafky"`, `event_version: 1`
- `source: "manual"`, `event_version: 1`

Para productos acepta tanto `quantity` como `qty`, pero el PORO interno siempre expone `quantity`.

Si no hay stock suficiente, el consumer no bloquea el procesamiento:

- deja el stock en `0`
- loguea un warning
- continua con el siguiente producto/mensaje

Si despues de descontar stock un producto queda en o debajo de `reorder_threshold`, el handler crea un nuevo `OutboxEvent` con tipo `inventory.low_stock`.

Formato actual de `inventory.low_stock`:

```json
{
  "event_id": "uuid",
  "event_type": "inventory.low_stock",
  "event_version": 1,
  "source": "kafky",
  "occurred_at": "2026-06-09T10:00:00Z",
  "data": {
    "product": {
      "id": 1,
      "name": "Wireless Mouse",
      "stock": 4,
      "reorder_threshold": 5
    }
  }
}
```

Por ahora se crea un evento `inventory.low_stock` cada vez que el producto queda bajo el threshold. Mas adelante se agregara control de duplicados.

## Provider Orders

La app incluye `provider_orders#index` para ver ordenes de reposicion generadas desde eventos de inventario:

```text
http://localhost:3000/provider_orders
```

La tabla muestra:

- `id`
- `product`
- `quantity`

El mismo proceso `bundle exec karafka server` tambien escucha `inventory.events`. Cuando recibe un evento `inventory.low_stock`:

```text
JSON Kafka -> InventoryLowStockEvent::Adapter -> InventoryLowStockEvent::V1 -> ProviderOrderRequestHandler
```

El handler crea un `ProviderOrder` si todavia no existe uno para ese producto. Esta validacion es intencionalmente simple y no contempla concurrencia.

La cantidad solicitada al proveedor se calcula como:

```ruby
product.reorder_threshold * 2
```

Para probar el flujo completo manual:

```bash
bin/rails outbox:publish
```

La primera ejecucion publica `order.created`; el consumer puede crear un `inventory.low_stock` pendiente. Ejecuta otra vez:

```bash
bin/rails outbox:publish
```

La segunda ejecucion publica `inventory.low_stock`; el consumer de inventario crea el `ProviderOrder`.
