module Cauterize
  module Builders
    module C
      class Composite < Buildable
        def render
          "struct #{@blueprint.name.to_s}"
        end

        def declare(formatter, sym)
          formatter << "#{render} #{sym};"
        end

        def constant_defines(formatter)
          field_lens = @blueprint.fields.values.map do |field|
            Builders.get(:c, field.type).max_enc_len_cpp_sym
          end

          formatter << "enum { #{max_enc_len_cpp_sym} = (#{field_lens.join(" + ")}) };"
        end

        def packer_defn(formatter)
          formatter << "CAUTERIZE_STATUS_T err;"
          if @blueprint.needs_checksum
            formatter << "uint32_t start;"
            formatter << "if (CA_OK != (err = CauterizeStartChecksum(dst, &start))) { return err; }"
          end
          @blueprint.fields.values.each do |field|
            p_sym = Builders.get(:c, field.type).packer_sym
            formatter << "if (CA_OK != (err = #{p_sym}(dst, &src->#{field.name}))) { return err; }"
          end
          if @blueprint.needs_checksum
            formatter << "if (CA_OK != (err = CauterizeWriteChecksum(dst, start))) { return err; }"
          end
          formatter << "return CA_OK;"
        end

        def unpacker_defn(formatter)
          formatter << "CAUTERIZE_STATUS_T err;"
          if @blueprint.needs_checksum
            formatter << "if (CA_OK != (err = CauterizeVerifyChecksum(src))) { return err; }"
          end
          @blueprint.fields.values.each do |field|
            u_sym = Builders.get(:c, field.type).unpacker_sym
            formatter << "if (CA_OK != (err = #{u_sym}(src, &dst->#{field.name}))) { return err; }"
          end
          formatter << "return CA_OK;"
        end

        def struct_proto(formatter)
          formatter << (render + ";")
        end

        def struct_defn(formatter)
          formatter << render
          formatter.braces do
            @blueprint.fields.values.each do |field|
              Builders.get(:c, field.type).declare(formatter, field.name)
            end
          end
          formatter.append(";")
        end
      end
    end
  end
end

Cauterize::Builders.register(:c, Cauterize::Composite, Cauterize::Builders::C::Composite)
