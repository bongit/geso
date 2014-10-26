# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

User.create(id: 1, name: "BON", email: "celendipity@gmail.com", admin: true, password: "password", password_confirmation: "password")

m_categories = ["グラフィック素材","プログラム素材","音素材"]
for m in 1..3 do
	MainCategory.create(id: m, name: m_categories[(m-1)])
end

s_categories = ["キャラクター", "イラスト", "アイテム・オブジェクト","背景","マップ","エフェクト","インターフェース・アイコン",
	"ゲームプログラム","ライブラリ","コード・クラス等",
	"効果音","BGM","音声","歌"]
for s in 1..7 do
	SubCategory.create(id: s, name: s_categories[(s-1)], parent_id: 1)
end
for s in 8..10 do
	SubCategory.create(id: s, name: s_categories[(s-1)], parent_id: 2)
end
for s in 11..14 do
	SubCategory.create(id: s, name: s_categories[(s-1)], parent_id: 3)
end

genres = ["アクション","シューティング","格闘","ロールプレイング","シミュレーション",
	"アドベンチャー","パズル","教育","スポーツ","レース"]

for g in 1..10 do
	Genre.create(id: g, name: genres[(g-1)])
end

licenses = ["CC BY","CC BY-SA","CC BY-ND","CC BY-NC","CC BY-NC-SA","CC BY-NC-ND"]
for l in 1..6 do
	License.create(id: l, name: licenses[(l-1)])
end










