defmodule Workflow.JsonUtil do
  alias Monad.Error

  def from_json_array(json_array, from_json) do
    json_array
    |> Enum.map(from_json)
    |> Error.choose()
  end
end
