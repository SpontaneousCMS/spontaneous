require 'set'

module MiniTest
  module Assertions
    def assert_has_elements(exp, act, msg = nil)
      msg = message(msg) { "Expected #{act} to have same elements as #{exp}" }
      assert Set.new(exp) == Set.new(act)
    end
  end
end

Object.infect_an_assertion :assert_has_elements, :must_have_elements
