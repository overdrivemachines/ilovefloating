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
      Stripe.api_key = Rails.application.credentials.stripe[:development][:secret_key]
      # Stripe.api_key = Rails.application.credentials.stripe[:production][:secret_key]
      # Stripe.api_key = Rails.application.credentials.api_key

      # finding if customer exists
      customer_id = nil
      begin
        customers = Stripe::Customer.list(email: @transaction.email , limit: 1)
        if (accounts["data"].size == 0)
          # Customer not found
          # Create a new Customer
          customer = Stripe::Customer.create({
            name: @transaction.name,
            email: @transaction.email,
            phone: @transaction.phone,
            description: 'Customer for jenny.rosen@example.com',
            source: stripe_token, # obtained with Stripe.js
          })
        else
          # Customer already exists, get the Customer ID
          customer_id = accounts["data"][0]["id"]
          # Update Name and Phone
          Stripe::Customer.update(
            customer_id,
            {
              name: @transaction.name,
              email: @transaction.email,
              phone: @transaction.phone,
              source: stripe_token
            })
        end        
      rescue StandardError => e
        flash[:error] = "Error: Transaction not completed. " + e.to_s
        render :new
        return
      end


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
          source: stripe_token,
          statement_descriptor: @transaction.item[0..21],
          receipt_email: @transaction.email,
          application_fee_amount: (application_fee * 100).to_i,
          customer: customer_id,
          metadata: {'name' => @transaction.name,
                      'email' => @transaction.email,
                      'phone' => @transaction.phone,
                      'start_date' => @transaction.start_date,
                      'sales_rep_name' => @transaction.sales_rep_name },
        }, stripe_account: connected_account.sid)
      rescue StandardError => e
        flash[:error] = "Error: Transaction not completed. " + e.to_s
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
