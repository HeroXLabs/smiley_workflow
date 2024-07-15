defmodule Workflow.Action.RewardStar do
  alias Workflow.Action.Incomplete

  @enforce_keys [:reward_points]
  defstruct [:reward_points]

  @type t :: %__MODULE__{
          reward_points: non_neg_integer()
        }

  def new(value) do
    case value do
      %{"reward_points" => reward_points} ->
        {:ok,
         %__MODULE__{
           reward_points: to_integer(reward_points)
         }}

      _ ->
        {:ok, %Incomplete{action: :reward_star}}
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
          "action" => "reward_star",
          "reward_points" => struct.reward_points
        },
        opts
      )
    end
  end
end
