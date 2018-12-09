module Bobot
  module Commander
    class Error < Bobot::FacebookError; end

    EVENTS = %i[
      message
      delivery
      postback
      optin
      read
      account_linking
      referral
      message_echo
      message_request
      policy-enforcement
      pass_thread_control
      take_thread_control
    ].freeze

    include Bobot::GraphFacebook

    class << self
      def deliver(body:, query:, action: '/me/messages')
        graph_post action, body: body, query: {
          access_token: query.fetch(:access_token),
        }
      end

      def on(event, &block)
        if EVENTS.include? event
          hooks[event] = block
        else
          warn "[bobot trigger] Ignoring #{event.class} (not available in [#{EVENTS.join(', ')}])"
        end
      end

      def receive(payload)
        event = Bobot::Event.parse(payload)
        event.mark_as_seen if (event.page.present? & !is_echo?(event) & !thread_control?(event))

        hooks.fetch(Bobot::Event::EVENTS.invert[event.class].to_sym)

        Bobot::CommanderJob.send(
          Bobot.config.async ? :perform_later : :perform_now,
          { payload: payload },
        )
      rescue KeyError
        warn "[bobot trigger] Ignoring #{event.class} (no hook registered)"
      end

      def trigger(payload)
        event = Bobot::Event.parse(payload)
        return unless (event.page.present? || is_echo?(event) || thread_control?(event))

        hook = hooks.fetch(Bobot::Event::EVENTS.invert[event.class].to_sym)
        hook.call(event)
      rescue KeyError
        warn "[bobot trigger] Ignoring #{event.class} (no hook registered)"
      end

      def hooks
        @hooks ||= {}
      end

      def unhook
        @hooks = {}
      end

      def is_echo?(event)
        if event.messaging["message"]
          event.messaging["message"]["is_echo"]
        end
      end

      def thread_control?(event)
        (event.messaging["take_thread_control"] || event.messaging["pass_thread_control"])
      end

    end
  end
end
