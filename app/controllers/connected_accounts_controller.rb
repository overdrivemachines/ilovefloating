class ConnectedAccountsController < ApplicationController
  before_action :set_connected_account, only: [:show, :edit, :update, :destroy]

  # GET /connected_accounts
  # GET /connected_accounts.json
  def index
    @connected_accounts = ConnectedAccount.all
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

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_connected_account
      @connected_account = ConnectedAccount.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def connected_account_params
      params.require(:connected_account).permit(:sid, :name, :status, :balance, :balance, :connected)
    end
end
