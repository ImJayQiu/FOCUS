json.extract! wiki_page, :id, :chapter, :heading1, :heading2, :heading3, :title, :content, :image1, :image2, :created_at, :updated_at
json.url wiki_page_url(wiki_page, format: :json)
