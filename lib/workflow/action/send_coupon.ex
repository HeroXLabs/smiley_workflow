defmodule Workflow.Action.SendCoupon do
  alias Workflow.Action.Incomplete

  @enforce_keys [
    :phone_number,
    :text,
    :new_customer_only,
    :coupon_title,
    :coupon_description,
    :coupon_image_url,
    :coupon_redeemable_count,
    :coupon_expires_in_days
  ]
  defstruct [
    :phone_number,
    :text,
    :new_customer_only,
    :coupon_title,
    :coupon_description,
    :coupon_image_url,
    :coupon_redeemable_count,
    :coupon_expires_in_days
  ]

  @type t :: %__MODULE__{
          phone_number: binary,
          text: binary,
          new_customer_only: boolean,
          coupon_title: binary,
          coupon_expires_in_days: pos_integer,
          coupon_description: binary | nil,
          coupon_redeemable_count: pos_integer,
          coupon_image_url: binary | nil
        }

  def new(value) do
    case value do
      %{
        "phone_number" => phone_number,
        "text" => text,
        "coupon_title" => coupon_title,
        "coupon_expires_in_days" => coupon_expires_in_days
      } ->
        {:ok,
         %__MODULE__{
           phone_number: phone_number,
           text: text,
           coupon_title: coupon_title,
           coupon_expires_in_days: to_integer(coupon_expires_in_days),
           new_customer_only: Map.get(value, "new_customer_only", false),
           coupon_description: Map.get(value, "coupon_description"),
           coupon_image_url: Map.get(value, "coupon_image_url"),
           coupon_redeemable_count: Map.get(value, "coupon_redeemable_count", 1) |> to_integer()
         }}

      _ ->
        {:ok, %Incomplete{action: :send_coupon}}
    end
  end

  defp to_integer(value) when is_integer(value) do
    value
  end

  defp to_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {value, ""} -> value
      _ -> nil
    end
  end

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(struct, opts) do
      Jason.Encode.map(
        %{
          "action" => "send_coupon",
          "phone_number" => struct.phone_number,
          "text" => struct.text,
          "coupon_title" => struct.coupon_title,
          "coupon_expires_in_days" => struct.coupon_expires_in_days,
          "coupon_description" => struct.coupon_description,
          "new_customer_only" => struct.new_customer_only,
          "coupon_redeemable_count" => struct.coupon_redeemable_count,
          "coupon_image_url" => struct.coupon_image_url
        },
        opts
      )
    end
  end
end
