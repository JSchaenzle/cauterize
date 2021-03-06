module Cauterize
  describe Cauterize::Builders::C::Group do
    let(:type_constructor) { lambda {|name| Cauterize.group(name)}}

    it_behaves_like "a buildable"
    it_behaves_like "a sane buildable"
    include_examples "no enum"

    context "enumeration for type tag" do
      before do
        Cauterize.scalar(:byte) do |_t|
          _t.type_name :uint8
        end

        @g = Cauterize.group!(:some_name) do |_g|
          _g.field(:a, :byte)
          _g.field(:b, :byte)
          _g.dataless(:c)
        end
        @b = Cauterize::Builders::C::Group.new(@g)
      end

      describe ".initialize" do
        it "creates the enumeration tag" do
          @b.instance_variable_get(:@tag_enum).class.name.should == "Cauterize::Enumeration"
        end
      end

      describe "@tag_enum" do
        it "contains a entry for each field in the group" do
          e = @b.instance_variable_get(:@tag_enum)
          e.values.keys.should =~ [ :GROUP_SOME_NAME_TYPE_A,
                                    :GROUP_SOME_NAME_TYPE_B,
                                    :GROUP_SOME_NAME_TYPE_C ]
        end
      end

      describe ".constant_defines" do
        before do
          f = default_formatter
          @b.constant_defines(f)
          @fs = f.to_s
        end

        it "contains the maximum encoded length definition" do
          @fs.should match /MAX_ENCODED_LENGTH_some_name/
        end

        it "includes the group length in the max encoded length" do
          @fs.should match /MAX_ENCODED_LENGTH_some_name.+MAX_ENCODED_LENGTH_group_some_name_type/
        end

        it "includes the length of type synonyms 'a', 'b' in the max encoded length" do
          @fs.should match /MAX_ENCODED_LENGTH_some_name.+MAX_ENCODED_LENGTH_byte/
          @fs.should match /MAX_ENCODED_LENGTH_some_name.+MAX_ENCODED_LENGTH_byte/
        end
      end

      describe ".packer_defn" do
        before do
          f = default_formatter
          @b.packer_defn(f)
          @fs = f.to_s
        end

        it "contains the enum packer" do
          @fs.should match /Pack_group_some_name_type/
        end

        it "contains each tag" do
          @fs.should match /GROUP_SOME_NAME_TYPE_A/
          @fs.should match /GROUP_SOME_NAME_TYPE_B/
          @fs.should match /GROUP_SOME_NAME_TYPE_C/
        end

        it "contains each data field" do
          @fs.should match /src->data\.a/
          @fs.should match /src->data\.b/
        end
      end

      describe ".unpacker_defn" do
        before do
          f = default_formatter
          @b.unpacker_defn(f)
          @fs = f.to_s
        end

        it "contains the enum unpacker" do
          @fs.should match /Unpack_group_some_name_type/
        end

        it "contains each tag" do
          @fs.should match /GROUP_SOME_NAME_TYPE_A/
          @fs.should match /GROUP_SOME_NAME_TYPE_B/
          @fs.should match /GROUP_SOME_NAME_TYPE_C/
        end

        it "contains each data field" do
          @fs.should match /dst->data\.a/
          @fs.should match /dst->data\.b/
        end
      end
    end

    context "structure definition" do
      let(:grp) do
        _g = Cauterize.group(:oof) do |g|
          g.field(:aaa, :int32)
          g.field(:bbb, :int32)
          g.dataless(:empty)
        end

        Builders.get(:c, _g)
      end

      describe ".struct_proto" do
        it "defines a structure prototype" do
          f = default_formatter
          grp.struct_proto(f)
          f.to_s.should == "struct oof;"
        end
      end

      describe ".struct_defn" do
        it "defines a structure definition" do
          f = default_formatter
          grp.struct_defn(f)
          fs = f.to_s

          fs.should match /struct oof/
          fs.should match /enum group_oof_type tag;/
          fs.should match /union/
          fs.should match /int32_t aaa;/ # built-in types are represented as their C type
          fs.should match /int32_t bbb;/ # built-in types are represented as their C type
          fs.should match /No data associated with 'empty'./
          fs.should match /} data;/
          fs.should match /};/
        end
      end
    end
  end
end
