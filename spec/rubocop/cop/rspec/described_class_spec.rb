# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpec::DescribedClass do
  let(:cop_config) { {} }

  context 'when SkipBlocks is `true`' do
    let(:cop_config) { { 'SkipBlocks' => true } }

    it 'ignores offenses within non-rspec blocks' do
      expect_offense(<<~RUBY)
        describe MyClass do
          controller(ApplicationController) do
            self.bar = MyClass
          end

          before do
            MyClass
            ^^^^^^^ Use `described_class` instead of `MyClass`.

            Foo.custom_block do
              MyClass
            end
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        describe MyClass do
          controller(ApplicationController) do
            self.bar = MyClass
          end

          before do
            described_class

            Foo.custom_block do
              MyClass
            end
          end
        end
      RUBY
    end

    it 'ignores offenses within non-rspec numblocks' do
      expect_offense(<<~RUBY)
        describe MyClass do
          controller(ApplicationController) do
            do_some_work(_1)
            self.bar = MyClass
          end

          before do
            MyClass
            ^^^^^^^ Use `described_class` instead of `MyClass`.

            Foo.custom_block do
              do_some_work(_1)
              MyClass
            end
          end
        end
      RUBY
    end
  end

  context 'when SkipBlocks is `false`' do
    it 'flags offenses within all blocks' do
      expect_offense(<<~RUBY)
        describe MyClass do
          controller(ApplicationController) do
            bar = MyClass
                  ^^^^^^^ Use `described_class` instead of `MyClass`.
          end

          before do
            MyClass
            ^^^^^^^ Use `described_class` instead of `MyClass`.

            Foo.custom_block do
              MyClass
              ^^^^^^^ Use `described_class` instead of `MyClass`.
            end
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        describe MyClass do
          controller(ApplicationController) do
            bar = described_class
          end

          before do
            described_class

            Foo.custom_block do
              described_class
            end
          end
        end
      RUBY
    end
  end

  context 'when EnforcedStyle is :described_class' do
    let(:cop_config) { { 'EnforcedStyle' => :described_class } }

    it 'flags for the use of the described class' do
      expect_offense(<<~RUBY)
        describe MyClass do
          include MyClass
                  ^^^^^^^ Use `described_class` instead of `MyClass`.

          subject { MyClass.do_something }
                    ^^^^^^^ Use `described_class` instead of `MyClass`.

          before { MyClass.do_something }
                   ^^^^^^^ Use `described_class` instead of `MyClass`.
        end
      RUBY

      expect_correction(<<~RUBY)
        describe MyClass do
          include described_class

          subject { described_class.do_something }

          before { described_class.do_something }
        end
      RUBY
    end

    it 'allows accessing constants from variables when in a nested namespace' do
      expect_no_offenses(<<~RUBY)
        module Foo
          describe MyClass do
            let(:foo) { SomeClass }
            let(:baz) { foo::CONST }
          end
        end
      RUBY
    end

    it 'flags with metadata' do
      expect_offense(<<~RUBY)
        describe MyClass, some: :metadata do
          subject { MyClass }
                    ^^^^^^^ Use `described_class` instead of `MyClass`.
        end
      RUBY

      expect_correction(<<~RUBY)
        describe MyClass, some: :metadata do
          subject { described_class }
        end
      RUBY
    end

    it 'ignores described class as string' do
      expect_no_offenses(<<~RUBY)
        describe MyClass do
          subject { "MyClass" }
        end
      RUBY
    end

    it 'ignores describe that do not reference to a class' do
      expect_no_offenses(<<~RUBY)
        describe "MyClass" do
          subject { "MyClass" }
        end
      RUBY
    end

    it 'ignores class if the scope is changing' do
      expect_no_offenses(<<~RUBY)
        describe MyClass do
          Class.new  { foo = MyClass }
          Module.new { bar = MyClass }
          Struct.new { lol = MyClass }
          Data.define { dat = MyClass }

          def method
            include MyClass
          end

          class OtherClass
            include MyClass
          end

          module MyModule
            include MyClass
          end
        end
      RUBY
    end

    it 'takes class from innermost describe' do
      expect_offense(<<~RUBY)
        describe MyClass do
          describe MyClass::Foo do
            subject { MyClass::Foo }
                      ^^^^^^^^^^^^ Use `described_class` instead of `MyClass::Foo`.

            let(:foo) { MyClass }
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        describe MyClass do
          describe MyClass::Foo do
            subject { described_class }

            let(:foo) { MyClass }
          end
        end
      RUBY
    end

    it 'ignores non-matching namespace defined on `describe` level' do
      expect_no_offenses(<<~RUBY)
        describe MyNamespace::MyClass do
          subject { ::MyClass }
          let(:foo) { MyClass }
        end
      RUBY
    end

    it 'ignores non-matching namespace' do
      expect_no_offenses(<<~RUBY)
        module MyNamespace
          describe MyClass do
            subject { ::MyClass }
          end
        end
      RUBY
    end

    it 'flags the use of described class with namespace' do
      expect_offense(<<~RUBY)
        describe MyNamespace::MyClass do
          subject { MyNamespace::MyClass }
                    ^^^^^^^^^^^^^^^^^^^^ Use `described_class` instead of `MyNamespace::MyClass`.
        end
      RUBY

      expect_correction(<<~RUBY)
        describe MyNamespace::MyClass do
          subject { described_class }
        end
      RUBY
    end

    it 'ignores non-matching namespace in usages' do
      expect_no_offenses(<<~RUBY)
        module UnrelatedNamespace
          describe MyClass do
            subject { MyNamespace::MyClass }
          end
        end
      RUBY
    end

    it 'ignores offenses within a class scope change' do
      expect_no_offenses(<<~RUBY)
        describe MyNamespace::MyClass do
          before do
            class Foo
              thing = MyNamespace::MyClass.new
            end
          end
        end
      RUBY
    end

    it 'ignores offenses within a hook scope change' do
      expect_no_offenses(<<~RUBY)
        describe do
          before do
            MyNamespace::MyClass.new
          end
        end
      RUBY
    end

    it 'flags the use of described class with module' do
      expect_offense(<<~RUBY)
        module MyNamespace
          describe MyClass do
            subject { MyNamespace::MyClass }
                      ^^^^^^^^^^^^^^^^^^^^ Use `described_class` instead of `MyNamespace::MyClass`.
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        module MyNamespace
          describe MyClass do
            subject { described_class }
          end
        end
      RUBY
    end

    it 'flags the use of described class with nested namespace' do
      expect_offense(<<~RUBY)
        module A
          class B::C
            module D
              describe E do
                subject { A::B::C::D::E }
                          ^^^^^^^^^^^^^ Use `described_class` instead of `A::B::C::D::E`.
                let(:one) { B::C::D::E }
                            ^^^^^^^^^^ Use `described_class` instead of `B::C::D::E`.
                let(:two) { C::D::E }
                            ^^^^^^^ Use `described_class` instead of `C::D::E`.
                let(:six) { D::E }
                            ^^^^ Use `described_class` instead of `D::E`.
                let(:ten) { E }
                            ^ Use `described_class` instead of `E`.
              end
            end
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        module A
          class B::C
            module D
              describe E do
                subject { described_class }
                let(:one) { described_class }
                let(:two) { described_class }
                let(:six) { described_class }
                let(:ten) { described_class }
              end
            end
          end
        end
      RUBY
    end

    it 'accepts an empty block' do
      expect_no_offenses(<<~RUBY)
        describe MyClass do
        end
      RUBY
    end

    it 'ignores if a local variable is part of the namespace' do
      expect_no_offenses(<<~RUBY)
        describe Broken do
          [Foo, Bar].each do |klass|
            describe klass::Baz.name do
              it { }
            end
          end
        end
      RUBY
    end

    it 'ignores if `described_class` is a part of the constant' do
      expect_no_offenses(<<~RUBY)
        module SomeGem
          describe VERSION do
            it 'returns proper version string' do
              expect(described_class::STRING).to eq('1.1.1')
            end
          end
        end
      RUBY
    end

    context 'when OnlyStaticConstants is `true`' do
      let(:cop_config) do
        { 'EnforcedStyle' => :described_class, 'OnlyStaticConstants' => true }
      end

      it 'ignores class with constant' do
        expect_no_offenses(<<~RUBY)
          describe MyClass do
            subject { MyClass::FOO }
          end
        RUBY
      end

      it 'ignores class with subclasses' do
        expect_no_offenses(<<~RUBY)
          describe MyClass do
            subject { MyClass::Subclass }
          end
        RUBY
      end
    end

    context 'when OnlyStaticConstants is `false`' do
      let(:cop_config) do
        { 'EnforcedStyle' => :described_class, 'OnlyStaticConstants' => false }
      end

      it 'flags class with constant' do
        expect_offense(<<~RUBY)
          describe MyClass do
            subject { MyClass::FOO }
                      ^^^^^^^ Use `described_class` instead of `MyClass`.
          end
        RUBY

        expect_correction(<<~RUBY)
          describe MyClass do
            subject { described_class::FOO }
          end
        RUBY
      end

      it 'flags class with subclasses' do
        expect_offense(<<~RUBY)
          describe MyClass do
            subject { MyClass::Subclass }
                      ^^^^^^^ Use `described_class` instead of `MyClass`.
          end
        RUBY

        expect_correction(<<~RUBY)
          describe MyClass do
            subject { described_class::Subclass }
          end
        RUBY
      end
    end

    it 'ignores parenthesized namespaces - begin_types' do
      expect_no_offenses(<<~RUBY)
        describe MyClass do
          subject { (MyNamespace)::MyClass }
        end
      RUBY
    end
  end

  context 'when EnforcedStyle is :explicit' do
    let(:cop_config) { { 'EnforcedStyle' => :explicit } }

    it 'flags the use of the described_class' do
      expect_offense(<<~RUBY)
        describe MyClass do
          include described_class
                  ^^^^^^^^^^^^^^^ Use `MyClass` instead of `described_class`.

          subject { described_class.do_something }
                    ^^^^^^^^^^^^^^^ Use `MyClass` instead of `described_class`.

          before { described_class.do_something }
                   ^^^^^^^^^^^^^^^ Use `MyClass` instead of `described_class`.
        end
      RUBY

      expect_correction(<<~RUBY)
        describe MyClass do
          include MyClass

          subject { MyClass.do_something }

          before { MyClass.do_something }
        end
      RUBY
    end

    it 'ignores described_class as string' do
      expect_no_offenses(<<~RUBY)
        describe MyClass do
          subject { "described_class" }
        end
      RUBY
    end

    it 'ignores describe that do not reference to a class' do
      expect_no_offenses(<<~RUBY)
        describe "MyClass" do
          subject { described_class }
        end
      RUBY
    end

    it 'ignores offenses within a class scope change' do
      expect_no_offenses(<<~RUBY)
        describe MyNamespace::MyClass do
          before do
            class Foo
              thing = described_class.new
            end
          end
        end
      RUBY
    end

    it 'ignores offenses within a hook scope change' do
      expect_no_offenses(<<~RUBY)
        describe do
          before do
            described_class.new
          end
        end
      RUBY
    end

    it 'autocorrects corresponding' do
      expect_offense(<<~RUBY)
        describe(Foo) { include described_class }
                                ^^^^^^^^^^^^^^^ Use `Foo` instead of `described_class`.
        describe(Bar) { include described_class }
                                ^^^^^^^^^^^^^^^ Use `Bar` instead of `described_class`.
      RUBY

      expect_correction(<<~RUBY)
        describe(Foo) { include Foo }
        describe(Bar) { include Bar }
      RUBY
    end
  end
end
