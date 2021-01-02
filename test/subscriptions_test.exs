defmodule SimpleMqtt.SubscriptionsTest do
  use ExUnit.Case
  alias SimpleMqtt.Subscriptions
  doctest SimpleMqtt.Subscriptions

  test "Subscribe adds new item" do
    subscriptions = Subscriptions.new()
    subscriptions = Subscriptions.subscribe(subscriptions, :c.pid(0, 1, 0), ["things/a/+", "things/b/+"])
    subscriptions = Subscriptions.subscribe(subscriptions, :c.pid(0, 2, 0), ["things/a/+"])
    subscriptions = Subscriptions.subscribe(subscriptions, :c.pid(0, 2, 0), ["things/c/+"])

    assert Subscriptions.list_matched(subscriptions, "things/a/on") == [:c.pid(0, 1, 0), :c.pid(0, 2, 0)]
    assert Subscriptions.list_matched(subscriptions, "things/b/on") == [:c.pid(0, 1, 0)]
    assert Subscriptions.list_matched(subscriptions, "things/c/on") == [:c.pid(0, 2, 0)]
  end

  test "Unsubscribe removes items" do
    subscriptions = Subscriptions.new()
    subscriptions = Subscriptions.subscribe(subscriptions, :c.pid(0, 1, 0), ["things/a/+", "things/b/+"])
    {:not_empty, subscriptions} = Subscriptions.unsubscribe(subscriptions, :c.pid(0, 1, 0), ["things/a/+"])

    assert Subscriptions.list_matched(subscriptions, "things/b/on") == [:c.pid(0, 1, 0)]
    assert Subscriptions.list_matched(subscriptions, "things/a/on") == []

    assert {:empty, _} = Subscriptions.unsubscribe(subscriptions, :c.pid(0, 1, 0), ["things/b/+"])
  end

  test "Unsubscribe :all removes items" do
    subscriptions = Subscriptions.new()
    subscriptions = Subscriptions.subscribe(subscriptions, :c.pid(0, 1, 0), ["things/a/+", "things/b/+"])
    {:empty, subscriptions} = Subscriptions.unsubscribe(subscriptions, :c.pid(0, 1, 0), :all)

    assert Subscriptions.list_matched(subscriptions, "things/b/on") == []
    assert Subscriptions.list_matched(subscriptions, "things/a/on") == []
  end
end
