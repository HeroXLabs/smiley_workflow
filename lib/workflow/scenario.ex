defmodule Workflow.Scenario do
  alias Workflow.{Step, Trigger}

  @enforce_keys [:id, :workspace_id, :enabled, :title, :trigger_id, :ordered_action_ids, :steps]
  defstruct [:id, :workspace_id, :enabled, :title, :trigger_id, :ordered_action_ids, :steps]

  @type id :: binary

  @type t :: %__MODULE__{
          id: id,
          workspace_id: binary,
          enabled: boolean,
          title: binary,
          trigger_id: Trigger.TriggerType.t(),
          ordered_action_ids: [Step.id()],
          steps: [Step.t()]
        }
end
