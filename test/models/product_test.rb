require "test_helper"

class ProductTest < ActiveSupport::TestCase
  test "valid product can be saved" do
    product = Product.new(name: "Test Kit", description: "A description")
    assert product.valid?
  end

  test "product without a name is invalid" do
    product = Product.new(description: "Missing name")
    assert_not product.valid?
    assert_includes product.errors[:name], "can't be blank"
  end

  test "validate_document_types rejects disallowed extensions" do
    product = products(:one)
    # Attach a fake .exe file using an in-memory blob
    product.documents.attach(
      io: StringIO.new("fake content"),
      filename: "malware.exe",
      content_type: "application/octet-stream"
    )
    assert_not product.valid?
    assert_includes product.errors[:documents].join, "Only PDF"
  end
end
