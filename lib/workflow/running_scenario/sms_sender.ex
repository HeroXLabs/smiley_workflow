defmodule Workflow.RunningScenario.SMSSender do
  alias Workflow.RunningScenario.TriggerContextPayload

  defmodule SMSProvider do
    @type t :: :twilio | :telnyx

    def new(str) when is_binary(str) do
      String.to_atom(str)
    end
  end

  @callback send_sms(String.t(), String.t(), TriggerContextPayload.t()) :: :ok
end
