defmodule Workflow.RunningScenario.CouponSender do
  alias Workflow.RunningScenario.ConditionsPayload

  defmodule SMSProvider do
    @type t :: :twilio | :telnyx

    def new(str) when is_binary(str) do
      String.to_atom(str)
    end
  end

  @type coupon_description :: String.t() | nil
  @type coupon_image_url :: String.t() | nil

  @callback send_coupon(String.t(), String.t(), String.t(), coupon_description, coupon_image_url, pos_integer, ConditionsPayload.t()) :: :ok
end
