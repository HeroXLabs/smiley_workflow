defmodule Workflow.Action.Incomplete do
  @enforce_keys [:action]
  defstruct [:action]

  @type action :: atom
  @type t :: %__MODULE__{action: action}
end
