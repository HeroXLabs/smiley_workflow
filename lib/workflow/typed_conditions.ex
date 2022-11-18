defmodule Workflow.TypedConditions do
  alias Workflow.Dates

  @type operator :: Op.t

  @type field_type :: :string
                    | :number
                    | :date
                    | :boolean
                    | :selection
  @type field_name :: String.t
  @type field :: {field_type, field_name}

  @type field_value :: String.t
                     | number
                     | Date.t
                     | nil

  @type op_name :: String.t
  @type op_category :: :string
                     | :number
                     | :ago
                     | :date
                     | :boolean
                     | :selection
  @type op :: {op_name, op_category}

  @type compare :: op | {op, field_value}

  @type condition_str :: String.t
                       | nil

  @type condition :: {field, compare}
                   | :empty

  @type condition_chain :: {:or, condition, condition_chain}
                         | {:and, condition, condition_chain}
                         | condition

  @type t :: condition_chain

  @type field_type_mapper :: (field_name -> field_type)

  @op_mappings %{
    string: %{
      "=" => {:equal, :string},
      "!=" => {:not_equal, :string},
      "}" => {:contain, :string},
      "!}" => {:not_contain, :string},
      "!!" => {:is_present, :string},
      "!" => {:is_blank, :string}
    },
    boolean: %{
      "!" => {:not_equal, :boolean},
      "!!" => {:equal, :boolean}
    },
    date: %{
      "!" => {:is_blank, :date},
      "!!" => {:is_present, :date},
      "=" => {:equal, :date},
      ">" => {:after, :date},
      "<" => {:before, :date},
      ">>" => {:after, :ago},
      "<<" => {:before, :ago},
      "==" => {:equal, :ago}
    },
    number: %{
      "=" => {:equal, :number},
      "!=" => {:not_equal, :number},
      ">" => {:greater_than, :number},
      "<" => {:less_than, :number},
      ">=" => {:greater_than_or_equal, :number},
      "<=" => {:less_than_or_equal, :number}
    },
    selection: %{
      "=" => {:equal, :string},
      "!=" => {:not_equal, :string},
      "}" => {:equal, :string},
      "!}" => {:not_equal, :string}
    }
  }

  @spec run_conditions(condition_chain, map, any, any) :: boolean
  def run_conditions(condition_chain, payload, timezone, date) do
    do_run_conditions(condition_chain, payload, timezone, date)
  end

  defp do_run_conditions({:and, condition, condition_chain}, payload, timezone, date) do
    run_condition(condition, payload, timezone, date) && do_run_conditions(condition_chain, payload, timezone, date)
  end

  defp do_run_conditions({:or, condition, condition_chain}, payload, timezone, date) do
    run_condition(condition, payload, timezone, date) || do_run_conditions(condition_chain, payload, timezone, date)
  end

  defp do_run_conditions(:empty, _payload, _timezone, _date) do
    false
  end

  defp do_run_conditions(condition, payload, timezone, date) do
    run_condition(condition, payload, timezone, date)
  end

  @spec run_condition(condition, map, any, any) :: boolean
  def run_condition(
    {{:selection, key}, {{op_name, _}, value}},
    %{} = payload,
    _,
    _
  ) do
    items =
      payload
      |> get_in([key])
      |> List.wrap()
      |> Enum.map(&to_string/1)
      |> Enum.map(&String.downcase/1)

    item = value |> String.trim() |> String.downcase()
    is_member = Enum.member?(items, item)

    case op_name do
      :equal -> is_member
      :not_equal -> not(is_member)
    end
  end

  def run_condition(
    {{_field_type, field_name}, compare_op},
    payload,
    timezone,
    date
  ) do
    raw_value = get_in(payload, String.split(field_name, "."))
    case {raw_value, compare_op} do
      {_, {:is_present, _}} ->
        !is_blank?(raw_value)
      {_, {:is_blank, _}} ->
        is_blank?(raw_value)
      {nil, _} ->
        false
      {_, compare_op} ->
        case compare_op do
          {{op_name, :boolean}, bool} ->
            compare_bool(op_name, bool, raw_value)
          {{op_name, :date}, %Date{} = date} ->
            compare_date(op_name, raw_value, timezone, date)
          {{op_name, :ago}, n_days} ->
            date = Calendar.Date.subtract!(date, n_days)
            op_name =
              case op_name do
                :before -> :after
                :after -> :before
                other -> other
              end
            compare_date(op_name, raw_value, timezone, date)
          {{op_name, :number}, op_value} ->
            compare_number(op_name, op_value, raw_value)
          {{op_name, :string}, op_value} ->
            compare_string(op_name, op_value, raw_value)
        end
    end
  end

  @doc """
  Parses conditions in string given the type of field.
  to_datetime_utc converts a Date to a DateTime given a default timezone.
  """
  @spec parse_conditions(String.t, field_type_mapper) :: {:ok, condition_chain} | {:error, any}
  def parse_conditions("", _field_type_mapper, _) do
    {:ok, :empty}
  end

  def parse_conditions(conditions_str, field_type_mapper) when is_binary(conditions_str) do
    conditions_str
    |> String.split(~r{\&|\|}, include_captures: true)
    |> extract_conditions(field_type_mapper)
  end

  def parse_conditions(_conditions_str, _field_type_mapper) do
    {:error, "non string condition str"}
  end

  @spec parse_condition(String.t, field_type_mapper) :: {:ok, condition} | {:error, any}
  def parse_condition(condition_str, field_type_mapper) do
    case String.split(condition_str, ":") do
      [field_name | rest] ->
        field_type = field_type_mapper.(field_name)
        case {field_type, rest} do
          {field_type, [op, value]} when field_type in [:string, :date, :number, :selection] ->
            with {:ok, {op_name, op_category}} <- with_op_mapping(field_type, op),
                 {:ok, value} <- convert_value(op_category, value) do
              {:ok, {{field_type, field_name}, {{op_name, op_category}, value}}}
            end
          {field_type, [op]} when field_type in [:string, :date] ->
            with {:ok, {op_name, op_category}} <- with_op_mapping(field_type, op) do
              case op_name do
                op_name when op_name in [:is_present, :is_blank] ->
                  {:ok, {{field_type, field_name}, {op_name, op_category}}}
                _ ->
                  {:error, :failed_to_find_op_mappings}
              end
            end
          {:boolean, [op]} ->
            with {:ok, {op_name, op_category}} <- with_op_mapping(:boolean, op) do
              {:ok, {{field_type, field_name}, {{op_name, op_category}, true}}}
            end
          _ -> {:ok, :empty}
        end
      _ ->
        {:error, :failed_to_parse_conditions}
    end
  end

  defp with_op_mapping(field_type, op) do
    case get_in(@op_mappings, [field_type, op]) do
      nil -> {:error, :failed_to_find_op_mappings}
      {_, _} = result -> {:ok, result}
    end
  end

  defp convert_value(:string, value), do: {:ok, String.trim(value)}
  defp convert_value(:date, value), do: Dates.date_from_string(value)
  defp convert_value(:number, value), do: parse_integer(value)
  defp convert_value(:ago, value), do: parse_integer(value)

  defp extract_conditions([condition_str, op | rest], field_type_mapper) do
    chain_op = case op do
      "&" -> :and
      "|" -> :or
    end

    with {:ok, condition} <- parse_condition(condition_str, field_type_mapper),
      {:ok, condition_rest} <- extract_conditions(rest, field_type_mapper) do
      {:ok, {chain_op, condition, condition_rest}}
    end
  end

  defp extract_conditions([string], field_type_mapper) do
    extract_conditions(string, field_type_mapper)
  end

  defp extract_conditions(condition_str, field_type_mapper) when is_binary(condition_str) do
    parse_condition(condition_str, field_type_mapper)
  end

  ## Helpers

  defp compare_string(op_name, op_value, raw_value) when is_binary(raw_value) do
    value = String.trim(raw_value)
    case op_name do
      :equal -> equal_string?(value, op_value)
      :not_equal -> !equal_string?(value, op_value)
      :contain -> contains?(value, op_value)
      :not_contain -> !contains?(value, op_value)
    end
  end

  defp compare_string(_op_name, _op_value, _raw_value), do: false

  defp compare_date(op_name, raw_value, timezone, date) do
    with {:ok, {s, e}} <- Dates.start_end_datetimes_of_day_unix(date, timezone),
         {:ok, v} <- parse_integer(raw_value) do
      case op_name do
        :equal -> v >= s && v <= e
        :after -> v > e
        :before -> v < s
      end
    else
      _ -> false
    end
  end

  defp compare_number(op_name, op_value, raw_value) do
    with {:ok, v} <- parse_integer(raw_value) do
      case op_name do
        :less_than -> v < op_value
        :less_than_or_equal -> v <= op_value
        :greater_than -> v > op_value
        :greater_than_or_equal -> v >= op_value
        :equal -> v == op_value
        :not_equal -> v != op_value
      end
    else
      _ -> false
    end
  end

  defp compare_bool(:equal, true, true), do: true
  defp compare_bool(:equal, false, false), do: true
  defp compare_bool(:not_equal, true, false), do: true
  defp compare_bool(:not_equal, false, true), do: true
  defp compare_bool(_, _, _), do: false

  def parse_integer(value) when is_number(value) do
    {:ok, round(value)}
  end

  def parse_integer(value) when is_binary(value) do
    try do
      {:ok, String.to_integer(value)}
    rescue
      _ -> {:error, :error_parsing_integer}
    end
  end

  defp is_blank?(nil), do: true
  defp is_blank?(""), do: true
  defp is_blank?(_), do: false

  defp equal_string?(a, b) do
    String.downcase(a) == String.downcase(b)
  end

  defp contains?(a, b) do
    String.contains?(String.downcase(a), String.downcase(b))
  end
end
