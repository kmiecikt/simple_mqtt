defmodule SimpleMqtt.MixProject do
  use Mix.Project

  def project do
    [
      app: :simple_mqtt,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      source_url: "https://github.com/kmiecikt/simple_mqtt"

    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.14", only: :dev, runtime: false}
    ]
  end

  defp description() do
    "A basic, single node pub-sub implementation where publishers and subscribers use topics and topics filters compatible with MQTT."
  end

  defp package() do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/kmiecikt/simple_mqtt"}
    ]
  end
end
