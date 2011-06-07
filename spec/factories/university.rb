Factory.define :university do |u|
  u.sequence(:title) do |n|
    "University #{n}"
  end

  u.name do |u|
    u.title
  end

  u.short_name do |u|
    u.title
  end

  u.domains do |u|
    ["#{u.title.gsub(/\s/, "").downcase}.edu"]
  end
end
