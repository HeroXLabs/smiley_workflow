defmodule Workflow.Action.OutgoingWebhook do
  alias Workflow.Action.Incomplete

  @enforce_keys [:url, :body]
  defstruct [:url, :body, headers: %{}]
  @type t :: %__MODULE__{url: binary, body: binary, headers: map}

  def new(value) do
    case value do
      %{"url" => url, "body" => body} when is_binary(url) and is_binary(body) ->
        {:ok, %__MODULE__{url: url, body: body, headers: Map.get(value, "headers", %{})}}

      _ ->
        {:ok, %Incomplete{action: :outgoing_webhook}}
    end
  end

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(struct, opts) do
      Jason.Encode.map(
        %{
          "action" => "outgoing_webhook",
          "url" => struct.url,
          "body" => struct.body,
          "headers" => struct.headers
        },
        opts
      )
    end
  end
end
