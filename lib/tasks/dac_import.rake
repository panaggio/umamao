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
       p.title = "#{p.name} #{p.university.short_name}"
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
    t = Topic.find_by_title "#{code} (Unicamp)"

    if t and t.type == Course
      return t
    end

    if not t
      t = Course.new()
      t.title = "#{code} (Unicamp)"
    else
      Topic.set(t.id, :_type => "Course")
      t = Course.find_by_title("#{code} (Unicamp)")
    end

    t.code = code
    t.university = UNICAMP
    t.name = name
    t.prereqs = []
    t.save!
    return t
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

          course = find_or_save_course_by_code($1, $2)

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

  def find_or_save_program_by_code(code, name)
    p = Program.find_or_initialize_by_code(convert_program_code code)
    if not p.name:
      p.name = "#{code} (Unicamp)"
      p.title = p.name
      p.university = UNICAMP
      p.save!
    end
    return p
  end

  def add_registered_students_offer(a, o, token)
    page = a.get("http://www.daconline.unicamp.br/altmatr/conspub_matriculadospordisciplinaturma.do?org.apache.struts.taglib.html.TOKEN=#{token}&txtDisciplina=#{o.course.code}&txtTurma=#{o.code}&cboSubG=#{o.semester}&cboSubP=#{'0'}&cboAno=#{o.year}&btnAcao=Continuar")
    html_page = convert_string(page.body)
    regex_aluno = /<td.*>([0-9]{5,7})<\/td>.*\n.*<td[^>]*>[^\w]*(\w.*\w) *<\/td>.*\n.*.*\n.*<td[^>]*>[^\d]*(\d*)<\/td>/
    html_page.scan(regex_aluno).each do |aluno|
      s = Student.find_or_initialize_by_code(aluno[0])
      s.name = aluno[1]
      s.registered_courses << o
      s.program = find_or_save_program_by_code(aluno[2], aluno[2])
      s.save!
      o.students << s
    end
    m = html_page.match(/Docente:<\/span>[^\w]*(\w[^<]*\w)/)
    if m:
      professor = m[1]
    end
  end

  def add_registered_students(course, semester, year)
    a = Mechanize.new
    page = a.get("http://www.daconline.unicamp.br/altmatr/menupublico.do")
    token = page.body.match(/var token = "([0-9a-f]{32,32})";/)[1]
    page = a.get("http://www.daconline.unicamp.br/altmatr/conspub_situacaovagaspordisciplina.do?org.apache.struts.taglib.html.TOKEN=#{token}&txtDisciplina=#{course.code}&txtTurma=V&cboSubG=#{semester}&cboSubP=#{'0'}&cboAno=#{year}&btnAcao=Continuar")
    regex_turmas = /<td height="18" bgcolor="white" width="100" align="center" class="corpo">([A-Z1-9#])  <\/td>/
    page.body.scan(regex_turmas).each do |turma|
      o = CourseOffer.find_or_initialize_by_title("#{course.code}#{turma[0]}-#{semester}s#{year}")
      o.course = course
      o.code = turma[0]
      o.semester = semester
      o.year = year
      add_registered_students_offer a, o, token
      o.save!
      print '-'
    end
    print "\n"
  end

  def add_student_classes_by_intitute(institute, semester, year)
    a = Mechanize.new
    page = a.get("http://www.dac.unicamp.br/sistemas/horarios/grad/G#{semester}S0/#{institute }.htm", {})
    regex_disc = /<a href=".*.htm">([A-Z][A-Z ][0-9]{3,3})(.*)  /
    convert_string(page.body).scan(regex_disc).each do |course|
      c = find_or_save_course_by_code(course[0], course[1])
      add_registered_students c, semester, year
    end
  end

  desc 'Import students and classes from Unicamp into topics'
  task :import_unicamp_students_classes => :base do#, :semester, :year do |t, args|
    year = ENV['year'] || 2011
    semester = ENV['semester'] || 1
    a = Mechanize.new
    page = a.get("http://www.dac.unicamp.br/sistemas/horarios/grad/G#{semester}S0/indiceP.htm", {})
    page.body.scan(/<a href="(\w*).htm/).each do |institute|
      add_student_classes_by_intitute institute[0], semester, year
    end
  end

  desc 'Import courses from Unicamp into topics'
  task :clean => :base do
    Course.delete_all
    Program.delete_all
    ProgramCourse.delete_all
    Student.delete_all
    CourseOffer.delete_all
  end


  task :import_all => [:import_unicamp_programs, :import_unicamp_courses,
   :import_unicamp_programs_courses, :import_unicamp_students_classes  ] do
  end
end
