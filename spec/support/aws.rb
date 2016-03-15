Aws.config[:stub_responses] = true

RSpec.configure do |config|
  config.before(:each) do
    regions = double(regions: [double(region_name: 'us-east-1')])
    allow_any_instance_of(Aws::EC2::Client).to receive(:describe_regions).and_return(regions)

    images = double(images: [double(image_id: 'image-id', name: 'Image', image_owner_alias: nil), double(image_id: 'image-id', name: 'Image', image_owner_alias: 'amazon_marketplace')])
    allow_any_instance_of(Aws::EC2::Client).to receive(:describe_images).and_return(images)
  end
end
