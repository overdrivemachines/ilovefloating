Stripe.api_key = Rails.application.credentials.stripe[Rails.env.to_sym][:publishable_key]
StripeEvent.signing_secret = Rails.application.credentials.stripe[Rails.env.to_sym][:signing_secret]

StripeEvent.configure do |events|
  events.subscribe 'invoice.', Stripe::InvoiceEventHandler.new
end