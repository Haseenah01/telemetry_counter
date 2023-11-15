defmodule TelemetryCounter do
  def interesting_function do
   :telemetry.execute([:telemetry_counter, :interesting_function], %{count: 1})
  #  TelemetryCounterWeb.Telemetry.metrics
    # :telemetry.attach("telemetry_counter-interesting_function-handler",[:telemetry_counter, :interesting_function], &TelemetryCounter.handle_event/4, %{})
  end
  def hold_value(value) do
    :telemetry.execute([:telemetry_counter, :hold_value], %{value: value})
  end

  def handle_event([:telemetry_counter, :interesting_function], measurements, _, _state) do
    IO.puts("############################")
    IO.inspect(measurements.count)
  end


end
