defmodule Workflow.RunningScenario.CouponSender do
  alias Workflow.RunningScenario.ConditionsPayload
  alias Workflow.Action.SendCoupon

  defmodule SMSProvider do
    @type t :: :twilio | :telnyx

    def new(str) when is_binary(str) do
      String.to_atom(str)
    end
  end

  @type coupon_description :: String.t() | nil
  @type coupon_image_url :: String.t() | nil

  @callback send_coupon(SendCoupon.t(), ConditionsPayload.t()) :: :ok
end
