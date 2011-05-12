Factory.define :vote do |v|
  v.value 1
  v.association :group
  v.association :user
  v.association :voteable, :factory => :answer
end

Factory.define :upvote, :parent => :vote do end

Factory.define :downvote, :parent => :vote do |v|
  v.value -1
end
