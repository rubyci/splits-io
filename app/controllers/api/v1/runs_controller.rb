class Api::V1::RunsController < ApplicationController
  before_action :set_run, only: [:show]

  def index
    unless search_params.any? { |param| params.key?(param) }
      render status: 400, json: {
        status: 400,
        message: "You must supply one of the following parameters: #{search_params.join(", ")}"
      }
      return
    end
    @runs = Run.where params.permit(search_params)
    render json: @runs.pluck(:id)
  end

  def show
    render json: {url: run_url(@run)}.merge(@run.as_json)
  end

  private

  def set_run
    @run = Run.find params[:id]
  rescue ActiveRecord::RecordNotFound
    render({
      status: 404,
      json: {
        status: 404,
        message: "Run with id '#{params[:id]}' not found. If '#{params[:id]}' isn't a numeric id, first use GET /api/v1/runs"
      }
    })
  end

  def search_params
    [:category_id, :user_id]
  end
end