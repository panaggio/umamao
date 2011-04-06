# -*- coding: utf-8 -*-
require 'mechanize'
require 'rubygems'
require 'ccsv'
require 'iconv'
require 'cgi'
require 'nokogiri'

# Fix encoding problems
def convert_string(str)
  i = Iconv.new('UTF-8','LATIN1')
  return Nokogiri::HTML.fragment(i.iconv(str)).to_s
end

namespace :jupiterweb do

  task :base => :environment do
    USP = University.find_by_short_name("USP")
  end

  def find_or_create_course(code, name, summary='')
    t = Topic.find_by_title("#{code} (USP)")
    if t && t.type == Course && t.name
      return t
    end

    if t.nil?
      t = Course.new
      t.title = "#{code} (USP)"
    elsif t.type == Topic
      Topic.set(t.id, :_type => "Course")
      t = Course.find_by_id(t.id)
    end

    t.name = name
    t.code = code
    t.university = USP
    t.summary = summary
    t.save!
    return t
  end

  def add_prereqs(course)
    # Retrieve course prereqs
    agent = Mechanize.new
    page = convert_string(
      agent.get(
        "http://sistemas2.usp.br/jupiterweb/listarCursosRequisitos?coddis=#{course.code}"
       ).body).gsub("\n", "").gsub("\r", "")
    if !page || page.include?("Disciplina não tem requisitos")
      return nil
    end
    page.scan(/(\w\w\w\d\d\d\d)[ \n]*- ([^<]*)/).each do |pre_req|
      course_prereq = find_or_create_course(pre_req[0], pre_req[1])
      if !course.prereq_ids.include? course_prereq.id
        course.prereq_ids << course_prereq.id
      end
    end
  end

  def save_course_usp(code, name, summary, url)
    c = find_or_create_course(code, name, summary)
    add_prereqs(c)

    links_number = 0

    links = []
    pre_req_links = ''

    if c.prereqs.present?
      pre_reqs = []
      c.prereqs.each do |r|
        if r.code.present?
          links_number = links_number + 1
          pre_reqs << "[#{r.code}][#{links_number}]"
          links << "\n  [#{links_number}]: /topics/#{r.code}-USP"
        end
      end

      pre_req_links = "**Pré-requisitos**: " + pre_reqs.join(',')
    end

    links_number = links_number + 1
    c.description = "# #{c.code}: #{c.name}\n\n"
    c.description << pre_req_links + "\n\n" + (c.summary || '')
    c.description << "[Veja mais informações sobre a disciplina][#{links_number}]\n\n"
    links << "\n  [#{links_number}]: http://sistemas2.usp.br/jupiterweb/#{url}"
    c.description << links.join()
    c.save!
  end

  def parse_course_page(page, url, institute_code)
      page = convert_string(page.gsub!("\n", ""))
      m = page.match(/Disciplina: (\w\w\w\d\d\d\d) - ([^<]*)/)
      unless m
        return nil
      end

      code = m[1]
      name = m[2]

      begin
      # Retrieve content between two titles and remove html information inside
      # it. At the end only the summary text will be present.
      summary = page.split("<b>Programa</b>")[1].split("<b>Avaliação</b>")[0].
                     gsub(/<.?br>/, "  \n").gsub(/<[^>]*>/, "").gsub(/^[ ]*/, "").
                     strip
      rescue
        puts code, name
      end
      puts [institute_code, code, name].join(", ")
      save_course_usp code, name, summary, url
  end

  def get_courses(agent, institute_code)
    agent.page.links.select{|l| l.href.include?("obterDisciplina")}.each do |link|
      link.click
      parse_course_page(agent.page.body, link.href, institute_code)
      sleep 0.5
    end
  end

  desc 'Import courses from USP into topics'
  task :import_usp_courses, [:last_institute_code] => :base do |t, args|
    puts "Import USP courses"
    agent = Mechanize.new
    page = agent.get("http://sistemas2.usp.br/jupiterweb/jupColegiadoLista?tipo=D")

    last_institute_code = args[:last_institute_code]
    import_started = !last_institute_code

    # For each institute page
    intitute_links = page.links.select{|l| l.href.include?('jupColegiadoMenu.jsp')}
    intitute_links.each do |institute_link|
      import_started = import_started ||
        institute_link.href.include?("codcg=#{last_institute_code}&")
      next unless import_started

      institute_code = institute_link.href.match(/codcg=(\d*)/)[1]
      institute_link.click

      # Intermediate link
      course_list = agent.page.links.select do |l|
        l.href.include?('jupDisciplinaLista')
      end
      course_list[0].click

      # Verify if courses are categorized by name
      courses_by_letter = agent.page.links.select{|l| l.href.include?("letra=")}
      if courses_by_letter.present?
        courses_by_letter.each do |link_disc_list|
          link_disc_list.click
          get_courses(agent, institute_code)
        end
      else
        get_courses(agent, institute_code)
      end

    end
    puts "\n"
  end

end
