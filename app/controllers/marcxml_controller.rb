# frozen_string_literal: true

# Given a barcode, returns a catkey by looking in searchworks
class MarcxmlController < ApplicationController
  def catkey
    marcxml = MarcxmlResource.find_by(barcode: params[:barcode])

    render plain: marcxml.catkey
  end
end
