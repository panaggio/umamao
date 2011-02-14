# -*- coding: utf-8 -*-
require 'mechanize'
require 'rubygems'
require 'ccsv'
require 'iconv'
require 'cgi'
require 'nokogiri'


def convert_string(str)
  i = Iconv.new('UTF-8','LATIN1')
  return Nokogiri::HTML.fragment(i.iconv(str)).to_s
end

namespace :dac do
  desc "Import current DAC information"

  task :base => :environment do
    UNICAMP = University.find_by_short_name("Unicamp")
    EXCLUDE_LIST = ["51"]
  end

  def convert_program_code(code)
    (code.to_i < 10 and code[0,1] != "0") ? "0#{code}" : code
  end


  desc 'Import undergraduation programs from Unicamp into topics'
  task :import_unicamp_programs => :base do
    agent = Mechanize.new
    pagelist = agent.get('http://www.dac.unicamp.br/sistemas/catalogos/grad/catalogo2011/cursos.html')
    pagelist.links.select{|l| l.href.include?('cur')}.each do |link|
      m = link.href.match(/cur*(\d*).html/)
      if m:
       p = Program.find_or_create_by_code(convert_program_code m[1])
       p.name = link.text.gsub(/\n/, ' ')
       p.university = UNICAMP
       p.title = "#{p.name} - #{p.university.short_name}"
       p.save!
       sleep 1
      end
      print "-"
    end
    puts "\n"
  end

end
