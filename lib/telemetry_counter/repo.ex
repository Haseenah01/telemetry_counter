defmodule TelemetryCounter.Repo do
  use Ecto.Repo,
    otp_app: :telemetry_counter,
    adapter: Ecto.Adapters.Postgres
end
