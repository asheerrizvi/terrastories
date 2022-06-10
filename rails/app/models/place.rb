class Place < ApplicationRecord
  MEDIA_PATH = Rails.env.test? ? 'spec/fixtures/media' : 'import/media'

  require 'csv'
  belongs_to :community
  has_and_belongs_to_many :stories
  has_one_attached :photo
  has_one_attached :name_audio
  validate :photo_format
  validates :name_audio, blob: { content_type: ['audio/mpeg', 'audio/wav'] }
  validates :lat, numericality: { greater_than_or_equal_to:  -90, less_than_or_equal_to:  90 }, allow_blank: true
  validates :long, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_blank: true
  has_many :interview_stories, class_name: "Story", foreign_key: "interview_location_id"

  attr_reader :point_geojson

  def self.import_csv(filename, community)
    ApplicationController.helpers.csv_importer(filename, self, community)
  end

  def photo_format
    return unless photo.attached?
    return if photo.blob.content_type.start_with? 'image/'
    photo.purge_later
    errors.add(:photo, 'needs to be an image')
  end

  def photo_url
    if photo.attached?
      Rails.application.routes.url_helpers.rails_blob_path(photo, only_path: true)
    end
  end

  def name_audio_url
    if name_audio.attached?
      Rails.application.routes.url_helpers.rails_blob_path(name_audio, only_path: true)
    end
  end

  def point_geojson
    RGeo::GeoJSON.encode geojson
  end

  def self.export_sample_csv
    headers = %w{ name type_of_place description region long lat media }

    CSV.generate(headers: true) do |csv|
      csv << headers
    end
  end

  def static_map_url
    geojson = RGeo::GeoJSON.encode(
      RGeo::GeoJSON::Feature.new(
        RGeo::Cartesian.factory.point(long, lat),
        id,
        "marker-symbol": name[0].downcase
      )
    ).to_json

    "https://api.mapbox.com/styles/v1/mapbox/light-v10/static/pin-l+000(#{long},#{lat})/#{long},#{lat},#{community.theme.zoom},#{community.theme.bearing},#{community.theme.static_map_pitch}/350x350?access_token=#{community.theme.mapbox_access_token}"
  end


  private

  def geojson
    # todo: add extra data here to pass to map about points
    RGeo::GeoJSON::Feature.new(
      RGeo::Cartesian.factory.point(long, lat),
      id,
      name: name,
      description: description,
      region: region,
      type_of_place: type_of_place,
      photo_url: photo_url,
      name_audio_url: name_audio_url,
      stories: stories
    )
  end

end

# == Schema Information
#
# Table name: places
#
#  id            :bigint           not null, primary key
#  description   :string
#  lat           :decimal(10, 6)
#  long          :decimal(10, 6)
#  name          :string
#  region        :string
#  type_of_place :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  community_id  :integer
#
