module Molinillo
  class TestUI
    include UI

    def output
      @output ||= if debug?
                    STDERR
                  else
                    File.open("/dev/null", "w")
                  end
    end
  end
end
