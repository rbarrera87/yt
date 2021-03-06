require 'yt/collections/base'
require 'yt/models/resumable_session'

module Yt
  module Collections
    # Provides methods to upload videos with the resumable upload protocol.
    #
    # Resources with resumable sessions are: {Yt::Models::Account accounts}.
    #
    # @see https://developers.google.com/youtube/v3/guides/using_resumable_upload_protocol
    class ResumableSessions < Base

      # Starts a resumable session by sending to YouTube the metadata of the
      # video to upload. If the request succeeds, YouTube returns a unique
      # URL to upload the video file (and eventually resume the upload).
      # @param [Integer] content_length the size (bytes) of the video to upload.
      # @param [Hash] options the metadata to add to the uploaded video.
      # @option options [String] :title The video’s title.
      # @option options [String] :description The video’s description.
      # @option options [Array<String>] :title The video’s tags.
      # @option options [Integer] :category_id The video’s category ID.
      # @option options [String] :privacy_status The video’s privacy status.
      def insert(content_length, options = {})
        @headers = headers_for content_length
        body = {}

        snippet = options.slice :title, :description, :tags, :category_id
        snippet[:categoryId] = snippet.delete(:category_id) if snippet[:category_id]
        body[:snippet] = snippet if snippet.any?

        status = options[:privacy_status]
        body[:status] = {privacyStatus: status} if status

        do_insert body: body, headers: @headers
      end

    private

      def attributes_for_new_item(data)
        {url: data['Location'], headers: @headers, auth: @auth}
      end

      def insert_params
        super.tap do |params|
          params[:response_format] = nil
          params[:path] = '/upload/youtube/v3/videos'
          params[:params] = {part: 'snippet,status', uploadType: 'resumable'}
        end
      end

      def headers_for(content_length)
        {}.tap do |headers|
          headers['x-upload-content-length'] = content_length
          headers['X-Upload-Content-Type'] = 'video/*'
        end
      end

      # The result is not in the body but in the headers
      def extract_data_from(response)
        response.header
      end
    end
  end
end