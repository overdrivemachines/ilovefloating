module Stripe
  class InvoiceEventHandler
    # https://dev.to/maxencehenneron/handling-stripe-webhooks-with-ruby-on-rails-4bb7
    def call(event)
      begin
        method = "handle_" + event.type.tr('.', '_')
        self.send method, event
      rescue JSON::ParserError => e
        render json: {:status => 400, :error => "Invalid payload"}
        return
      rescue NoMethodError => e
      end
    end

    def handle_invoice_payment_failed(event)
      puts "***handle_invoice_payment_failed executing"
    end

    def handle_invoice_payment_succeeded(event)
      puts "****handle_invoice_payment_succeeded executing"
      # logger.info "handle_invoice_payment_succeeded executing"
      # logger.info "EVENT:#{event.type}:#{event.id}"
      
      puts event.data.object.class
      render json: {:status => 400, :info => event}
    end
  end
end