class ClicksController < ApplicationController
	def index
    click = Click.first_or_create(total_clicks: 0)
    @total_clicks = click.total_clicks
  end

	def increment
		click = Click.first_or_create(total_clicks: 0)
		click.increment!(:total_clicks)
		render json: { total_clicks: click.total_clicks }
	end
end
