# まずタグを全消し
Tag.delete_all

# 再登録（常駐3個）
%w[#アガる曲 #チルタイム #青春ソング].each do |name|
  Tag.create!(name: name, active: true)
end