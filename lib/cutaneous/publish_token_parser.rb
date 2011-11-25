module Cutaneous
  PublishTokenParser ||= Cutaneous::TokenParser.generate({
    :comment => %w(!{ }),
    :expression => %w(${ }),
    :escaped_expression => %w($${ }),
    :statement => %w(%{ })
  })
end # Cutaneous
