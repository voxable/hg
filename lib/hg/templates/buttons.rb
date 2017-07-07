

# facebook messenger button template
# see https://developers.facebook.com/docs/messenger-platform/send-api-reference/templates
class Buttons < Template

  attribute :template_type, Types::Strict::String('button')
  attribute :text, Types::Strict::String.constrained(max_size: 640)
  attribute :sharable, Types::Boolean.optional
  # button template can only contain call, log in/out, payload and url buttons
  # template must have at least one and no more than three buttons
  attribute :buttons, Types::Strict::Array
    .member(
      Button::Call ||
          Button::LogIn || Button::LogOut || Button::Payload || Button::Url
    )
    .constrained(size: 1..3)
end

