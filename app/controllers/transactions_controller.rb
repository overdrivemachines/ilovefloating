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
    # @transaction.name = "Dipen Chauhan"
    # @transaction.email = "get.dipen@gmail.com"
    # @transaction.phone = "(530)566-3038"
    # @transaction.sales_rep_name = "John Smith"

  end

  # POST /transactions
  def create
    @transaction = Transaction.new(transaction_params)
    @redirect = false
    is_subscription = false
    # Determining item name and price
    # TODO: move items to a table
    if (transaction_params[:item].nil?)
      @transaction.item = "Test"
      @transaction.price = 2.0
    elsif (transaction_params[:item] == "0")
      @transaction.item = "6 Week Stress Release Program (10% discount paid in full)"
      @transaction.price = 375.0
    elsif (transaction_params[:item] == "1")
      @transaction.item = "60 Minute Floatation Therapy Session"
      @transaction.price = 75.0
    elsif (transaction_params[:item] == "2")
      @transaction.item = "6 Week Stress Release Program (Payment Plan)"
      @transaction.price = 69.0
      is_subscription = true
    elsif (transaction_params[:item] == "3")
      @transaction.item = "Test"
      @transaction.price = 2.0
    elsif (transaction_params[:item] == "4")
      @transaction.item = "Test Subscription"
      @transaction.price = 2.25
      is_subscription = true
    end

    # we will save the transaction first. This is a good way to check for validation errors
    if @transaction.save
      # Find the connected account   
      connected_account = ConnectedAccount.find_by(id: transaction_params[:connected_account_id])
      if (connected_account.nil?)
        flash[:error] = "Connect Account #{transaction_params[:connected_account_id]} not found."
        redirect_to new_transaction_url and return
      end

      # Retreive the stripe token
      stripe_token = params[:stripeToken]
      if (stripe_token.nil?)
        redirect_to connected_accounts_url, flash: { error: "Stripe token not received from Stripe"}
        return
      end

      # Set the API key based on Rails environment
      Stripe.api_key = Rails.application.credentials.stripe[Rails.env.to_sym][:secret_key]

      # Create an Customer on Connected Account
      customer_id = create_or_update_customer(@transaction.name, 
        @transaction.email, 
        @transaction.phone,
        @transaction.sales_rep_name,
        stripe_token,
        connected_account.sid)
      if (@redirect)
        return
      end

      if (is_subscription)
        # Check or Create Product
        # Check or Create Plan
        plan_id = check_or_create_plan(connected_account.sid)
        if (@redirect)
          return
        end

        begin
          subscription = Stripe::Subscription.create({
              customer: customer_id,
              items: [{
                  plan: plan_id,
              }],
              application_fee_percent: connected_account.commission,
              metadata: {
                  installments_paid: 0,
                  source: "RoR"
              },
          }, stripe_account: connected_account.sid )
          @transaction.charge_id = subscription["id"]
          @transaction.save
          redirect_to connected_accounts_url, flash: { success: "Transaction completed successfully. Subscription ID: #{subscription["id"]}. Amount: $#{@transaction.price}."}
          return
        rescue StandardError => e
          flash[:error] = "Error: Transaction not completed. Subscription failed. " + e.to_s
          redirect_to new_transaction_url
          return
        end

      else
        stripe_fee = calculate_stripe_fee(@transaction.price)
        application_fee = calculate_application_fee(@transaction.price, connected_account.commission)

        # Charge the customer
        # Testing errors:
        # https://stripe.com/docs/testing
        # Receipts: https://stripe.com/docs/receipts
        # https://stripe.com/docs/recipes/sending-custom-email-receipts
        # Metadata: https://stripe.com/docs/charges
        redirect = false
        begin
          charge = Stripe::Charge.create({
            amount: (@transaction.price * 100).to_i,
            currency: "usd",
            description: @transaction.item,
            # source: customer_token.id,
            statement_descriptor: @transaction.item[0..21],
            receipt_email: @transaction.email,
            application_fee_amount: (application_fee * 100).to_i,
            customer: customer_id,
            metadata: {'name' => @transaction.name,
                        'email' => @transaction.email,
                        'phone' => @transaction.phone,
                        'start_date' => @transaction.start_date,
                        'sales_rep_name' => @transaction.sales_rep_name,
                        'platform_customer_id' => customer_id},
          }, stripe_account: connected_account.sid)

        rescue StandardError => e
          flash[:error] = "Error: Transaction not completed. Charge failed. " + e.to_s
          redirect = true
        end

        if redirect
          redirect_to new_transaction_url and return
        end
      end

      if (is_subscription)
        # TODO: setup a Product and a Plan
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
          @transaction.charge_id = subscription["id"]
          @transaction.save
          redirect_to connected_accounts_url, flash: { success: "Transaction completed successfully. Subscription ID: #{subscription["id"]}. Amount: $#{@transaction.price}. Stripe Fees: $#{stripe_fee}. Application Fee: $#{application_fee}"}
          return
        rescue StandardError => e
          flash[:error] = "Error: Transaction not completed. Subscription failed. " + e.to_s
          redirect_to new_transaction_url and return
        end
      end

      @transaction.charge_id = charge["id"]
      @transaction.save
      redirect_to connected_accounts_url, flash: { success: "Transaction completed successfully. ID: #{charge["id"]}. Amount: $#{@transaction.price}. Stripe Fees: $#{stripe_fee}. Application Fee: $#{application_fee}"}
      return
    else
      redirect_to new_transaction_url and return
    end   
  end

  private

  # Create a Customer on Connected Account
  def create_or_update_customer(name, email, phone, sales_rep_name, stripe_token, sid)
    # finding if customer exists in connected account
    customer_id = nil
    begin
      customers = Stripe::Customer.list({
          email: email,
          limit: 1
      }, stripe_account: sid)

      if (customers["data"].size == 0)
        # Customer not found
        # Create a new Customer on Connected Account
        customer = Stripe::Customer.create({
          name: name,
          email: email,
          phone: phone,
          source: stripe_token, # obtained with Stripe.js
        }, stripe_account: sid)
        customer_id = customer["id"];
      else
        # Customer already exists, get the Customer ID
        customer_id = customers["data"][0]["id"]
        # Update Name, Phone and Credit Card info (source)
        Stripe::Customer.update(
          customer_id,
          {
            name: name,
            email: email,
            phone: phone,
            source: stripe_token # obtained with Stripe.js
          }, stripe_account: sid)
      end
    rescue StandardError => e
      @redirect = true
      flash[:error] = "Error: Transaction not completed. Customer update failed. " + e.to_s
      redirect_to new_transaction_url and return
    end
    return customer_id
  end

  def calculate_stripe_fee(price)
    return (0.3 + (2.9 / 100.0) * price).round(2)
  end

  def calculate_application_fee(price, commission)
    # Determine the Application Fee amount
    client_received = price - calculate_stripe_fee(price)
    if (client_received <= 0)
      return 0
    end
    af = ((commission / 100.0) * client_received).round(2)
    return af
  end

  def check_or_create_product(sid)
    # List the products in the Connected Account

    begin
      products = Stripe::Product.list({limit: 20, type: "service"}, stripe_account: sid)
      product = nil
      if (products["data"].size != 0)
        # iterate through products
        products["data"].each do |p|
          if ((p["metadata"]["code"] == Digest::SHA1.hexdigest(p.id)) && (p["type"] == "service"))
            # Product found
            # Update the name in case someone changed it
            product = Stripe::Product.update(
              p.id,
              {
                name: '6 Week Stress Release Payment Plan',
              }, stripe_account: sid)
            break
          end
        end
      end
      if (product.nil?)
        # Create a New Product
        product = Stripe::Product.create({
          name: '6 Week Stress Release Payment Plan',
          type: 'service',
        }, stripe_account: sid)
        # Update New Product's metadata
        product = Stripe::Product.update(
          product.id,
          {
            metadata: {code: Digest::SHA1.hexdigest(product.id), source: "RoR"},
          }, stripe_account: sid)
      end

      return product.id
    rescue StandardError => e
      @redirect = true
      flash[:error] = "Error: Transaction not completed. Create/Update Product failed. " + e.to_s
      redirect_to new_transaction_url and return
    end 
  end

  def check_or_create_plan(sid)
    begin
      product_id = check_or_create_product(sid)
      if (@redirect)
        return
      end
      # List the Plans
      plans = Stripe::Plan.list({limit: 10, product: product_id}, stripe_account: sid)
      plan = nil
      if (plans["data"].size != 0)
        # iterate through plans
        plans["data"].each do |p|
          if ((p["metadata"]["code"] == Digest::SHA1.hexdigest(p.id)) && 
            (p["interval"] == "week") &&
            (p["amount"] == (@transaction.price * 100).to_i))
            # Product found
            # Update the name in case someone changed it
            plan = Stripe::Plan.update(
              p.id,
              {
                nickname: 'Weekly',
              }, stripe_account: sid)
            break
          end
        end
      end
      if (plan.nil?)
        # Create a New Plan
        plan = Stripe::Plan.create({
          amount: (@transaction.price * 100).to_i,
          interval: 'week',
          product: product_id,
          nickname: 'Weekly',
          currency: 'usd',
        }, stripe_account: sid)
        # Update New Plan's metadata
        plan = Stripe::Plan.update(
          plan.id,
          {
            metadata: {code: Digest::SHA1.hexdigest(plan.id), source: "RoR"},
          }, stripe_account: sid)
      end

      return plan.id
    rescue StandardError => e
      @redirect = true
      flash[:error] = "Error: Transaction not completed. Create/Update Plan failed. " + e.to_s
      redirect_to new_transaction_url and return
    end 
  end

    # Never trust parameters from the scary internet, only allow the white list through.
  def transaction_params
    params.require(:transaction).permit(:name, :email, :phone, :start_date, :sales_rep_name, :item, :connected_account_id)
  end
end
