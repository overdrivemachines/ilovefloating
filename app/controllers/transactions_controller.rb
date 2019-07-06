class TransactionsController < ApplicationController
  before_action :set_transaction, only: [:show, :edit, :update, :destroy]

  # GET /transactions
  # GET /transactions.json
  def index
    @transactions = Transaction.all
  end

  # GET /transactions/1
  # GET /transactions/1.json
  def show
  end

  # GET /transactions/new
  def new
    @transaction = Transaction.new
    # Temp Data
    # @transaction.name = "Dipen Chauhan"
    # @transaction.email = "get.dipen@gmail.com"
    # @transaction.phone = "(530)566-3038"
    # @transaction.sales_rep_name = "John Smith"

  end

  # GET /transactions/1/edit
  def edit
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
      @transaction.item = "6 Weeks"
      @transaction.price = 447.0
    elsif (transaction_params[:item] == "1")
      @transaction.item = "Single Float"
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
      Stripe.api_key = Rails.application.credentials.api_key

      begin
        charge = Stripe::Charge.create({
          amount: (@transaction.price * 100).to_i,
          currency: "usd",
          source: stripe_token,
          application_fee_amount: (application_fee * 100).to_i,
        }, stripe_account: connected_account.sid)
      rescue StandardError => e
        flash[:error] = "Error: Transaction not completed. " + e
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

  # PATCH/PUT /transactions/1
  # PATCH/PUT /transactions/1.json
  def update
    respond_to do |format|
      if @transaction.update(transaction_params)
        format.html { redirect_to @transaction, notice: 'Transaction was successfully updated.' }
        format.json { render :show, status: :ok, location: @transaction }
      else
        format.html { render :edit }
        format.json { render json: @transaction.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /transactions/1
  # DELETE /transactions/1.json
  def destroy
    @transaction.destroy
    respond_to do |format|
      format.html { redirect_to transactions_url, notice: 'Transaction was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_transaction
      @transaction = Transaction.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def transaction_params
      params.require(:transaction).permit(:name, :email, :phone, :start_date, :sales_rep_name, :item, :connected_account_id)
    end
end
