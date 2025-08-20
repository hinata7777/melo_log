%w[夏に聴きたい曲 元気が出る曲 落ち着く曲].each do |n|
  Tag.find_or_create_by!(name: n) do |t|
    t.active = true
  end
end