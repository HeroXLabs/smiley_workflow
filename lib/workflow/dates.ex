defmodule Workflow.Dates do
  import Calendar.Date, only: [from_erl: 1, to_erl: 1, from_erl!: 1, subtract!: 2, diff: 2]

  @type timezone :: String.t()
  @type time_erl :: {non_neg_integer, non_neg_integer, non_neg_integer}

  def today_local(timezone) do
    Calendar.Date.today!(timezone)
  end

  @spec n_days_since(Integer.t(), timezone) :: Date.t()
  def n_days_since(num, timezone) do
    timezone
    |> Calendar.Date.today!()
    |> Calendar.Date.add!(num)
  end

  @spec n_days_ago(Integer.t(), timezone) :: Date.t()
  def n_days_ago(num, timezone) do
    timezone
    |> Calendar.Date.today!()
    |> Calendar.Date.subtract!(num)
  end

  @doc ~S"""
  Returns the start of day date time given a date and timezone.
  """
  @spec to_datetime(Date.t(), timezone) :: DateTime.t()
  def to_datetime(%Date{day: d, month: m, year: y}, timezone) do
    {{y, m, d}, {0, 0, 0}}
    |> Calendar.DateTime.from_erl!(timezone, 0)
  end

  def to_datetime_utc(%Date{} = date, timezone) do
    to_datetime(date, timezone)
    |> Calendar.DateTime.shift_zone!("Etc/UTC")
  end

  @doc ~S"""
  Returns some date time given a date, time erl format, and timezone.
  """
  @spec to_datetime_utc(Date.t(), time_erl, binary) :: DateTime.t()
  def to_datetime_utc(%Date{day: d, month: m, year: y}, {_, _, _} = time_erl, timezone) do
    {{y, m, d}, time_erl}
    |> Calendar.DateTime.from_erl!(timezone, 0)
    |> shift_utc!()
  end

  def to_datetime_with_time(%Date{day: d, month: m, year: y}, {hr, min, sec}, timezone) do
    {{y, m, d}, {hr, min, sec}}
    |> Calendar.DateTime.from_erl!(timezone)
  end

  def to_datetime_with_time_utc(%Date{} = date, time, timezone) do
    to_datetime_with_time(date, time, timezone)
    |> Calendar.DateTime.shift_zone!("Etc/UTC")
  end

  @doc ~S"""
  Returns the start of day date time given a date and timezone.
  """
  def to_start_day_datetime(%Date{day: d, month: m, year: y}, timezone) do
    {{y, m, d}, {0, 0, 0}}
    |> Calendar.DateTime.from_erl!(timezone)
  end

  def to_start_day_datetime_utc(%Date{} = date, timezone) do
    to_start_day_datetime(date, timezone)
    |> Calendar.DateTime.shift_zone!("Etc/UTC")
  end

  @doc ~S"""
  Returns the end of day date time given a date and timezone.
  """
  def to_end_day_datetime(%Date{day: d, month: m, year: y}, timezone) do
    {{y, m, d}, {23, 59, 59}}
    |> Calendar.DateTime.from_erl!(timezone)
  end

  def to_end_day_datetime_utc(%Date{} = date, timezone) do
    to_end_day_datetime(date, timezone)
    |> Calendar.DateTime.shift_zone!("Etc/UTC")
  end

  @spec start_end_datetimes_of_day(Date.t(), timezone) :: {:ok, {DateTime.t(), DateTime.t()}}
  def start_end_datetimes_of_day(date, timezone) do
    date_erl = Calendar.Date.to_erl(date)

    {:ok,
     {Calendar.DateTime.from_erl!({date_erl, {0, 0, 0}}, timezone),
      Calendar.DateTime.from_erl!({date_erl, {23, 59, 59}}, timezone)}}
  end

  @spec start_end_datetimes_of_day_unix(Date.t(), timezone) :: {:ok, {pos_integer, pos_integer}}
  def start_end_datetimes_of_day_unix(%Date{} = date, timezone) do
    with {:ok, {s, e}} <- start_end_datetimes_of_day(date, timezone) do
      {:ok, {DateTime.to_unix(shift_utc!(s)), DateTime.to_unix(shift_utc!(e))}}
    end
  end

  def to_datetime_unix_optional(%DateTime{} = dt) do
    DateTime.to_unix(dt)
  end

  def to_datetime_unix_optional(_), do: nil

  def within_dates?(date, start_date, end_date) do
    diff(date, start_date) >= 0 &&
      diff(date, end_date) <= 0
  end

  @doc ~S"""
  Returns the year months of a given period

  ## Examples

      iex> Workflow.Dates.year_months(~D[2016-12-25], ~D[2017-03-01])
      ["2016-12", "2017-01", "2017-02", "2017-03"]
  """
  def year_months(start_date, end_date) do
    dates_within_span(start_date, end_date)
    |> Enum.map(&year_month/1)
    |> Enum.uniq()
  end

  @doc ~S"""
  Returns the year month of a given date

  ## Examples

      iex> Workflow.Dates.year_month(~D[2016-12-25])
      "2016-12"
      iex> Workflow.Dates.year_month(~D[2016-01-05])
      "2016-01"
  """
  def year_month(date) do
    {y, m, _} = Calendar.Date.to_erl(date)

    [
      y,
      m
      |> Integer.to_string()
      |> String.pad_leading(2, "0")
    ]
    |> Enum.join("-")
  end

  @doc ~S"""
  Returns all dates within a span

  ## Examples

      iex> Workflow.Dates.dates_within_span(~D[2016-12-25], ~D[2017-01-05])
      [~D[2016-12-25], ~D[2016-12-26], ~D[2016-12-27], ~D[2016-12-28],
       ~D[2016-12-29], ~D[2016-12-30], ~D[2016-12-31], ~D[2017-01-01],
       ~D[2017-01-02], ~D[2017-01-03], ~D[2017-01-04], ~D[2017-01-05]]
  """
  @spec dates_within_span(Date.t(), Date.t()) :: [Date.t()]
  def dates_within_span(start_date, end_date) do
    if start_date |> Calendar.Date.after?(end_date) do
      raise ArgumentError, message: "start date after end date"
    else
      do_dates_within_span(start_date, end_date, [start_date])
    end
  end

  defp do_dates_within_span(current_date, end_date, dates) do
    next_day = current_date |> Calendar.Date.add!(1)

    if next_day |> Calendar.Date.after?(end_date) do
      dates
    else
      do_dates_within_span(next_day, end_date, dates ++ [next_day])
    end
  end

  @doc ~S"""
  Convert a string to a `Date`.

  ## Examples

      iex> Workflow.Dates.date_from_string("2016-12-12")
      {:ok, ~D[2016-12-12]}
  """
  @spec date_from_string(binary) :: {:ok, Date.t()} | {:error, binary}
  def date_from_string(str) when is_binary(str) do
    try do
      [y, m, d] = str |> String.split("-") |> Enum.map(&String.to_integer/1)
      {y, m, d} |> from_erl
    rescue
      _ ->
        {:error, "invalid input. Expected format: 2016-12-12"}
    end
  end

  def date_from_string(_), do: {:error, "invalid input. Expected a String"}

  @doc ~S"""
  Return the start and end dates of last n days.

  ## Examples

      iex> Workflow.Dates.start_and_end_of_last_n_days(~D[2016-12-12], 4)
      {~D[2016-12-08], ~D[2016-12-11]}
  """
  @spec start_and_end_of_last_n_days(Date.t(), integer) :: {Date.t(), Date.t()}
  def start_and_end_of_last_n_days(date, n) do
    {subtract!(date, n), subtract!(date, 1)}
  end

  @doc ~S"""
  Return the start and end dates of last n months.

  ## Examples

      iex> Workflow.Dates.start_and_end_of_last_n_months(~D[2016-12-12], 3)
      {~D[2016-09-01], ~D[2016-11-30]}
      iex> Workflow.Dates.start_and_end_of_last_n_months(~D[2017-02-01], 1)
      {~D[2017-01-01], ~D[2017-01-31]}
  """
  @spec start_and_end_of_last_n_months(Date.t(), integer) :: {Date.t(), Date.t()}
  def start_and_end_of_last_n_months(date, n) do
    {y, m, _} = date |> to_erl
    first_day_of_month = {y, m, 1}
    last_day_of_previous_month = first_day_of_month |> subtract!(1) |> to_erl

    first_day_of_previous_n_month =
      1..n
      |> Enum.reduce(first_day_of_month, fn _, first_day_of_month ->
        last_day_of_previous_month = first_day_of_month |> subtract!(1) |> to_erl
        {y, m, _} = last_day_of_previous_month
        {y, m, 1}
      end)

    {:ok, s} = from_erl(first_day_of_previous_n_month)
    {:ok, e} = from_erl(last_day_of_previous_month)

    {s, e}
  end

  @spec get_first_day_of_month(Date.t()) :: Date.t()
  def get_first_day_of_month(date) do
    {y, m, _} = date |> to_erl
    {y, m, 1} |> from_erl!
  end

  defp shift_utc!(datetime) do
    Calendar.DateTime.shift_zone!(datetime, "Etc/UTC")
  end
end
