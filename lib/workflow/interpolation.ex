defmodule Workflow.Interpolation do
  def interpolate(string, bindings \\ %{}) do
    ~r/(?<head>){{[^}]+}}(?<tail>)/
    |> Regex.split(string, on: [:head, :tail])
    |> Enum.reduce("", fn
      <<"{{" <> rest>>, acc ->
        key = String.trim_trailing(rest, "}")
        keys = String.split(key, ".")
        output = get_in(bindings, keys)
        acc <> to_string(output)
      segment, acc ->
        acc <> segment
    end)
  end
end

