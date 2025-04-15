defmodule Workflow.RunningScenario.StampRewarder do
  alias Workflow.RunningScenario.TriggerContextPayload
  alias Workflow.Action.AddStamp

  @callback add_stamp(AddStamp.t(), TriggerContextPayload.t()) :: :ok
end
