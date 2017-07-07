require 'types'

# facebook messenger template
# see https://developers.facebook.com/docs/messenger-platform/send-api-reference/templates
class Template < Dry::Struct

  attribute :template_type, Types::Strict::String.enum(
    'airline_boardingpass',
    'airline_checkin',
    'airline_itinerary',
    'airline_update',
    'button',
    'generic',
    'list',
    'open_graph',
    'receipt'
  )

end

