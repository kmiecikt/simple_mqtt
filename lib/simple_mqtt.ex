defmodule SimpleMqtt do
  alias SimpleMqtt.Subscriptions

  use GenServer

  @type package_identifier() :: 0x0001..0xFFFF | nil
  @type qos() :: 0..2
  @type topic() :: String.t()
  @type topic_filter() :: String.t()
  @type payload() :: binary() | nil

  def start_link() do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(_) do
    {:ok, Subscriptions.new()}
  end

  @spec subscribe(pid(), [topic_filter()]) :: :ok
  def subscribe(pid, topics) do
    GenServer.call(pid, {:subscribe, topics})
  end

  @spec unsubscribe(pid(), [topic_filter()] | :all) :: :ok
  def unsubscribe(pid, topics) do
    GenServer.call(pid, {:unsubscribe, topics})
  end

  @spec publish(pid(), topic(), payload()) :: :ok | {:error, :unknown_connection}
  def publish(pid, topic, payload) do
    GenServer.cast(pid, {:publish, topic, payload})
  end

  def handle_call({:subscribe, topics}, {from, _}, subscriptions) do
    case Subscriptions.subscribe(subscriptions, from, topics) do
      :error -> {:reply, :error, subscriptions}
      new_subscriptions -> {:reply, :ok, new_subscriptions}
    end
  end

  def handle_call({:unsubscribe, topics}, {from, _}, subscriptions) do
    case Subscriptions.unsubscribe(subscriptions, from, topics) do
      :error -> {:reply, :error, subscriptions}
      {:empty, new_subscriptions} -> {:reply, :ok, new_subscriptions}
      {:not_empty, new_subscriptions} -> {:reply, :ok, new_subscriptions}
    end
  end

  def handle_cast({:publish, topic, payload}, subscriptions) do
    case Subscriptions.list_matched(subscriptions, topic) do
      :error -> {:noreply, subscriptions}
      pids ->
        for pid <- pids do
          send(pid, {:simple_mqtt, topic, payload})
        end
        {:noreply, subscriptions}
    end
  end
end
