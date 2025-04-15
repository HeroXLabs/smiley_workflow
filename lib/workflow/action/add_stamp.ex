defmodule Workflow.Action.AddStamp do
  alias Workflow.Action.Incomplete

  @enforce_keys [:stamp_count]
  defstruct [:stamp_count]

  @type t :: %__MODULE__{
          stamp_count: non_neg_integer()
        }

  def new(value) do
    case value do
      %{"stamp_count" => stamp_count} ->
        {:ok,
         %__MODULE__{
           stamp_count: to_integer(stamp_count)
         }}

      _ ->
        {:ok, %Incomplete{action: :add_stamp}}
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
          "action" => "add_stamp",
          "stamp_count" => struct.stamp_count
        },
        opts
      )
    end
  end
end
