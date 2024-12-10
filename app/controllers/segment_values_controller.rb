class SegmentValuesController < ApplicationController
    def create
    @segment = Segment.new
    @segment_value = @segment.segment_values.build
    @segment_value.id = Time.current.to_i
    @segment_value.fallback_id = @segment_value.id

    respond_to do |format|
      format.turbo_stream
    end
  end

  def destroy
    @segment_value = SegmentValue.find_or_initialize_by id: params[:id]
    @segment_value.fallback_id = params[:idx]

    respond_to do |format|
      format.turbo_stream
    end
  end

end
