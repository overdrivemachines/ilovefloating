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

    # Execute only for `invoice.payment_succeeded` events.
    def handle_invoice_payment_succeeded(event)
      puts "****handle_invoice_payment_succeeded executing"
      # TODO: logging
      # logger.info "handle_invoice_payment_succeeded executing"
      # logger.info "EVENT:#{event.type}:#{event.id}"
      
      # Increment payments count

      # https://stripe.com/docs/recipes/installment-plan
      # https://stripe.com/docs/webhooks/setup
      
      puts "Livemode: " + event["livemode"].to_s

      if (event["livemode"] == false)
        # Grab the subscription line item.
        sub =  event.data.object.lines.data[0]

        puts "***event.data.object.lines.data[0]: " + sub.to_s

        return

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

          puts "New Installment: " + count.to_s
          # Save incremented value to `installments_paid` metadata of the subscription.
          
          # begin
          subscription_object = Stripe::Subscription.update( 
            sub["subscription"]["id"], {
              metadata: {
                  installments_paid: count,
                  source: "RoR"
              },
            }, stripe_account: event["account"] )

          puts "Subscription " + sub["subscription"]["id"] + " updated. Count: " + count

          # Check if all 10 installments have been paid.
          # If paid in full, then cancel the subscription.
          if count >= 6
              subscription_object.delete
          end
          # rescue StandardError => e
          #   render json: {:status => 400, :error => e}
          #   return
          # end
          
        end
      end
      # puts event.data.object.class
      # render json: {:status => 400, :info => event}
    end
  end
end