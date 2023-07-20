# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpec::ProperlyItSpecify, :config do
  it 'registers an offense when using `it` without description' do
    expect_offense(<<~RUBY)
      it do
      ^^ Use `specify` instead of `it`.
        # ...
      end
    RUBY

    expect_correction(<<~RUBY)
      specify do
        # ...
      end
    RUBY
  end

  it 'registers an offense when using `specify` with description' do
    expect_offense(<<~RUBY)
      specify 'it sends an email' do
      ^^^^^^^ Use `it` instead of `specify`.
        # ...
      end
    RUBY

    expect_correction(<<~RUBY)
      it 'it sends an email' do
        # ...
      end
    RUBY
  end

  it 'registers an offense when using `specify` and one-liner style' do
    expect_offense(<<~RUBY)
      specify { is_expected.to be_truthy }
      ^^^^^^^ Use `it` instead of `specify`.
      specify { are_expected.to be_falsy }
      ^^^^^^^ Use `it` instead of `specify`.
    RUBY

    expect_correction(<<~RUBY)
      it { is_expected.to be_truthy }
      it { are_expected.to be_falsy }
    RUBY
  end

  it 'does not register an offense when using `specify` ' \
     'and not one-liner style' do
    expect_no_offenses(<<~RUBY)
      specify { expect(sqrt(4)).to eq(2) }
    RUBY
  end

  it 'does not register an offense when using `specify` without description' do
    expect_no_offenses(<<~RUBY)
      specify do
        # ...
      end
    RUBY
  end

  it 'does not register an offense when using `it` with description' do
    expect_no_offenses(<<~RUBY)
      it 'sends an email' do
        # ...
      end
    RUBY
  end

  it 'does not register an offense when using `it` and one-liner style' do
    expect_no_offenses(<<~RUBY)
      it { is_expected.to be_truthy }
    RUBY
  end
end
