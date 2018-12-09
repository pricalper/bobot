module Bobot
  module Event
    class TakeThreadControl
      include Bobot::Event::Common

      def previous_owner_app_id
        @messaging['take_thread_control']['previous_owner_app_id']
      end

      def access_token
        Bobot::Page.find(recipient["id"])
      end

    end
  end
end
