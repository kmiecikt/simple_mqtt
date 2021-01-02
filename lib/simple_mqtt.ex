defmodule SimpleMqtt do
  alias SimpleMqtt.Subscriptions
  use GenServer
  require Logger

  @type package_identifier() :: 0x0001..0xFFFF | nil
  @type topic() :: String.t()
  @type topic_filter() :: String.t()
  @type payload() :: binary() | nil

  @moduledoc """
  The SimpleMqtt is a basic, single node pub-sub implementation where publishers and subscribers use topics and topics filters
  compatible with MQTT.

  It cannot replace a real MQTT broker, but can be used in a simple IoT device, with multiple local sensors and actuators that have to communicate with each other.
  """

  @doc """
  Starts new Simple MQTT server and links it to the current process
  """
  def start_link() do
    GenServer.start_link(__MODULE__, nil)
  end

  @doc """
  Subscribes the current process to the given list of topics. Each item in the list must be a valid MQTT filter.

  ## Examples

  In the following example, the current process subscribes to two topic filters:
    {:ok, pid} = SimpleMqtt.start_link()
    :ok = SimpleMqtt.subscribe(pid, ["things/sensor_1/+", "things/sensor_2/+"])

  If the process needs to monitor one more topic filter, it can call `subscribe` again. After this call, the current process
  will be subscribed to three topic filters.

    :ok = SimpleMqtt.subscribe(pid, ["things/sensor_3/+"])

  """
  @spec subscribe(pid(), [topic_filter()]) :: :ok
  def subscribe(pid, topics) do
    Logger.debug("Subscribed process #{inspect(pid)} to topics #{inspect(topics)}")
    GenServer.call(pid, {:subscribe, topics})
  end

  @doc """
  Unsubscribes the current process from the given list of topics.

  ## Examples

  In the following example, the current process starts the Simple MQTT server, subscribes to two topic filters,
  and then unsubscribes from the second one. It will still receive messages published to a topic that matches the first
  filter.

    {:ok, pid} = SimpleMqtt.start_link()
    :ok = SimpleMqtt.subscribe(pid, ["things/sensor_1/+", "things/sensor_2/+"])
    :ok = SimpleMqtt.unsubscribe(pid, ["things/sensor_2/+"])

  In the second example, the current process unsubscribes from all topics. It will no longer receive any messages.

    {:ok, pid} = SimpleMqtt.start_link()
    :ok = SimpleMqtt.subscribe(pid, ["things/sensor_1/+", "things/sensor_2/+"])
    :ok = SimpleMqtt.unsubscribe(pid, :all)
  """
  @spec unsubscribe(pid(), [topic_filter()] | :all) :: :ok
  def unsubscribe(pid, topics) do
    Logger.debug("Unsubscribed process #{inspect(pid)} from topics #{inspect(topics)}")
    GenServer.call(pid, {:unsubscribe, topics})
  end

  @doc """
  Publishes message to the given topic.

  ## Examples

    {:ok, pid} = SimpleMqtt.start_link()
    :ok = SimpleMqtt.publish(pid, "things/sensor_1/temperature", "34.5")
  """
  @spec publish(pid(), topic(), payload()) :: :ok
  def publish(pid, topic, payload) do
    Logger.info("Publishing message to topic #{topic}")
    GenServer.cast(pid, {:publish, topic, payload})
  end

  @impl true
  def init(_) do
    {:ok, {Subscriptions.new(), %{}}}
  end

  @impl true
  def handle_call({:subscribe, topics}, {from, _}, {subscriptions, monitors}) do
    case Subscriptions.subscribe(subscriptions, from, topics) do
      :error -> {:reply, :error, subscriptions}
      new_subscriptions ->
        reference = Process.monitor(from)
        new_monitors = Map.put(monitors, from, reference)
        {:reply, :ok, {new_subscriptions, new_monitors}}
    end
  end

  @impl true
  def handle_call({:unsubscribe, topics}, {from, _}, {subscriptions, monitors} = state) do
    case Subscriptions.unsubscribe(subscriptions, from, topics) do
      :error -> {:reply, :error, state}
      {:empty, new_subscriptions} ->
        new_monitors = case Map.fetch(monitors, from) do
          {:ok, monitor_ref} ->
            Process.demonitor(monitor_ref)
            Map.delete(monitors, from)
          _ -> monitors
        end
        {:reply, :ok, {new_subscriptions, new_monitors}}
      {:not_empty, new_subscriptions} ->
        {:reply, :ok, {new_subscriptions, monitors}}
    end
  end

  @impl true
  def handle_cast({:publish, topic, payload}, {subscriptions, _} = state) do
    case Subscriptions.list_matched(subscriptions, topic) do
      :error -> {:noreply, state}
      pids ->
        for pid <- pids do
          Logger.debug("Sending message published to topic #{topic} to subscriber #{inspect(pid)}")
          send(pid, {:simple_mqtt, topic, payload})
        end
        {:noreply, state}
    end
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, {subscriptions, monitors}) do
    Logger.info("Subscriber #{inspect(pid)} exited. Removing its subscriptions")
    new_monitors = Map.delete(monitors, pid)

    case Subscriptions.unsubscribe(subscriptions, pid, :all) do
      :error -> {:noreply, {subscriptions, new_monitors}}
      {_, new_subscriptions} -> {:noreply, {new_subscriptions, new_monitors}}
    end
  end
end
