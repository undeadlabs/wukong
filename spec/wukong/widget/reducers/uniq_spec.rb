require 'spec_helper'

describe "Reducers" do
  describe :uniq do
    include_context "reducers"
    it_behaves_like 'a processor', :named => :uniq
    it "should remove duplicate records" do
      processor.given(*strings.sort).should emit(*strings.sort.uniq)
    end
    it "should output nothing if given no records" do
      processor.given().should emit()
    end
  end
end
