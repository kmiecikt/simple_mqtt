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

  test "Simple MQTT does not link to subscribers" do
    {:ok, pid} = SimpleMqtt.start_link()
    subscriber_pid = spawn(fn ->
        :ok = SimpleMqtt.subscribe(pid, ["things/a/+"])
        receive do
           _ -> nil
        end
      end)

    Process.sleep(10)
    Process.exit(subscriber_pid, :kill)
    Process.sleep(10)

    assert Process.alive?(subscriber_pid) == false
    assert Process.alive?(pid) == true
  end
end
