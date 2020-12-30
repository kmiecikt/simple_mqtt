defmodule SimpleMqttTest do
  use ExUnit.Case
  doctest SimpleMqtt

  test "greets the world" do
    assert SimpleMqtt.hello() == :world
  end
end
