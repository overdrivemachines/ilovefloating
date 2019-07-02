require 'stripe'
class ConnectedAccountsController < ApplicationController
  before_action :set_connected_account, only: [:show, :edit, :update, :destroy]

  # GET /connected_accounts
  # GET /connected_accounts.json
  def index
    @accounts = ConnectedAccount.all
    # list = list_of_accounts_online
    # @accounts = list_of_accounts_online["data"]
  end

  # GET /connected_accounts/1
  # GET /connected_accounts/1.json
  def show
  end

  # GET /connected_accounts/new
  def new
    @connected_account = ConnectedAccount.new
  end

  # GET /connected_accounts/1/edit
  def edit
  end

  # POST /connected_accounts
  # POST /connected_accounts.json
  def create
    @connected_account = ConnectedAccount.new(connected_account_params)

    respond_to do |format|
      if @connected_account.save
        format.html { redirect_to @connected_account, notice: 'Connected account was successfully created.' }
        format.json { render :show, status: :created, location: @connected_account }
      else
        format.html { render :new }
        format.json { render json: @connected_account.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /connected_accounts/1
  # PATCH/PUT /connected_accounts/1.json
  def update
    respond_to do |format|
      if @connected_account.update(connected_account_params)
        format.html { redirect_to @connected_account, notice: 'Connected account was successfully updated.' }
        format.json { render :show, status: :ok, location: @connected_account }
      else
        format.html { render :edit }
        format.json { render json: @connected_account.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /connected_accounts/1
  # DELETE /connected_accounts/1.json
  def destroy
    @connected_account.destroy
    respond_to do |format|
      format.html { redirect_to connected_accounts_url, notice: 'Connected account was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # GET /connected_accounts/refresh
  def refresh
    # sync local accounts with online stripe accounts
    # accounts on db
    connected_accounts = ConnectedAccount.all
    # accounts on stripe
    online_accounts = list_of_accounts_online["data"]

    # update local db based on accounts on stripe
    online_accounts.each { |online_account|
      connected_account = ConnectedAccount.where(sid: online_account.id)
      if (connected_account.nil?)
        # if account is not in the db, create a new one
        connected_account = ConnectedAccount.new
        # connected_account.connected = Date.today
      end
      connected_account.name = online_account["business_profile"]["name"]
      # connected_account.status = 
      # connected_account.balance =
      connected_account.city = online_account["business_profile"]["support_address"]["city"]
      connected_account.state = online_account["business_profile"]["support_address"]["state"]
      connected_account.postal_code = online_account["business_profile"]["support_address"]["postal_code"]
      connected_account.url = online_account["business_profile"]["url"]
      connected_account.dashboard_display_name = online_account["settings"]["dashboard"]["display_name"]
      connected_account.save
    }

    redirect_to connected_accounts_url
  end

  # GET /connected_accounts/add
  def add
    if (stripe_params[:error])
      redirect_to connected_accounts_url
    else
      # There is no error.
      # https://stripe.com/docs/connect/standard-accounts#token-request
      
      # Step 4: Fetch the user's credentials from Stripe

      uri = URI('https://connect.stripe.com/oauth/token')
      res = Net::HTTP.post_form(uri, 
        'client_secret' => Rails.application.credentials.api_key, 
        'code' => stripe_params[:code], 
        'grant_type' => 'authorization_code')

      @result = JSON.parse(res.body)
      puts @result

      if (@result.nil?)
        redirect_to connected_accounts_url, flash: { error: "No response from Stripe"} 
        return
      elsif (@result["error"])
        redirect_to connected_accounts_url, flash: { error: @result["error"] + ": " + @result["error_description"] }
        return
      elsif (@result["stripe_user_id"].nil?)
        redirect_to connected_accounts_url, flash: { error: "stripe_user_id is blank. Cannot proceed. Account was not added." }
        return
      end

      # https://stripe.com/docs/connect/oauth-reference#post-token-response
      # store response in database

      # Searching and Finding: http://www.xyzpub.com/en/ruby-on-rails/4.0/queries.html
      connected_account = ConnectedAccount.where(sid: @result["stripe_user_id"]).limit(1)[0]
      if connected_account.nil?
        connected_account = ConnectedAccount.new
      end
      connected_account.sid = @result["stripe_user_id"]
      connected_account.publishable_key = @result["stripe_publishable_key"]
      connected_account.refresh_token = @result["refresh_token"]
      connected_account.access_token = @result["accress_token"]
      connected_account.connected = Date.today

      Stripe.api_key = Rails.application.credentials.api_key
      retrieved_account = Stripe::Account.retrieve(@result["stripe_user_id"])
      
      connected_account.name = retrieved_account["business_profile"]["name"]
      # connected_account.status = 
      # connected_account.balance =
      connected_account.city = retrieved_account["business_profile"]["support_address"]["city"]
      connected_account.state = retrieved_account["business_profile"]["support_address"]["state"]
      connected_account.postal_code = retrieved_account["business_profile"]["support_address"]["postal_code"]
      connected_account.url = retrieved_account["business_profile"]["url"]
      connected_account.dashboard_display_name = retrieved_account["settings"]["dashboard"]["display_name"]


      if connected_account.save
        redirect_to connected_accounts_url, flash: { success: "Strip Account " + connected_account.dashboard_display_name + " added."} 
      else
        redirect_to connected_accounts_url, flash: { error: connected_account.errors } 
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_connected_account
      @connected_account = ConnectedAccount.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def connected_account_params
      params.require(:connected_account).permit(:sid, :name, :status, :balance, :balance, :connected)
    end

    def stripe_params
      params.permit(:scope, :code, :error, :error_description)
    end

    # Retrieving all connected accounts
    # https://stripe.com/docs/api/accounts/list?lang=curl
    def list_of_accounts_online
      Stripe.api_key = Rails.application.credentials.api_key
      return Stripe::Account.list
    end
end
