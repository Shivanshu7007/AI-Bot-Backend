class Api::ProductsController < ApplicationController
  include Rails.application.routes.url_helpers

  def index
    products = Product.all

    render json: products.map { |p|
      {
        id: p.id,
        name: p.name,
        description: p.description,
        image_url: p.image.attached? ? url_for(p.image) : nil
      }
    }
  end
end
