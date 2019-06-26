class HomeController < ApplicationController
  def index
  end

  # https://stripe.com/docs/connect/standard-accounts#redirected
  def check
    if (stripe_params[:error])
      redirect_to home_results_url
    else
      # There is no error.
      # https://stripe.com/docs/connect/standard-accounts#token-request
      # Make a post request

      uri = URI('https://connect.stripe.com/oauth/token')
      res = Net::HTTP.post_form(uri, 
        'client_secret' => stripe_params[:code], 
        'code' => '50', 
        'grant_type' => 'authorization_code')
      puts res.body

      # https://stripe.com/docs/connect/oauth-reference#post-token-response
      # store response in database

      redirect_to home_results_url
    end
  end

  def results

  end

  private
    def stripe_params
      params.permit(:scope, :code, :error, :error_description)
    end
end
