Factory.sequence :affiliation_number do |n|
  n
end

Factory.define :affiliation do |a|
  a.association :university

  a.email do |a|
    n = FactoryGirl.find(:affiliation_number).run
    "#{n}@#{a.university.domains.first}"
  end
end
