class ImageProcessor
  MAX_DIMENSION = 512
  QUALITY = 85
  FORMAT = "webp"

  # Processes an uploaded file (ActionDispatch::Http::UploadedFile or similar)
  # Returns a Tempfile with the optimized WebP image.
  def self.call(file)
    new(file).process
  end

  def initialize(file)
    @file = file
  end

  def process
    pipeline = ImageProcessing::Vips
      .source(@file)
      .resize_to_limit(MAX_DIMENSION, MAX_DIMENSION)
      .convert(FORMAT)
      .saver(quality: QUALITY, strip: true)

    pipeline.call
  end
end
