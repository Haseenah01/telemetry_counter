defmodule TelemetryCounter.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    :ok = :telemetry.attach(
      # unique handler id
      "telemetry_counter-interesting_function-handler",
      [:telemetry_counter, :interesting_function],
      &TelemetryCounter.handle_event/4,
      nil
    )
    children = [
      # Start the Telemetry supervisor
      TelemetryCounterWeb.Telemetry,
      # Start the Ecto repository
      TelemetryCounter.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: TelemetryCounter.PubSub},
      # Start Finch
      {Finch, name: TelemetryCounter.Finch},
      # Start the Endpoint (http/https)
      TelemetryCounterWeb.Endpoint

      # {TelemetryCounterWeb.ReporterState,0}
      # Start a worker by calling: TelemetryCounter.Worker.start_link(arg)
      # {TelemetryCounter.Worker, arg}
    ]



    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TelemetryCounter.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TelemetryCounterWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
