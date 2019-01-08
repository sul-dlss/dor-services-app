class VersionsController < ApplicationController
  before_action :load_item

  def create
    Dor::VersionService.open(@item)
    render plain: @item.current_version
  end

  def current
    render plain: @item.current_version
  end

  def close_current
    request.body.rewind
    body = request.body.read
    if body.strip.empty?
      sym_params = nil
    else
      raw_params = JSON.parse body
      sym_params = Hash[raw_params.map { |(k, v)| [k.to_sym, v] }]
      if sym_params[:significance]
        sym_params[:significance] = sym_params[:significance].to_sym
      end
    end
    Dor::VersionService.close(@item, sym_params)
    render plain: "version #{@item.current_version} closed"
  end
end
