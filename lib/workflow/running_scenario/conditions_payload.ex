defprotocol Workflow.RunningScenario.ConditionsPayload do
  alias Workflow.RunningScenario.TriggerContextPayload

  @spec to_conditions_payload(TriggerContextPayload.t()) :: map
  def to_conditions_payload(any)
end
