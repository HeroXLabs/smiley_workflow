defmodule Workflow.RunningScenario.SMSSender do
  alias Workflow.RunningScenario.ConditionsPayload

  defmodule SMSProvider do
    @type t :: :twilio | :telnyx

    def new(str) when is_binary(str) do
      String.to_atom(str)
    end
  end

  @callback send_sms(String.t(), String.t(), ConditionsPayload.t()) :: :ok
end
