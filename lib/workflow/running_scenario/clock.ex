defmodule Workflow.RunningScenario.Clock do
  @type timezone :: term

  @callback today!(timezone) :: Date.t()
end
