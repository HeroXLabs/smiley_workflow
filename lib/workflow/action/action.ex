defmodule Workflow.Action do
  alias __MODULE__.{Incomplete, SendCoupon, SendSms, RewardStar}

  @type t :: SendSms.t() | SendCoupon.t() | RewardStar.t() | Incomplete.t()

  def from_json(%{"action" => action} = json) do
    new(action, json)
  end

  def new("send_sms", value) do
    SendSms.new(value)
  end

  def new("send_coupon", value) do
    SendCoupon.new(value)
  end

  def new("reward_star", value) do
    RewardStar.new(value)
  end

  def new(action, _value) do
    {:error, "Invalid action: #{action}"}
  end
end
