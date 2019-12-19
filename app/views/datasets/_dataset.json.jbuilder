json.extract! dataset, :id, :name, :fname, :dtype, :dpath, :active, :remark, :created_at, :updated_at
json.url dataset_url(dataset, format: :json)
