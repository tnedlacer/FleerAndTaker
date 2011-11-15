module FunctionalTestExt
  private
    def tlogin(user = nil)
      @user = user
      @user ||= Factory(:twitter_oauth_user)
      request.session[:user_id] = @user.id
    end
end
