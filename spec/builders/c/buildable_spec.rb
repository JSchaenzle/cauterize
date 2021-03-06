module Cauterize::Builders::C
  describe Cauterize::Builders::C do
    describe Buildable do
      subject { Buildable.new(:some_blueprint) }

      describe "required methods" do
        it "raises errors on required interfaces" do
          lambda {
            REQUIRED_METHODS.each do |m|
              subject.send(m)
            end
          }.should raise_error /must implement/
        end
      end

      describe :method_missing do
        it "calls the original if method not required" do
          lambda {
            subject.is_not_defined
          }.should raise_error NoMethodError
        end
      end
    end
  end
end
