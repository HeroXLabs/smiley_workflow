defmodule Workflow.RunningScenario.InlineAction do
  alias Workflow.JsonUtil
  alias Workflow.{Action, Filter}

  @derive Jason.Encoder
  @enforce_keys [:filters, :action]
  defstruct [:filters, :action]

  @type t :: %__MODULE__{
          filters: [Filter.t()],
          action: Action.t()
        }

  def from_json(%{"filters" => filters_json, "action" => action_json}) do
    with {:ok, filters} <- JsonUtil.from_json_array(filters_json, &Filter.from_json/1),
         {:ok, action} <- Action.from_json(action_json) do
      {:ok, %__MODULE__{filters: filters, action: action}}
    end
  end
end
