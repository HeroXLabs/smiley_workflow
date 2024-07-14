defmodule Workflow.RunnableAction do
  alias Workflow.{JsonUtil, Action, Filter, Delay}

  @derive Jason.Encoder
  @enforce_keys [:filters, :delays, :inline_filters, :action]
  defstruct [:filters, :delays, :inline_filters, :action]

  @type t :: %__MODULE__{
          filters: [Filter.t()],
          delays: [Delay.t()],
          inline_filters: [Filter.t()],
          action: Action.t()
        }

  def from_json(%{
        "filters" => filters,
        "delays" => delays,
        "inline_filters" => inline_filters,
        "action" => action
      }) do
    with {:ok, filters} <- JsonUtil.from_json_array(filters, &Filter.from_json/1),
         {:ok, delays} <- JsonUtil.from_json_array(delays, &Delay.new/1),
         {:ok, inline_filters} <- JsonUtil.from_json_array(inline_filters, &Filter.from_json/1),
         {:ok, action} <- Action.from_json(action) do
      {:ok,
       %__MODULE__{
         filters: filters,
         delays: delays,
         inline_filters: inline_filters,
         action: action
       }}
    end
  end
end
