defmodule SimpleMqtt do
  @type package_identifier() :: 0x0001..0xFFFF | nil
  @type qos() :: 0..2
  @type topic() :: String.t()
  @type topic_filter() :: String.t()
  @type payload() :: binary() | nil

  def start_link() do
    :ok
  end

  def init(_) do
    :ok
  end

  @spec subscribe(pid(), [topic_filter()]) :: :ok
  def subscribe(_pid, _topic_filters) do
    :ok
  end

  @spec unsubscribe(pid(), [topic_filter()] | :all) :: :ok
  def unsubscribe(_pid, _topic_filters) do
    :ok
  end

  @spec publish(pid(), topic(), payload()) :: :ok | {:error, :unknown_connection}
  def publish(_pid, _topic, _payload) do
    :ok
  end
end
