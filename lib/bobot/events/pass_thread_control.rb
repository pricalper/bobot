module Bobot
  module Event
    class PassThreadControl
      include Bobot::Event::Common

      def page
        @messaging['recipient']['id']
      end

    end
  end
end