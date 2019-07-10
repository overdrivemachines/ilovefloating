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
    end

    # Execute only for `invoice.payment_succeeded` events.
    def handle_invoice_payment_succeeded(event)
      # TODO: logging
      e_logger = Logger.new('log/event.log', 10, 1024000)
      # e_logger.info "handle_invoice_payment_succeeded executing"
      # e_logger.info "EVENT:#{event.type}: #{event.id}"
      e_logger.info "================================"
      e_logger.info "NEW EVENT: #{event.id}"
      e_logger.info "================================"
      
      # Increment payments count

      # https://stripe.com/docs/recipes/installment-plan
      # https://stripe.com/docs/webhooks/setup
      
      if (event["livemode"] == true) || (Rails.env == "development")
        # Grab the subscription line item.
        sub =  event.data.object.lines.data[0]

        e_logger.info "Account ID: " + event["account"].to_s
        e_logger.info "Subscription ID: " + sub["id"].to_s
        e_logger.info "Installments_paid: " + sub["metadata"]["installments_paid"].to_s

        # Execute only for installment plans.
        if !sub.metadata[:installments_paid].nil?
          # Recommendation: Log invoices and check for duplicate events.
          # Recommendation: Note that we send $0 invoices for trials.
          #                 You can verify the `amount_paid` attribute of
          #                 the invoice object before incrementing the count.

          # Retrieve and increment the number of payments.
          count = sub.metadata[:installments_paid].to_i
          count += 1
          
          # Metadata is not write-protected; creating a database is an alternative.

          # Save incremented value to `installments_paid` metadata of the subscription.
          
          subscription_object = nil
          begin
            subscription_object = Stripe::Subscription.update(sub["subscription"], { metadata: { installments_paid: count, source: "RoR" }, }, stripe_account: event["account"] )
          rescue StandardError => e
            e_logger.error e
            return
          end
          # Check if all 10 installments have been paid.
          # If paid in full, then cancel the subscription.
          if (subscription_object.nil?)
            e_logger.error "Subscription Object is nil. Subscription cannot be updated"
          else
            e_logger.info "Subscription Updated Successfully"
            e_logger.info "New Installments: " + subscription_object["metadata"]["installments_paid"].to_s
            if count >= 6
                subscription_object.delete
            end
          end

          # rescue StandardError => e
          #   e_logger.error e
          #   return
          # end
        end
      end
      # puts event.data.object.class
      # render json: {:status => 400, :info => event}
    end
  end
end