twitter_auth_yml = YAML.load_file(Rails.root.join("config/twitter_auth.yml"))[Rails.env]
Twitter.configure do |config|
  config.consumer_key = twitter_auth_yml["oauth_consumer_key"]
  config.consumer_secret = twitter_auth_yml["oauth_consumer_secret"]
end