defmodule Workflow.RunningScenario.IdGen do
  @callback generate() :: String.t()
end
