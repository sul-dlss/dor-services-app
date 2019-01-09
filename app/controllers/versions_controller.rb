class VersionsController < ApplicationController
  before_action :load_item

  def create
    Dor::VersionService.open(@item, open_params)
    render plain: @item.current_version
  end

  def current
    render plain: @item.current_version
  end

  def close_current
    Dor::VersionService.close(@item, close_params)
    render plain: "version #{@item.current_version} closed"
  end

  private

  def open_params
    params.permit(
      :assume_accessioned,
      :create_workflows_ds,
      vers_md_upd_info: [
        :description,
        :opening_user_name,
        :significance
      ]
    ).to_h.deep_symbolize_keys
  end

  def close_params
    symbolized_hash = params.permit(
      :description,
      :significance,
      :start_accession,
      :version_num
    ).to_h.symbolize_keys
    # Downstream code expects the significance value to be a symbol
    symbolized_hash[:significance] = symbolized_hash[:significance].to_sym if symbolized_hash.key?(:significance)
    symbolized_hash
  end
end
