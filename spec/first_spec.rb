require "rails_helper"

RSpec.describe "creates and object in the database" do
  before :each do
    product = Product.new
    product.name = "New Product"
    product.save
  end

  it "persists in the database" do
    product = Product.find_by(name: "New Product")
    expect(product.name).to eq("New Product")
  end
end
