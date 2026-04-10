defmodule Workflow.RunningScenario.TriggerContextPayload.FormResponseContextPayload do
  alias Workflow.RunningScenario.TriggerContextPayload.{Business, Customer}

  defmodule FormResponse do
    @derive Jason.Encoder
    @enforce_keys [:id, :token, :form_id, :title, :url, :answers, :answer_count]
    defstruct [
      :id,
      :token,
      :form_id,
      :title,
      :url,
      :answers,
      :answer_count,
      answered_field_ids: [],
      answered_field_titles: []
    ]

    @type t :: %__MODULE__{
            id: integer,
            token: String.t(),
            form_id: String.t(),
            title: String.t(),
            url: String.t(),
            answers: [map],
            answer_count: integer,
            answered_field_ids: [String.t()],
            answered_field_titles: [String.t()]
          }
  end

  @derive Jason.Encoder
  @enforce_keys [:business, :customer, :form_response]
  defstruct [:business, :customer, :form_response]

  @type t :: %__MODULE__{
          business: Business.t(),
          customer: Customer.t(),
          form_response: FormResponse.t()
        }

  defimpl Workflow.RunningScenario.ConditionsPayload, for: __MODULE__ do
    alias Workflow.Dates
    alias Workflow.RunningScenario.TriggerContextPayload.FormResponseContextPayload

    def to_conditions_payload(%FormResponseContextPayload{
          business: business,
          customer: customer,
          form_response: form_response
        }) do
      %{
        "first_name" => customer.first_name,
        "phone_number" => customer.phone_number,
        "tags" => customer.tags,
        "visits_count" => customer.visits_count,
        "last_visit_at" => Dates.to_datetime_unix_optional(customer.last_visit_at),
        "has_upcoming_appointments" => customer.has_upcoming_appointments,
        "business" => %{
          "id" => business.id,
          "name" => business.name,
          "timezone" => business.timezone
        },
        "form_response" => %{
          "id" => form_response.id,
          "token" => form_response.token,
          "form_id" => form_response.form_id,
          "title" => form_response.title,
          "url" => form_response.url,
          "answer_count" => form_response.answer_count,
          "answered_field_ids" => form_response.answered_field_ids,
          "answered_field_titles" => form_response.answered_field_titles,
          "answers" => form_response.answers
        }
      }
    end
  end
end
