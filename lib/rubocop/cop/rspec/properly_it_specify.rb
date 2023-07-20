# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Check for `specify` and `it` are used properly.
      #
      # Use specify if the example doesn't have a description,
      # use it for examples with descriptions.
      #
      # @example
      #   # bad
      #   it do
      #     # ...
      #   end
      #
      #   # good
      #   specify do
      #     # ...
      #   end
      #
      #   # bad
      #   specify 'it sends an email' do
      #     # ...
      #   end
      #
      #   # good
      #   it 'sends an email' do
      #     # ...
      #   end
      #
      #   # bad
      #   specify { is_expected.to be_truthy }
      #
      #   # good
      #   it { is_expected.to be_truthy }
      #   specify { expect(sqrt(4)).to eq(2) }
      #
      class ProperlyItSpecify < Base
        extend AutoCorrector
        MSG = 'Use `%<good>s` instead of `%<bad>s`.'
        ONE_LINER_EXPECTATIONS = %w[is_expected are_expected].freeze

        # @!method includes_expectation?(node)
        def_node_search :includes_expectation?, <<~PATTERN
          (send nil? #one_liner_expectation? ...)
        PATTERN

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          return unless example?(node)

          send_node = node.send_node
          if send_node.method?(:it)
            register_offense_for_it(node, send_node)
          elsif send_node.method?(:specify)
            register_offense_for_specify(node, send_node)
          end
        end

        private

        def register_offense_for_it(node, send_node)
          selector = send_node.loc.selector
          return unless send_node.arguments.empty? && node.multiline?

          add_offense(selector,
                      message: format(MSG, good: 'specify',
                                           bad: 'it')) do |corrector|
            corrector.replace(selector, 'specify')
          end
        end

        def register_offense_for_specify(node, send_node)
          selector = send_node.loc.selector
          return unless !send_node.arguments.empty? || node.single_line?
          return if node.single_line? && !includes_expectation?(node)

          add_offense(selector,
                      message: format(MSG, good: 'it',
                                           bad: 'specify')) do |corrector|
            corrector.replace(selector, 'it')
          end
        end

        def one_liner_expectation?(node)
          ONE_LINER_EXPECTATIONS.include?(node.to_s)
        end
      end
    end
  end
end
