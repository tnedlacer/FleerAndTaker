module PlayHelper
  def return_to_index
    link_to('mypage', {:controller => '/play', :action => :index}, :class => 'return')
  end
end
