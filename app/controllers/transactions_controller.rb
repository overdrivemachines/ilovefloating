class TransactionsController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => [:stripe_webhooks]

  # GET /transactions
  # def index
  #   @transactions = Transaction.all
  # end

  # GET /transactions/new
  def new
    @transaction = Transaction.new
    # Temp Data
    @transaction.name = "Dipen Chauhan"
    @transaction.email = "get.dipen@gmail.com"
    @transaction.phone = "(530)566-3038"
    @transaction.sales_rep_name = "John Smith"

  end

  # POST /transactions
  def create
    @transaction = Transaction.new(transaction_params)
    is_subscription = false
    # Determining item name and price
    # TODO: move items to a table
    if (transaction_params[:item].nil?)
      @transaction.item = "Test"
      @transaction.price = 2.0
    elsif (transaction_params[:item] == "0")
      @transaction.item = "6 Week Stress Release Program (10% discount paid in full)"
      @transaction.price = 447.0
    elsif (transaction_params[:item] == "1")
      @transaction.item = "60 Minute Floatation Therapy Session"
      @transaction.price = 75.0
    elsif (transaction_params[:item] == "2")
      @transaction.item = "6 Week Stress Release Program (Payment Plan)"
      @transaction.price = 75.0
      is_subscription = true
    elsif (transaction_params[:item] == "3")
      @transaction.item = "Test"
      @transaction.price = 2.0
    end

    # we will save the transaction first. This is a good way to check for validation errors
    if @transaction.save
      # Find the connected account   
      connected_account = ConnectedAccount.find_by(id: transaction_params[:connected_account_id])
      if (connected_account.nil?)
        flash[:error] = "Connect Account #{transaction_params[:connected_account_id]} not found."
        render :new
        return
      end

      # Retreive the stripe token
      stripe_token = params[:stripeToken]
      if (stripe_token.nil?)
        redirect_to connected_accounts_url, flash: { error: "Stripe token not received from Stripe"}
        return
      end

      # Determine the Application Fee amount
      stripe_fee = (0.3 + (2.9 / 100.0) * @transaction.price).round(2)
      client_received = @transaction.price - stripe_fee
      if (client_received <= 0)
        redirect_to connected_accounts_url, flash: { error: "Client made negative amount so no Application Fee received."}
        return
      end
      application_fee = ((connected_account.commission / 100.0) * client_received).round(2)

      # Determine the Connected Account's 

      # Stripe.api_key = 'sk_test_lPVHKFQDPSSLI6uiJr4dVdY7'
      Stripe.api_key = Rails.application.credentials.stripe[Rails.env.to_sym][:secret_key]
      # Stripe.api_key = Rails.application.credentials.stripe[:production][:secret_key]
      # Stripe.api_key = Rails.application.credentials.api_key

      # finding if customer exists in connected account
      customer_id = nil
      begin
        # customers = Stripe::Customer.list({
        #     email: @transaction.email,
        #     limit: 1
        # }, stripe_account: connected_account.sid)
        customers = Stripe::Customer.list({
            email: @transaction.email,
            limit: 1
        })
        if (customers["data"].size == 0)
          # Customer not found
          # Create a new Customer
          puts "Creating new Customer"
          # customer = Stripe::Customer.create({
          #   name: @transaction.name,
          #   email: @transaction.email,
          #   phone: @transaction.phone,
          #   source: stripe_token, # obtained with Stripe.js
          # }, stripe_account: connected_account.sid)
          customer = Stripe::Customer.create({
            name: @transaction.name,
            email: @transaction.email,
            phone: @transaction.phone,
            source: stripe_token, # obtained with Stripe.js
          })
          customer_id = customer["id"];
          puts "New Customer ID: " + customer_id
        else
          # Customer already exists, get the Customer ID
          puts "Customer #{@transaction.name} already exists"
          customer_id = customers["data"][0]["id"]
          puts "Customer ID: " + customer_id
          # Update Name and Phone
          # Stripe::Customer.update(
          #   customer_id,
          #   {
          #     name: @transaction.name,
          #     email: @transaction.email,
          #     phone: @transaction.phone,
          #     source: stripe_token # obtained with Stripe.js
          #   }, stripe_account: connected_account.sid)
          Stripe::Customer.update(
            customer_id,
            {
              name: @transaction.name,
              email: @transaction.email,
              phone: @transaction.phone,
              source: stripe_token # obtained with Stripe.js
            })
          puts "Customer Updated"
        end
      rescue StandardError => e
        flash[:error] = "Error: Transaction not completed. Customer update failed. " + e.to_s
        render :new
        return
      end


      # Shared Customers - https://stripe.com/docs/connect/shared-customers
      # We need to share the customer from the platform account to the connected account
      # Making tokens
      # If the customer is stored on the platform account and the charge is on the
      # connected account, a new token needs to be created
      customer_token = nil
      if (!is_subscription)
        begin
          customer_token = Stripe::Token.create({
            :customer => customer_id,
          }, {:stripe_account => connected_account.sid })
          puts "New Customer Token: " + customer_token.id
        rescue StandardError => e
          flash[:error] = "Error: Transaction not completed. Customer token creation failed. " + e.to_s
          render :new
          return
        end
      else

        # # Save the customer on the connected account
        # # https://stripe.com/docs/connect/shared-customers#making-a-charge
        # shared_customer = Stripe::Customer.create({
        #     name: @transaction.name,
        #     email: @transaction.email,
        #     phone: @transaction.phone,
        #     description: 'Shared Customer',
        #     source: customer_token.id,
        # }, stripe_account: connected_account.sid)
        # puts "New Customer on Connected Account: " + shared_customer.id

        # Signing up the customer for the installment plan
        # Do this only if the customer has selected option (2)
        # Customer is automatically charged
        begin
          subscription = Stripe::Subscription.create({
              customer: customer_id,
              items: [{
                  plan: Rails.application.credentials.stripe[Rails.env.to_sym][:weekly_plan_id],
              }],
              application_fee_percent: connected_account.commission,
              metadata: {
                  installments_paid: 0,
              },
          }, stripe_account: connected_account.sid )
          puts "Subscription: " + subscription.to_s
          @transaction.charge_id = subscription["id"]
          @transaction.save
          redirect_to connected_accounts_url, flash: { success: "Transaction completed successfully. Subscription ID: #{subscription["id"]}. Amount: $#{@transaction.price}. Stripe Fees: $#{stripe_fee}. Application Fee: $#{application_fee}"}
          return
        rescue StandardError => e
          flash[:error] = "Error: Transaction not completed. Subscription failed. " + e.to_s
          render :new
          return
        end
      end
      
      # Charge the customer
      # Testing errors:
      # https://stripe.com/docs/testing
      # Receipts: https://stripe.com/docs/receipts
      # https://stripe.com/docs/recipes/sending-custom-email-receipts
      # Metadata: https://stripe.com/docs/charges
      begin
        charge = Stripe::Charge.create({
          amount: (@transaction.price * 100).to_i,
          currency: "usd",
          description: @transaction.item,
          source: customer_token.id,
          statement_descriptor: @transaction.item[0..21],
          receipt_email: @transaction.email,
          application_fee_amount: (application_fee * 100).to_i,
          # customer: shared_customer.id,
          metadata: {'name' => @transaction.name,
                      'email' => @transaction.email,
                      'phone' => @transaction.phone,
                      'start_date' => @transaction.start_date,
                      'sales_rep_name' => @transaction.sales_rep_name,
                      'platform_customer_id' => customer_id},
        }, stripe_account: connected_account.sid)

        puts "***Charge ID: " + charge.id
      rescue StandardError => e
        flash[:error] = "Error: Transaction not completed. Charge failed. " + e.to_s
        render :new
        return
      end

      @transaction.charge_id = charge["id"]
      @transaction.save
      redirect_to connected_accounts_url, flash: { success: "Transaction completed successfully. ID: #{charge["id"]}. Amount: $#{@transaction.price}. Stripe Fees: $#{stripe_fee}. Application Fee: $#{application_fee}"}
      return
    else
      render :new
      return
    end   
  end

  private

    # Never trust parameters from the scary internet, only allow the white list through.
    def transaction_params
      params.require(:transaction).permit(:name, :email, :phone, :start_date, :sales_rep_name, :item, :connected_account_id)
    end
end
