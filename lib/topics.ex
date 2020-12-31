defmodule SimpleMqtt.Topics do
  @type published_topic() :: [String.t()]
  @type subscribed_topic() :: [String.t()]

  @doc """
  Parses topic for published message.

  ## Examples
  iex> SimpleMqtt.Topics.parse_published_topic("things/switch_1/on")
  {:ok, ["things", "switch_1", "on"]}

  iex> SimpleMqtt.Topics.parse_published_topic("/things/switch_1/on")
  {:ok, ["", "things", "switch_1", "on"]}

  iex> SimpleMqtt.Topics.parse_published_topic("")
  :error

  iex> SimpleMqtt.Topics.parse_published_topic("/+")
  :error
  """
  @spec parse_published_topic(String.t()) :: {:ok, published_topic()} | :error
  def parse_published_topic(""), do: :error

  def parse_published_topic(topic) when is_binary(topic) do
    result = String.split(topic, "/")
    if result |> Enum.all?(&valid_published_segment?/1) do
      {:ok, result}
    else
      :error
    end
  end

  defp valid_published_segment?(segment) do
    !(String.contains?(segment, "+") || String.contains?(segment, "#"))
  end

  @doc """
  Parses filter for subscribed topics.

  ## Examples
  iex> SimpleMqtt.Topics.parse_subscribed_topic("things/switch_1/on")
  {:ok, ["things", "switch_1", "on"]}

  iex> SimpleMqtt.Topics.parse_subscribed_topic("/things/switch_1/on")
  {:ok, ["", "things", "switch_1", "on"]}

  iex> SimpleMqtt.Topics.parse_subscribed_topic("")
  :error

  iex> SimpleMqtt.Topics.parse_subscribed_topic("+")
  {:ok, ["+"]}

  iex> SimpleMqtt.Topics.parse_subscribed_topic("+/switch_1/on")
  {:ok, ["+", "switch_1", "on"]}

  iex> SimpleMqtt.Topics.parse_subscribed_topic("switch_1/+/on")
  {:ok, ["switch_1", "+", "on"]}

  iex> SimpleMqtt.Topics.parse_subscribed_topic("things/#")
  {:ok, ["things", "#"]}

  iex> SimpleMqtt.Topics.parse_subscribed_topic("#")
  {:ok, ["#"]}

  iex> SimpleMqtt.Topics.parse_subscribed_topic("#/switch_1/on")
  :error
  """
  @spec parse_subscribed_topic(String.t()) :: {:ok, subscribed_topic()} | :error
  def parse_subscribed_topic(""), do: :error
  def parse_subscribed_topic(topic) do
    result = String.split(topic, "/")
    {beginning, [last]} = Enum.split(result, Enum.count(result) - 1)
    if Enum.all?(beginning, fn s -> valid_subscribed_segment?(s, false) end) && valid_subscribed_segment?(last, true) do
      {:ok, result}
    else
      :error
    end
  end

  defp valid_subscribed_segment?("+", _), do: true
  defp valid_subscribed_segment?("#", true), do: true

  defp valid_subscribed_segment?(segment, _) do
    !(String.contains?(segment, "+") || String.contains?(segment, "#"))
  end


  @doc """
  Checks whether the published topic matches the subscribed topic.

  ## Examples
  iex> SimpleMqtt.Topics.matches?(["things", "switch_1", "on"], ["things", "switch_1", "on"])
  true

  iex> SimpleMqtt.Topics.matches?(["things", "switch_1", "on"], ["things", "switch_1", "off"])
  false

  iex> SimpleMqtt.Topics.matches?(["things", "switch_1", "on"], ["things", "+", "on"])
  true

  iex> SimpleMqtt.Topics.matches?(["things", "a", "on"], ["things", "a", "+"])
  true

  iex> SimpleMqtt.Topics.matches?(["things", "switch_1", "on"], ["things", "+", "off"])
  false

  iex> SimpleMqtt.Topics.matches?(["things", "switch_1", "on"], ["things", "switch_1", "#"])
  true

  iex> SimpleMqtt.Topics.matches?(["things", "switch_1", "on"], ["things", "#"])
  true

  iex> SimpleMqtt.Topics.matches?(["things", "switch_1", "on"], ["#"])
  true

  iex> SimpleMqtt.Topics.matches?(["things", "switch_1", "on"], ["devices", "#"])
  false
  """
  @spec matches?(published_topic(), subscribed_topic()) :: boolean()
  def matches?([], []) do
    true
  end

  def matches?([x | rest_p], [x | rest_s]) do
    matches?(rest_p, rest_s)
  end

  def matches?([_ | rest_p], ["+" | rest_s]) do
    matches?(rest_p, rest_s)
  end

  def matches?(_, ["#"]) do
    true
  end

  def matches?(_, _) do
    false
  end
end
