defmodule Workflow.Action.SendSms do
  alias Workflow.Action.Incomplete

  @enforce_keys [:phone_number, :text]
  defstruct [:phone_number, :text]
  @type t :: %__MODULE__{phone_number: binary, text: binary}

  def new(value) do
    case value do
      %{"phone_number" => phone_number, "text" => text} ->
        {:ok, %__MODULE__{phone_number: phone_number, text: text}}

      _ ->
        {:ok, %Incomplete{action: :send_sms}}
    end
  end

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(struct, opts) do
      Jason.Encode.map(
        %{
          "action" => "send_sms",
          "phone_number" => struct.phone_number,
          "text" => struct.text
        },
        opts
      )
    end
  end
end
