json.array!(@game_assets) do |game_asset|
  json.extract! game_asset, :id, :name, :user_id
  json.url game_asset_url(game_asset, format: :json)
end
