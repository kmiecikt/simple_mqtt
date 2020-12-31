defmodule SimpleMqttTest do
  use ExUnit.Case
  doctest SimpleMqtt

  test "Current process receives subscribed notifications" do
    {:ok, pid} = SimpleMqtt.start_link()
    :ok = SimpleMqtt.subscribe(pid, ["things/a/+"])
    :ok = SimpleMqtt.publish(pid, "things/a/on", "True")
    assert_receive({:simple_mqtt, "things/a/on", "True"})
  end

  test "Current process doesn't receives notifications after unsubscribing" do
    {:ok, pid} = SimpleMqtt.start_link()
    :ok = SimpleMqtt.subscribe(pid, ["things/a/+"])
    :ok = SimpleMqtt.unsubscribe(pid, :all)
    :ok = SimpleMqtt.publish(pid, "things/a/on", "True")
    refute_receive({:simple_mqtt, "things/a/on", }, 10)
  end

  test "Simple MQTT unregisters crashed procsses" do
    assert False == True
  end
end
