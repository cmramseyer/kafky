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
        { "sku": "MOUSE-WL-001", "quantity": 2 }
      ]
    }
  }
}
```

## Procesar Ordenes En Inventario

`kafky` solo crea y publica `order.created`; no consume `orders.events` ni
descuenta stock. `kafky_storage` consume ese topic, valida disponibilidad,
descuenta su inventario y publica `inventory.stock_updated`.

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

La emision de `inventory.low_stock` se movera a `kafky_storage` en una etapa
posterior. Mientras tanto, esta app conserva el consumer de `inventory.events`
para el flujo existente de ordenes a proveedor.
