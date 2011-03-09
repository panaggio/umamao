# -*- coding: utf-8 -*-
require 'jcode'

class String
  # Replaces special characters in a string so that it may be used as
  # part of a 'pretty' URL.  This was copied from Rails, but maintains
  # capitalized letters and doesn't remove accented characters.
  #
  # ==== Examples
  #
  #   class Person
  #     def to_param
  #       "#{id}-#{name.parameterize}"
  #     end
  #   end
  #
  #   @person = Person.find(1)
  #   # => #<Person id: 1, name: "Donald E. Knuth">
  #
  #   <%= link_to(@person.name, person_path(@person)) %>
  #   # => <a href="/person/1-Donald-E-Knuth">Donald E. Knuth</a>
  def parameterize(sep = '-')
    # Turn unwanted chars into the separator
    parameterized_string = self.dup.gsub(/[^\w\-_]+/i, sep)
    unless sep.nil? || sep.empty?
      re_sep = Regexp.escape(sep)
      # No more than one of the separator in a row.
      parameterized_string.gsub!(/#{re_sep}{2,}/, sep)
      # Remove leading/trailing separator.
      parameterized_string.gsub!(/^#{re_sep}|#{re_sep}$/i, '')
    end
    parameterized_string
  end

  def downcase_with_accents
     norm = self.downcase
     norm.tr!('ÁÉÍÓÚÇ', 'áéíóúç')
     norm.tr!('ÀÈÌÒÙ', 'àèìòù')
     norm.tr!('ÄËÏÖÜ', 'äëïöü')
     norm.tr!('ÂÊÎÔÛ', 'âêîôû')
     norm.tr!('ÃẼĨÕŨ', 'ãẽĩõũ')
     norm
   end

  def downcase_with_accents!
     self.downcase!
     self.tr!('ÁÉÍÓÚÇ', 'áéíóúç')
     self.tr!('ÀÈÌÒÙ', 'àèìòù')
     self.tr!('ÄËÏÖÜ', 'äëïöü')
     self.tr!('ÂÊÎÔÛ', 'âêîôû')
     self.tr!('ÃẼĨÕŨ', 'ãẽĩõũ')
   end

  def phrase_ucfirst
	a = self.split(' ').map {|x| if x == "da" or x == "de" or x == "do" then x else x.capitalize end}
	a.join(' ')
  end

  def capitalize_with_accents
    self[0..0] + self[1..-1].downcase
  end

  # Handles (almost) only portuguese accented letters.
  def strip_accents
    norm = self.clone
    norm.tr!("ÁÉÍÓÚ", "AEIOU")
    norm.tr!("áéíóú", "aeiou")
    norm.tr!("ÂÊÎÔÛ", "AEIOU")
    norm.tr!("âêîôû", "aeiou")
    norm.tr!("ÃẼĨÕŨ", "AEIOU")
    norm.tr!("ãẽĩõũ", "aeiou")
    norm.tr!("Çç", "Cc")
    norm
  end

end

