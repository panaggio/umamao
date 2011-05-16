Factory.define :topic do |t|
  t.sequence :title do |n|
    "Test topic #{n}"
  end
end
