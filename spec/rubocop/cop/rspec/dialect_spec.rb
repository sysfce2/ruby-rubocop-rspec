# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpec::Dialect do
  let(:cop_config) do
    {
      'PreferredMethods' => {
        'context' => 'describe'
      }
    }
  end

  it 'allows describe blocks' do
    expect_no_offenses(<<~RUBY)
      describe 'display name presence' do
      end
    RUBY
  end

  it 'allows calling methods named context in examples' do
    expect_no_offenses(<<~RUBY)
      it 'tests common context invocations' do
        expect(request.context).to be_empty?
      end
    RUBY
  end

  it 'registers an offense for context blocks' do
    expect_offense(<<~RUBY)
      context 'display name presence' do
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `describe` over `context`.
      end
    RUBY

    expect_correction(<<~RUBY)
      describe 'display name presence' do
      end
    RUBY
  end

  it 'registers an offense for RSpec.context blocks' do
    expect_offense(<<~RUBY)
      RSpec.context 'context' do
      ^^^^^^^^^^^^^^^^^^^^^^^ Prefer `describe` over `context`.
        it 'tests common context invocations' do
          expect(request.context).to be_empty?
        end
      end
    RUBY

    expect_correction(<<~RUBY)
      RSpec.describe 'context' do
        it 'tests common context invocations' do
          expect(request.context).to be_empty?
        end
      end
    RUBY
  end

  context 'without preferred methods' do
    let(:cop_config) do
      {
        'PreferredMethods' => {}
      }
    end

    it 'allows all methods blocks' do
      expect_no_offenses(<<~RUBY)
        context 'is important' do
          specify 'for someone to work' do
            everyone.should have_some_leeway
          end
        end
      RUBY
    end
  end

  context 'with error matchers config' do
    let(:cop_config) do
      {
        'PreferredMethods' => {
          'raise_exception' => 'raise_error'
        }
      }
    end

    it 'registers an offense for `raise_exception`' do
      expect_offense(<<~RUBY)
        it 'raises an error' do
          expect { subject }.to raise_exception(StandardError)
                                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `raise_error` over `raise_exception`.
        end
      RUBY

      expect_correction(<<~RUBY)
        it 'raises an error' do
          expect { subject }.to raise_error(StandardError)
        end
      RUBY
    end
  end
end
