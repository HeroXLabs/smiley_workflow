defmodule Workflow.RunningScenario.Scheduler do
  alias Workflow.RunningScenario.ScenarioRun

  @type seconds :: non_neg_integer
  @type clock :: module

  # Computes the delay for a job, based on the delay type and the delay value.
  # Calls run_action on the scenario run with the delay.
  @callback schedule(ScenarioRun.t(), seconds, clock) :: :ok
end
