# SimpleMqtt
A basic, single node pub-sub implementation where publishers and subscribers use topics and topics filters compatible with MQTT.

It cannot replace a real MQTT broker, but can be used in a simple IoT device, with multiple local sensors and actuators that have to communicate with each other.

## Installation
If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `simple_mqtt` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:simple_mqtt, "~> 0.1.0"}
  ]
end
```

## Usage
In the following example, the current process:
- Starts a `SimpleMqtt` server.
- Subscribes to two topic filters.
- Publishes a message that matches one of the filters.
- Receives notification.
- Unsubscribes from the server.
```
iex> {:ok, pid} = SimpleMqtt.start_link()
{:ok, #PID<0.201.0>}

iex> :ok = SimpleMqtt.subscribe(pid, ["things/sensor_1/+", "things/sensor_2/+"])
:ok

iex> :ok = SimpleMqtt.publish(pid, "things/sensor_1/on", "true")
:ok

iex> flush
{:simple_mqtt, "things/sensor_1/on", "true"}

iex> :ok = SimpleMqtt.unsubscribe(pid, :all)
:ok
```

## API documentation
The [ExDoc](https://github.com/elixir-lang/ex_doc) documentation can be found at [https://hexdocs.pm/simple_mqtt](https://hexdocs.pm/simple_mqtt).

