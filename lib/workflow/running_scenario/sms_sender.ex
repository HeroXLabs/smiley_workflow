defmodule Workflow.RunningScenario.SMSSender do
  @callback send_sms(String.t(), String.t(), String.t()) :: :ok
end
