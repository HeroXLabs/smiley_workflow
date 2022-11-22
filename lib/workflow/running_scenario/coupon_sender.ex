defmodule Workflow.RunningScenario.CouponSender do
  alias Workflow.RunningScenario.ConditionsPayload

  defmodule SMSProvider do
    @type t :: :twilio | :telnyx

    def new(str) when is_binary(str) do
      String.to_atom(str)
    end
  end

  @callback send_coupon(String.t(), String.t(), String.t(), pos_integer, ConditionsPayload.t()) :: :ok
end
