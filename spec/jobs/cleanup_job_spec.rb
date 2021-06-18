# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CleanupJob, type: :job do
  context 'when we write tests' do
    xit 'it works'
  end

  #   context 'when successful' do
  #     before do
  #       allow(CleanupService).to receive(:cleanup_by_druid)
  #       allow(CleanupJob).to receive(:set).and_return(job)
  #    end
  #     it 'returns 200' do
  #       delete "/v1/objects/#{object_id}/workspace",
  #     it 'queus job and returns 204' do
  #       delete "/v1/objects/#{druid}/workspace",
  #             headers: { 'Authorization' => "Bearer #{jwt}" }
  #       expect(CleanupService).to have_received(:cleanup_by_druid).with(object_id)
  #       expect(CleanupJob).to have_received(:set).with(queue: :default)
  #       expect(job).to have_received(:perform_later)
  #         .with(druid: druid, background_job_result: BackgroundJobResult, workflow: 'accessionWF')
  #      expect(response).to have_http_status(:no_content)
  #    end
  #  end

  #   context "when the directory doesn't exist" do
  #     before do
  #       allow(CleanupService).to receive(:cleanup_by_druid)
  #         .and_raise(Errno::ENOENT, 'dir_s_rmdir - /dor/workspace/aa/222')
  #     end

  #     it 'returns JSON-API error' do
  #       delete "/v1/objects/#{object_id}/workspace",
  #              headers: { 'Authorization' => "Bearer #{jwt}" }
  #       expect(response).to have_http_status(:unprocessable_entity)
  #       expect(response.body).to eq(
  #         '{"errors":[{"status":"422","title":"Unable to remove directory",' \
  #         '"detail":"No such file or directory - dir_s_rmdir - /dor/workspace/aa/222"}]}'
  #       )
  #     end
  #   end

  #   context 'when the directory is not empty' do
  #     before do
  #       allow(CleanupService).to receive(:cleanup_by_druid)
  #         .and_raise(Errno::ENOTEMPTY, 'dir_s_rmdir - /dor/assembly/pw/569/pw/4290')
  #     end

  #     it 'returns JSON-API error' do
  #       delete "/v1/objects/#{object_id}/workspace",
  #              headers: { 'Authorization' => "Bearer #{jwt}" }
  #       expect(response).to have_http_status(:unprocessable_entity)
  #       expect(response.body).to eq(
  #         '{"errors":[{"status":"422","title":"Unable to remove directory",' \
  #         '"detail":"Directory not empty - dir_s_rmdir - /dor/assembly/pw/569/pw/4290"}]}'
  #       )
  #     end
  #  end
end
