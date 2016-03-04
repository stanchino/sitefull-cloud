require 'google/apis/compute_v1'

RSpec.configure do |config|
  config.before(:each) do
    zones = double(items: [double(id: 'us-central1-a', name: 'us-central1-a')])
    allow_any_instance_of(::Google::Apis::ComputeV1::ComputeService).to receive(:list_zones).and_return(zones)

    images = double(items: [double(id: 'image-id-1', name: 'Image 1', self_link: 'image-id-1', deprecated: nil),
                            double(id: 'image-id-2', name: 'Image 2', self_link: 'image-id-2', deprecated: double(state: 'DEPRECATED')),
                            double(id: 'image-id-3', name: 'Image 3', self_link: 'image-id-3', deprecated: double(state: 'NON-DEPRECATED'))])
    allow_any_instance_of(::Google::Apis::ComputeV1::ComputeService).to receive(:list_images).and_return(images)

    machine_types = double(items: [double(id: 'machine-type-1', name: 'machine-type-1', self_link: 'machine-type-1'),
                                   double(id: 'machine-type-2', name: 'machine-type-2', self_link: 'machine-type-2')])
    allow_any_instance_of(::Google::Apis::ComputeV1::ComputeService).to receive(:list_machine_types).and_return(machine_types)
  end
end
