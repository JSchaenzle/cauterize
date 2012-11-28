class Group
  def self.from_hash(hash)
    validate(hash, "group")
    group = hash["group"]
    validate(group, "name", "members")

    Group.new(group["name"], group["members"])
  end

  def initialize(name, members)
    @name = name
    @members = members.map {|m| GroupMember.from_obj(m)}
  end

  def enum_type
    "enum #{up_name}"
  end

  def up_name
    "GROUP_" + @name.up_snake
  end

  def name_as_prefix
    up_name + "_"
  end

  def format_enumeration(formatter)
    formatter.enum(up_name) do |f|
      member_enums = @members.map {|m| m.enum_name(name_as_prefix)}
      member_enums.each {|m| f << "#{m},"}
    end
    formatter.blank_line
  end

  def format_struct(formatter)
    uses_length = @members.any? {|m| m.sizeFunc}
    formatter.struct(@name) do |f|
      f << "#{enum_type} tag;"
      f << "size_t length;"
      f.braces("union") do |g|
        @members.each {|m| g << "struct #{m.name} #{m.name.down_snake};"}
      end
      formatter.append_last(" data;")
    end
    formatter.blank_line
  end

  def format_packer(formatter)
    params = [ "struct Cauterize * dst", "struct #{@name} * src" ]
    formatter.func("Pack#{@name}", "CAUTERIZE_STATUS_T", params) do |f|
      f << "CAUTERIZE_STATUS_T s;"
      f.blank_line

      # Copy the tag.
      f << "/* Copy the tag. */"
      f << "s = CauterizeAppend(dst, &(src->tag), sizeof(src->tag));"
      f.braces("if (CA_OK != s)") do
        f << "return s;"
      end
      f.blank_line

      # Copy the union.
      f.braces("switch (src->tag)") do
        @members.each do |m|
          # Create the field
          field = "src->data.#{m.name.down_snake}"
          f.undented { f << "case #{m.enum_name(name_as_prefix)}:"}

          # Update and copy the length
          f << "/* Copy the length. */"
          sizeFunc = m.sizeFunc || "sizeof"
          f << "src->length = #{sizeFunc}(#{field})"
          f << "s = CauterizeAppend(dst, &(src->length), sizeof(src->length));"
          f.braces("if (CA_OK != s)") do
            f << "return s;"
          end
          f.blank_line

          # Copy the data
          f << "s = CauterizeAppend(dst, &(#{field}), src->length);"
          f.braces("if (CA_OK != s)") do
            f << "return s;"
          end
          f << "break;"
          f.blank_line
        end
      end
      f.blank_line
      f << "return CA_OK;"
    end
    formatter.blank_line
  end

  def format_unpacker(formatter)
    params = [ "struct #{@name} * dst", "struct Cauterize * src" ]
    formatter.func("Unpack#{@name}", "CAUTERIZE_STATUS_T", params) do |f|
      f << "CAUTERIZE_STATUS_T s;"
      f << "size_t length = 0;"
      f.blank_line

      # Read the tag.
      f << "s = CauterizeRead(src, &(dst->tag), sizeof(dst->tag));"
      f.braces("if (CA_OK != s)") do
        f << "return s;"
      end
      f.blank_line

      # Copy the length
      f << "s = CauterizeRead(src, &(dst->length), sizeof(dst->length));"
      f.braces("if (CA_OK != s)") do
        f << "return s;"
      end
      f.blank_line

      # Read the union based on the tag.
      f.braces("switch (dst->tag)") do
        @members.each do |m|
          field = "dst->data.#{m.name.down_snake}"
          f.undented { f << "case #{m.enum_name(name_as_prefix)}:"}

          f << "s = CauterizeRead(src, &(#{field}), &(dst->length));"
          f.braces("if (CA_OK != s)") do
            f << "return s;"
          end
          f << "break;"
          f.blank_line
        end
      end
      f.blank_line
      f << "return CA_OK;"
    end
    formatter.blank_line
  end
end
