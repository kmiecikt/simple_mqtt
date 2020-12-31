defmodule SimpleMqtt.Subscriptions do
  alias SimpleMqtt.Topics

  @moduledoc """
  Represents collection of subscribed topics for multiple processes.
  """

  @type subscriptions :: %{}

  @doc """
  Creates new subscriptions collection.
  """
  @spec new() :: subscriptions()
  def new() do
    Map.new()
  end

  @doc """
  Adds a new subscription to the collection. If the same pid was already registered, the topics will be merged.
  """
  @spec subscribe(subscriptions(), pid(), [String.t()]) :: :error | subscriptions()
  def subscribe(subscriptions, pid, topics) do
    with {:ok, parsed_topics} <- parse_subscribed_topics(topics)
    do
      new_set = MapSet.new(parsed_topics)
      Map.update(subscriptions, pid, new_set, fn existing_set -> MapSet.union(existing_set, new_set) end)
    else
      :error -> :error
    end
  end

  @doc """
  Removes topics from the subscription.
  """
  @spec unsubscribe(subscriptions(), pid(), [String.t()]) :: :error | {:empty, subscriptions()} | {:not_empty, subscriptions()}
  def unsubscribe(subscriptions, pid, :all) do
    {:empty, Map.delete(subscriptions, pid)}
  end

  def unsubscribe(subscriptions, pid, topics) do
    with {:ok, parsed_topics} <- parse_subscribed_topics(topics),
         {:ok, existing_topics} <- Map.fetch(subscriptions, pid)
    do
      {_, updated} = parsed_topics|> Enum.map_reduce(existing_topics, fn item, acc ->
          {item, MapSet.delete(acc, item)}
        end)

      case Enum.count(updated) do
        0 -> {:empty, Map.delete(subscriptions, pid)}
        _ -> {:not_empty, Map.put(subscriptions, pid, updated)}
      end
    else
      :error -> :error
    end
  end

  @spec list_matched(subscriptions(), String.t) :: :error | [pid()]
  @doc """
  Returns pids for all processes that subscribed to topics that match the given published topic.
  """
  def list_matched(subscriptions, topic) do
    case Topics.parse_published_topic(topic) do
      {:ok, published_topic} ->
        subscriptions
        |> Stream.flat_map(fn {pid, subscribed_topics} -> Enum.map(subscribed_topics, fn t-> {pid, t} end) end)
        |> Stream.filter(fn {_, t} -> Topics.matches?(published_topic, t) end)
        |> Stream.map(fn {pid, _} -> pid end)
        |> Enum.uniq()
      :error -> :error
    end
  end

  defp parse_subscribed_topics(topics, result \\ [])

  defp parse_subscribed_topics([], result), do: {:ok, result}

  defp parse_subscribed_topics([first | rest], result) do
    case Topics.parse_subscribed_topic(first) do
      {:ok, parsed_topic} -> parse_subscribed_topics(rest, [parsed_topic | result])
      :error -> :error
    end
  end
end
