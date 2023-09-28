defmodule Workflow.Interpolation do
  alias Workflow.Template

  def interpolate(string, timezone, bindings \\ %{}) do
    ~r/(?<head>){{[^}]+}}(?<tail>)/
    |> Regex.split(string, on: [:head, :tail])
    |> Enum.reduce("", fn
      <<"{{" <> rest>>, acc ->
        key = String.trim_trailing(rest, "}")
        [first_key | rest ] = String.split(key, ".")
        first_key = String.split(first_key, ":") |> List.last()
        keys = [first_key] ++ rest
        value = get_in(bindings, keys)
        key = Enum.join(keys, ".")
        output = 
          case Template.conditions_mapping(key) do
            :date -> 
              case List.last(keys) do
                "expire_date" -> human_readable_format_in_date(value, timezone)
                _ -> human_readable_format_in_date_time(value, timezone)
              end
            :string ->
              case key do
                "first_name" -> value || "there"
                _ -> value
              end
            _ ->
              value
          end
        acc <> to_string(output)
      segment, acc ->
        acc <> segment
    end)
  end

  defp human_readable_format_in_date_time(date_time, timezone) do
    date_time
    |> Calendar.DateTime.shift_zone!(timezone)
    |> Calendar.ContainsDateTime.dt_struct()
    |> Calendar.Strftime.strftime!("%I:%M %p %A, %d %b %Y")
  end

  defp human_readable_format_in_date(date_time, timezone) do
    date_time
    |> Calendar.DateTime.shift_zone!(timezone)
    |> Calendar.DateTime.to_date()
  end
end

