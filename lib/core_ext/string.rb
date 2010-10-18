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

end

