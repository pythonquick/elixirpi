defmodule Elixirpi.Worker do
  alias Elixirpi.Collector
  alias Decimal, as: D

  # Commonly used formula constants:
  @d1 D.new(1)
  @d2 D.new(2)
  @d4 D.new(4)
  @d5 D.new(5)
  @d6 D.new(6)
  @d8 D.new(8)
  @d16 D.new(16)

  def run() do
    precision = Collector.precision
    keep_processing_digits(precision)
  end

  defp calc_sixteen_power(0, _) do
    @d1
  end

  defp calc_sixteen_power(exp, exponent_cache) do
    {cache_exp, cache_sixteen_power} = exponent_cache
    Enum.reduce(cache_exp+1..exp, cache_sixteen_power, fn(_, acc) -> D.mult(acc, @d16) end)
  end

  defp term(digit_position, sixteen_power) do
    digit_position_decimal = D.new(digit_position)
    eight_times_digit_pos = D.mult(@d8, digit_position_decimal)
    D.div(@d4, eight_times_digit_pos |> D.add(@d1))
      |> D.sub(D.div(@d2, eight_times_digit_pos |> D.add(@d4)))
      |> D.sub(D.div(@d1, eight_times_digit_pos |> D.add(@d5)))
      |> D.sub(D.div(@d1, eight_times_digit_pos |> D.add(@d6)))
      |> D.div(sixteen_power)
  end

  defp process_next_digits(precision) do
    D.set_context(%D.Context{D.get_context | precision: precision})
    {next_digit_positions, exponent_cache} = Collector.next_digits

    calc_digit_positions(next_digit_positions, precision, exponent_cache)
    |> Enum.each(fn {:ok, {digit_position, next_term, exponent_cache}} ->
      Collector.update_pi(digit_position, next_term, exponent_cache)
      IO.write('.')
    end)

    next_digit_positions
  end

  defp calc_digit_positions(digit_positions, precision, exponent_cache) do
    # Following calculates digits in streams of parallel running tasks
    Task.async_stream(digit_positions, fn digit_position ->
      calc_digit_position(digit_position, precision, exponent_cache)
    end, timeout: 100000)

    # In contrast, the following calculates digit positions sequentially. Slow!
    #Enum.map(digit_positions, fn digit_position -> 
    #  {:ok, calc_digit_position(digit_position, precision, exponent_cache)}
    #end)
  end

  defp calc_digit_position(digit_position, precision, exponent_cache) do
      D.set_context(%D.Context{D.get_context | precision: precision})
      power_of_sixteen = calc_sixteen_power(digit_position, exponent_cache)
      {digit_position, term(digit_position, power_of_sixteen), {digit_position, power_of_sixteen}}
  end

  defp keep_processing_digits(precision) do
    next_digit_positions = process_next_digits(precision)
    case next_digit_positions do
      [] -> IO.puts "Worker finished"
      _ -> keep_processing_digits(precision)
    end
  end
end
