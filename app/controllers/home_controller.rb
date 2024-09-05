# app/controllers/home_controller.rb
class HomeController < ApplicationController
  def index
    @click = Click.first_or_create(total_clicks: 0)
  end
end
