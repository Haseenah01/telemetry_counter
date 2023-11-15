defmodule TelemetryCounterWeb.PlugReporter do
  use GenServer
  require Logger

  alias Telemetry.Metrics.{Counter, Distribution, LastValue, Sum, Summary}

  # def start_link(metrics: metrics) do
  #   GenServer.start_link(__MODULE__, metrics)
  # end
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts[:metrics])
  end

  def init(metrics) do
    Process.flag(:trap_exit, true)

    :ets.new(:metrix, [:named_table, :public, :set, {:write_concurrency, true}])
    groups = Enum.group_by(metrics, & &1.event_name)

    for {event, metrics} <- groups do
      id = {__MODULE__, event, self()}
      :telemetry.attach(id, event, &handle_event/4, metrics)
    end

    {:ok, Map.keys(groups)}
  end

  def handle_event(_event_name, measurements, metadata, metrics) do
    metrics
    |> Enum.map(&(handle_metric(&1, measurements, metadata)))
  end

  defp extract_measurement(metric, measurements) do
    case metric.measurement do
      fun when is_function(fun, 1) ->
        fun.(measurements)

      key ->
        measurements[key]
    end
  end

  # COUNTER
  def handle_metric(%Counter{}, _measurements, _metadata) do
    :ets.update_counter(:metrix, :counter, 1, {:counter, 0})

    Logger.info "Counter - #{inspect :ets.lookup(:metrix, :counter)}"
  end

  #LAST VALUE
  def handle_metric(%LastValue{} = metric, measurements, _metadata) do
    duration = extract_measurement(metric, measurements)
    key = :last_pageload_time

    :ets.insert(:metrix, {key, duration})

    Logger.info "LastValue - #{inspect :ets.lookup(:metrix, key)}"
  end

  #SUM
  def handle_metric(%Sum{}, _measurements, %{conn: conn} = metadata) do
    key = :bytes_transmitted

    body = IO.iodata_to_binary(conn.resp_body)

    :ets.update_counter(:metrix, key, byte_size(body), {key, 0})

    Logger.info "Sum - #{inspect :ets.lookup(:metrix, key)}"
  end

  #SUMMARY
  def handle_metric(%Summary{} = metric, measurements, _metadata) do
    duration = extract_measurement(metric, measurements)

    summary =
      case :ets.lookup(:metrix, :summary) do
        [summary: {min, max}] ->
          {
            min(min, duration),
            max(max, duration)
          }

        _ ->
          {duration, duration, 1, duration}
      end

    :ets.insert(:metrix, {:summary, summary})

    Logger.info "Summary - #{inspect summary}"
  end

  #DISTRIBUTION
  def handle_metric(%Distribution{} = metric, measurements, _metadata) do
    duration = extract_measurement(metric, measurements)

    update_distribution(metric.buckets, duration)

    Logger.info "Distribution - #{inspect :ets.match_object(:metrix, {{:distribution, :_}, :_})}"
  end


  defp update_distribution([], _duration) do
    key = {:distribution, "1000+"}
    :ets.update_counter(:metrix, key, 1, {key, 0})
  end

  defp update_distribution([head|_buckets], duration) when duration <= head do
    key = {:distribution, head}
    :ets.update_counter(:metrix, key, 1, {key, 0})
  end

  defp update_distribution([_head|buckets], duration) do
    update_distribution(buckets, duration)
  end

  def terminate(_, events) do
    events
    |> Enum.each(&(:telemetry.detach({__MODULE__, &1, self()})))

    :ok
  end

end
