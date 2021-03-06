module Cauterize
  describe Cauterize::Builders::C::Enumeration do
    let(:type_constructor) { lambda {|name|
      Cauterize.enumeration(name) do |t|
        t.value :a, 100
      end
    }}

    it_behaves_like "a buildable"
    it_behaves_like "a sane buildable"
    include_examples "no struct"

    describe ".enum_defn" do
      let(:en) do
        _e = Cauterize.enumeration(:foo) do |e|
          e.value :aaa
          e.value :bbb
          e.value "QuickBrownFox".to_sym
        end

        f = default_formatter
        Builders.get(:c, _e).enum_defn(f)
        f.to_s
      end

      it "contains the enum name" do
        en.should match /enum foo/
      end

      it "contains an entry for each value" do
        en.should match /AAA = 0,/
        en.should match /BBB = 1,/
        en.should match /QUICK_BROWN_FOX = 2,/
        en.should match /};/
      end
    end

    describe ".packer_defn" do
      let(:en0) do
        _e = Cauterize.enumeration(:foo) do |e|
          e.value :aaa
          e.value :bbb
          e.value "QuickBrownFox".to_sym
        end

        f = default_formatter
        Builders.get(:c, _e).packer_defn(f)
        f.to_s
      end

      let(:en1) do
        _e = Cauterize.enumeration(:bar) do |e|
          e.value :aaa, 500
          e.value :bbb, -30
        end

        f = default_formatter
        Builders.get(:c, _e).packer_defn(f)
        f.to_s
      end

      it "defines a representation variable" do
        en0.should match /int8_t enum_representation;/
        en1.should match /int16_t enum_representation;/
      end

      it "references a packer for the representation" do
        en0.should match /Pack_int8/
        en1.should match /Pack_int16/
      end
    end

    describe ".unpacker_defn" do
      let(:en) do
        _e = Cauterize.enumeration(:foo) do |e|
          e.value :aaa
          e.value :bbb
          e.value "QuickBrownFox".to_sym
        end

        f = default_formatter
        Builders.get(:c, _e).unpacker_defn(f)
        f.to_s
      end

      it "defines a representation variable" do
        en.should match /int8_t enum_representation;/
      end

      it "references a unpacker for the representation" do
        en.should match /Unpack_int8/
      end
    end
  end
end
