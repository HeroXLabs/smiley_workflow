defmodule Workflow.Interpolation do
  alias Workflow.Template

  def interpolate(string, timezone, bindings \\ %{}) do
    ~r/(?<head>){{[^}]+}}(?<tail>)/
    |> Regex.split(string, on: [:head, :tail])
    |> Enum.reduce("", fn
      <<"{{" <> rest>>, acc ->
        key = String.trim_trailing(rest, "}")
        keys = String.split(key, ".")
        value = get_in(bindings, keys)
        output = 
          case Template.conditions_mapping(key) do
            :date -> 
              human_readable_format(value, timezone)
            _ ->
              value
          end
        acc <> to_string(output)
      segment, acc ->
        acc <> segment
    end)
  end

  defp human_readable_format(date_time, timezone) do
    date_time
    |> Calendar.DateTime.shift_zone!(timezone)
    |> Calendar.ContainsDateTime.dt_struct()
    |> Calendar.Strftime.strftime!("%I:%M %p %A, %d %b %Y")
  end
end

