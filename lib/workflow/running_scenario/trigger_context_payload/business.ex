defmodule Workflow.RunningScenario.TriggerContextPayload.Business do
  alias Workflow.RunningScenario.SMSSender

  @derive Jason.Encoder
  @enforce_keys [:id, :name, :timezone, :phone_number, :sms_provider]
  defstruct [:id, :name, :timezone, :phone_number, :sms_provider]

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          timezone: String.t(),
          phone_number: String.t(),
          sms_provider: SMSSender.sms_provider()
        }
end
