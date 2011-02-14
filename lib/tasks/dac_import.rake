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

  def save_course_dac(course)
    return if not course
    course.summary = course.code

    pre_req_links = (not course.prereqs.empty?) ?
      "<strong>Pré-requisitos</strong>: " + course.prereqs.map { |r|
    r.code ? "<a href=\"/topics/#{r.code.tr(' ', '-')}-Unicamp\">#{r.code}</a>" : ''
    }.join(', ') + "\n\n" : ''

    course.description = "# #{course.code}: #{course.name}\n\n"
    course.description << pre_req_links + (course.summary || '')
    course.save!
  end

  def find_or_save_course_by_code(code, name)
    c = Course.find_or_create_by_code(code)
    if not c.title:
      c.title = "#{code} (Unicamp)"
      c.university = UNICAMP
      c.name = name
      c.save!
    end
    return c
  end

  desc 'Import courses from Unicamp into topics'
  task :import_unicamp_courses => :base do#, :year do |t, args|
    year = ENV['year'] || 2011
    agent = Mechanize.new
    pagelist = agent.get("http://www.dac.unicamp.br/sistemas/catalogos/grad/catalogo#{year}/ementas/")

    pagelist.links.select{|l| l.href.include?('todas')}.each do |link|
      link.click

      # the first 4 items are just page header information
      text_items = agent.page.search('font[size="-1"]').map{|el| el.text.strip}[4..-1]
      course = nil
      text_items.each do |item|
        case item
        when /^(\w[\w ]\d+) (.*)/ # e.g.: AD012 Ateliê de Prática em Dança II
          if course:
            save_course_dac course
          end

          course = Course.find_or_initialize_by_code($1)
          course.title = "#{course.code} (Unicamp)"
          course.name = $2
          course.university = UNICAMP

        when /^Pré-Req\.: (.*)/ # e.g.: Pré-Req.: AD011 F 429
          $1.scan(/([A-Za-z]+\d+)|([fF] \d+)/).each do |pre_req|
            if $1
              course.prereqs << find_or_save_course_by_code($1, $1)
            end
          end
        when /^Ementa: (.*)/
          course.save!
        end
      end
      save_course_dac course

      print '-' # progress indicator

      sleep 1
    end
    puts "\n"
  end

  desc 'Import undergrad programs\' courses from Unicamp'
  task :import_unicamp_programs_courses => :base do#, :year  do |t, args|
    year = ENV['year'] || 2011
    agent = Mechanize.new
    Program.all.select{|p| p.university.id == UNICAMP.id}.each do |program|
      next if EXCLUDE_LIST.include? program.code
      pagelist = agent.get("http://www.dac.unicamp.br/sistemas/catalogos/grad/catalogo#{year}/cursos/sug#{program.code}.html")
      semesters = pagelist.body.split("Semestre")
      indexSemester = 0
      semesters.each do |semester|
        convert_string(semester).scan(/<a href="..\/ementas\/todas.*">(\w[\w ]\d\d\d)/).each do |course|
          c = find_or_save_course_by_code(course[0], course[0])
          pc = ProgramCourse.new()
          pc.semester = indexSemester
          pc.year_catalog = year
          pc.course = c
          pc.program = program
          pc.save
        end
        indexSemester = indexSemester + 1
      end
      print "-"
    end
    puts "\n"
  end
end
