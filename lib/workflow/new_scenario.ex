defmodule Workflow.NewScenario do
  alias Workflow.NewTrigger

  defstruct [:workspace_id, :title, :trigger]
  @type t :: %__MODULE__{workspace_id: binary, title: binary, trigger: NewTrigger.t()}
end
