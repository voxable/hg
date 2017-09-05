require 'dry-validation'
class Buttons
  schema = Dry::Validation.schema do
    required(:buttons).filled.each.value(type?: Button)
    required(:text).filled(:str?).value(max_size?: 640)


    end
end