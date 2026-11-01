require "rails_helper"

RSpec.describe "Board themes" do
  let(:assets) { Rails.root.join("app/assets") }

  # Asset URLs like url("/fonts/lora.css") are logical paths, found in any of the assets folders
  def asset?(logical_path)
    %w[stylesheets fonts images].any? { |folder| assets.join(folder, logical_path).file? }
  end

  def urls(css)
    css.read.scan(%r{url\("/([^"]+)"\)}).flatten
  end

  it "has a stylesheet for each theme but Classic, and no others" do
    stylesheets = assets.join("stylesheets/themes").children.map { |file| file.basename(".css").to_s }

    expect(stylesheets).to match_array(Event::THEMES.keys.excluding("classic"))
  end

  Event::THEMES.keys.excluding("classic").each do |theme|
    it "finds every font and image the #{theme} theme uses" do
      theme_urls = urls(assets.join("stylesheets/themes/#{theme}.css"))
      font_stylesheets = theme_urls.select { |path| path.end_with?(".css") && asset?(path) }
      fonts = font_stylesheets.flat_map { |path| urls(assets.join("stylesheets", path)) }

      expect(theme_urls).to all(satisfy { |path| asset?(path) })
      expect(fonts).to be_present.and all(satisfy { |path| asset?(path) })
    end
  end

  it "keeps each font's license with it" do
    font_folders = assets.join("fonts").children.select(&:directory?)

    expect(font_folders.map { |folder| folder.join("OFL.txt") }).to all(be_file)
  end
end
