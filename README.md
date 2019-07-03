# DASHBOARD for ilovefloating.com

- Devise Login
- Clients Section 
  - A list of your Stripe Platform Account’s Connected Accounts.
  - Connected Accounts can be added, edited and removed. 
  - The Application Fee charged to the Connected Accounts can be edited as a percentage.

## Domain Model
Run `rake generate_erd` to regenerate (must have graphvis).
![](/erd.png)

## Configuration and System Dependencies
- Ubuntu 18.04.2 LTS
- ruby 2.6.2p47 (2019-03-13 revision 67232) [x86_64-linux]
- Rails 5.2.3

## OAuth link
https://stripe.com/docs/connect/standard-accounts
client_id - ca_FEO5gO2qc2qBntLsQ8J3Okp7w3cMTONy
redirect_uri - 
authorize_url - https://connect.stripe.com/oauth/authorize?response_type=code&client_id=ca_FEO5gO2qc2qBntLsQ8J3Okp7w3cMTONy&scope=read_write&redirect_uri=


## Deployment Updates
```
git pull
bundle install --deployment --without development test
bundle exec rake assets:precompile db:migrate RAILS_ENV=production
```
- Restart Services:
```sh
passenger-config restart-app $(pwd)
sudo service nginx restart
```

## Nginx configuration file
File: /etc/nginx/sites-enabled/bitshares_upload.conf
```
server {
    listen 80;
    server_name dashboard.;

    # Tell Nginx and Passenger where your app's 'public' directory is
    root /var/www/ilovefloating/code/public;

    # set client body size to 20M #
    client_max_body_size 20M;

    # Turn on Passenger
    passenger_enabled on;
    passenger_ruby /home/dynamic/.rvm/gems/ruby-2.5.3/wrappers/ruby;
}
```

## Using SSL with Passenger in Production

- Certbot - https://certbot.eff.org/lets-encrypt/ubuntuxenial-nginx
`
$ sudo apt-get update
$ sudo apt-get install software-properties-common
$ sudo add-apt-repository ppa:certbot/certbot
$ sudo apt-get update
$ sudo apt-get install python-certbot-nginx
$ sudo certbot --nginx
`
- Test SSL - https://www.ssllabs.com/ssltest/analyze.html?d=www.site.com

## NGINX and Passenger Debug
- service nginx configtest
- /usr/sbin/nginx -t



## References
- AJAX
  - https://github.com/overdrivemachines/TaskSnail/blob/master/app/controllers/tasks_controller.rb
  - https://launchschool.com/blog/the-detailed-guide-on-how-ajax-works-with-ruby-on-rails
  - https://rubyplus.com/articles/4211-Using-Ajax-and-jQuery-in-Rails-5-Apps
- Understanding Charges - https://stripe.com/docs/connect/charges
- Direct Charges - https://stripe.com/docs/connect/direct-charges


## How to Connet to Your Remote Server?
- Shortcuts to SSH clients - https://askubuntu.com/questions/754450/shortcuts-to-ssh-clients
- How To Configure SSH Key-Based Authentication on a Linux Server - https://www.digitalocean.com/community/tutorials/how-to-configure-ssh-key-based-authentication-on-a-linux-server

## Stripe API
- List connected accounts: https://stripe.com/docs/api/accounts/list



Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
