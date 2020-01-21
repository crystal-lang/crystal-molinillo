require "./spec_helper"

module Molinillo
  describe ResolutionState do
    describe DependencyState do
      it "pops a possibility state" do
        state = DependencyState(Nil, String, String).new(
          "name",
          %w(requirement1 requirement2 requirement3),
          DependencyGraph(Nil, String).new,
          "requirement",
          %w(possibility1 possibility),
          0,
          {} of String => Nil,
          [] of Nil
        )
        possibility_state = state.pop_possibility_state
        # %w(name requirements activated requirement conflicts).each do |attr|
        #   expect(possibility_state.send(attr)).to eq(state.send(attr))
        # end
        possibility_state.should be_a(PossibilityState(Nil, String, String))
        possibility_state.depth.should eq(state.depth + 1)
        possibility_state.possibilities.should eq(%w(possibility))
      end
    end
  end
end
