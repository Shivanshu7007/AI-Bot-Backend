ActiveAdmin.register Product do
  permit_params :name, documents: []

  # ===============================
  # QR DOWNLOAD MEMBER ACTION
  # ===============================
  member_action :qr, method: :get do
    product = Product.find(params[:id])

    require 'rqrcode'
    require 'rqrcode_png'

    qr = RQRCode::QRCode.new(
      "https://yourdomain.com/chat?product_id=#{product.id}"
    )

    png = qr.as_png(
      bit_depth: 1,
      border_modules: 4,
      color_mode: ChunkyPNG::COLOR_GRAYSCALE,
      size: 300
    )

    send_data png.to_s,
              type: 'image/png',
              disposition: 'attachment',
              filename: "product_#{product.id}_qr.png"
  end

  # ===============================
  # QR BUTTON ON SHOW PAGE
  # ===============================
  action_item :download_qr, only: :show do
    link_to "Download QR Code",
            qr_admin_product_path(resource)
  end

  # ===============================
  # INDEX
  # ===============================
  index do
    selectable_column
    id_column
    column :name
    column "Documents" do |product|
      product.documents.map do |doc|
        link_to doc.filename, url_for(doc)
      end.join(", ").html_safe
    end
    column :created_at
    column :updated_at
    actions
  end

  # ===============================
  # FORM
  # ===============================
  form do |f|
    f.inputs "Product Details" do
      f.input :name
      f.input :documents, as: :file, input_html: { multiple: true }
    end
    f.actions
  end

  # ===============================
  # SHOW PAGE
  # ===============================
  show do
    attributes_table do
      row :name

      row :documents do |product|
        product.documents.map do |doc|
          link_to doc.filename, url_for(doc)
        end
      end

      row "QR Code Preview" do |product|
        image_tag qr_admin_product_path(product),
                  size: "150x150"
      end
    end
  end
end
