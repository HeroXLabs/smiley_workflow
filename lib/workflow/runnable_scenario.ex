defmodule Workflow.RunnableScenario do
  alias Workflow.{RunnableAction, Trigger}

  defstruct [:id, :workspace_id, :title, :trigger, :actions]

  @type t :: %__MODULE__{
          id: binary,
          workspace_id: binary,
          title: binary,
          trigger: Trigger.t(),
          actions: [RunnableAction.t()]
        }
end
