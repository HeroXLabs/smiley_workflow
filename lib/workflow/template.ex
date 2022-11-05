defmodule Workflow.Template do
  def triggers() do
    [
      %{
        id: "step-check-in",
        title: "User checks in",
        description: "Trigger when a user checks in",
        type: "trigger",
        trigger: "check_in",
        context: %{
          "customer" => [
            %{id: "phone_number", name: "Customer phone number", category: "string"},
            %{id: "first_name", name: "Customer first name", category: "string"},
            %{id: "tags", name: "Customer tags", category: "array"},
            %{id: "visits_count", name: "Number of visits", category: "number"},
            %{id: "last_visit_at", name: "Last visit date", category: "date"}
          ],
          "check-in" => [
            %{id: "services", name: "Check-in services", category: "selection"}
          ]
        }
      },
      %{
        id: "step-cancel-appointment",
        title: "Cancel appointment",
        description: "Trigger when a user cancels an appointment",
        type: "trigger",
        trigger: "cancel_appointment",
        context: %{
          "customer" => [
            %{id: "phone_number", name: "Customer phone number", category: "string"},
            %{id: "masked_phone_number", name: "Masked customer phone number", category: "string"},
            %{id: "first_name", name: "Customer first name", category: "string"},
            %{id: "tags", name: "Customer tags", category: "array"},
            %{id: "visits_count", name: "Number of visits", category: "number"},
            %{id: "last_visit_at", name: "Last visit date", category: "date"}
          ],
          "appointment" => [
            %{id: "services", name: "Appointment services", category: "selection"},
            %{id: "employees", name: "Appointment assignees", category: "selection"}
          ],
          "employees" => [
            %{id: "phone_number", name: "Employee phone number", category: "string"},
            %{id: "first_name", name: "Employee first name", category: "string"}
          ]
        }
      }
    ]
  end

  def actions() do
    [
      %{
        id: "step-filter",
        title: "Continue only if",
        description: "Continue only if the condition is met",
        type: "action",
        action: "filter"
      },
      %{
        id: "step-delay",
        title: "Delay for",
        description: "Delay the workflow for a given amount of time",
        type: "action",
        action: "delay"
      },
      %{
        id: "step-schedule-text",
        title: "Send a text message",
        description: "Send a text message to a customer",
        type: "action",
        action: "send_sms"
      }
    ]
  end

  def conditions_map() do
    %{
      "phone_number" => "string",
      "first_name" => "string",
      "tags" => "array",
      "visits_count" => "number",
      "last_visit_at" => "date",
      "check_in.services" => "selection",
      "appointment.services" => "selection",
      "employees.phone_number" => "string",
      "employees.first_name" => "string"
    }
  end
end
