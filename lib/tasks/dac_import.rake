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

namespace :dac do
  desc "Import current DAC information"

  task :base => :environment do
    UNICAMP = University.find_by_short_name("Unicamp")
    # Courses like 'Cursão' do not exist really
    COURSE_EXCLUDE_LIST = ["51"]
  end

  # Fix "1" to "01" like DAC main page
  def convert_academic_program_code(code)
    (code.to_i < 10 and code[0,1] != "0") ? "0#{code}" : code
  end

  desc 'Import undergraduation academic_programs from Unicamp into topics'
  task :import_unicamp_academic_programs => :base do
    puts "Importing Unicamp academic_programs"

    #Get DAC page course and finds/creates them
    agent = Mechanize.new
    pagelist = agent.get('http://www.dac.unicamp.br/sistemas/catalogos/grad/catalogo2011/cursos.html')
    pagelist.links.select{|l| l.href.include?('cur')}.each do |link|
      m = link.href.match(/cur*(\d*).html/)
      if m:
       p = AcademicProgram.find_or_initialize_by_code(convert_academic_program_code m[1])
       p.name = link.text.gsub(/\n/, ' ')
       p.university = UNICAMP
       p.title = "#{p.name} (#{p.university.short_name})"
       p.save!
       sleep 1
      end
      print "-"
    end
    puts "\n"
  end

  # Save the course, updating its topic description
  def save_course_dac(course)
    return if not course

    pre_req_links = (not course.prereqs.empty?) ?
      "<strong>Pré-requisitos</strong>: " + course.prereqs.map { |r|
    r.code ? "<a href=\"/topics/#{r.code.tr(' ', '-')}-Unicamp\">#{r.code}</a>" : ''
    }.join(', ') + "\n\n" : ''

    course.description = "# #{course.code}: #{course.name}\n\n"
    course.description << pre_req_links + (course.summary || '')
    course.save!
  end

  # Find if there is already a topic or course, otherwise create one
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
  task :import_unicamp_courses => :base do
    puts "Import Unicamp courses"
    year = ENV['year'] || 2011

    # Search all courses in DAC webpages and create or update its information
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
          course.summary = $1
        end
      end
      save_course_dac course

      print '-' # progress indicator

      sleep 1
    end
    puts "\n"
  end

  desc 'Import Unicamp undergrad academic_programs\' catalog'
  task :import_unicamp_academic_programs_catalog => :base do
    puts "Import Unicamp academic_programs' courses"
    year = ENV['year'] || 2011
    agent = Mechanize.new

    AcademicProgram.all.select{|p| p.university.id == UNICAMP.id}.each do |academic_program|
      next if COURSE_EXCLUDE_LIST.include? academic_program.code
      pagelist = agent.get("http://www.dac.unicamp.br/sistemas/catalogos/grad/catalogo#{year}/cursos/sug#{academic_program.code}.html")
      semesters = pagelist.body.split("Semestre")
      indexSemester = 0
      semesters.each do |semester|
        convert_string(semester).scan(/<a href="..\/ementas\/todas.*">(\w[\w ]\d\d\d)/).each do |course|
          c = find_or_save_course_by_code(course[0], course[0])
          if CourseSuggestion.count(:semester => indexSemester, :catalog_year => year, :course_id => c.id, :academic_program_id => academic_program.id) == 0
            pc = CourseSuggestion.new()
            pc.semester = indexSemester
            pc.catalog_year = year
            pc.course = c
            pc.academic_program = academic_program
            pc.save
          end
        end
        indexSemester = indexSemester + 1
      end
      print "-"
    end
    puts "\n"
  end

  # Searches an acamdemic course and if it does not exist, create it
  def find_or_save_academic_program_by_code(code, name)
    p = AcademicProgram.find_or_initialize_by_code(convert_academic_program_code code)
    if not p.name:
      p.name = "#{code} (Unicamp)"
      p.title = p.name
      p.university = UNICAMP
      p.save!
      for year in 2005..2011 do
        find_or_create_academic_program_class(p, year)
      end
    end
    return p
  end

  # Change 70018 to 070018 to uniform RAs
  def fix_student_code(code)
    "#{"0"*(6-(code.length))}#{code}"
  end

  # Takes the first 2 characters of RA and find out admission year
  def admission_year(code)
    year = code[0,2].to_i
    return 1900+year if year > 20
    return 2000+year
  end

  # If the academic program class does not exist already, create it, otherwise
  # return it
  def find_or_create_academic_program_class(academic_program, year)
    if p = AcademicProgramClass.first(:academic_program_id => academic_program.id, :year => year)
      return p
    end

    p = AcademicProgramClass.new()
    p.academic_program = academic_program
    p.year = year
    p.title = "#{academic_program.name} #{year} (#{academic_program.university.short_name})"
    p.save!
    return p
  end

  # For a course offer, retrieve all students registered for it
  def add_registered_students_offer(a, o, token)
    page = a.get("http://www.daconline.unicamp.br/altmatr/conspub_matriculadospordisciplinaturma.do?org.apache.struts.taglib.html.TOKEN=#{token}&txtDisciplina=#{o.course.code}&txtTurma=#{o.code}&cboSubG=#{o.semester}&cboSubP=#{'0'}&cboAno=#{o.year}&btnAcao=Continuar")
    html_page = convert_string(page.body)
    regex_student = /<td.*>([0-9]{5,7})<\/td>.*\n.*<td[^>]*>[^\w]*(\w.*\w) *<\/td>.*\n.*.*\n.*<td[^>]*>[^\d]*(\d*)<\/td>/
    html_page.scan(regex_student).each do |student|
      # Create or retrieve and update the student information
      s = Student.find_or_initialize_by_code(fix_student_code student[0])
      academic_program = find_or_save_academic_program_by_code(student[2], student[2])
      s.academic_program_class = find_or_create_academic_program_class(academic_program, admission_year(s.code))
      s.name = student[1]
      s.university = UNICAMP
      s.registered_courses << o
      s.save!
      s.academic_program_class.students << s
      s.academic_program_class.save!
      o.students << s
    end
    m = html_page.match(/Docente:<\/span>[^\w]*(\w[^<]*\w)/)
    if m:
      professor = m[1]
    end
  end

  # Retrieve all current course offers and for each one retrieve the students
  # registered for it
  def add_registered_students(course, semester, year)
    a = Mechanize.new
    page = a.get("http://www.daconline.unicamp.br/altmatr/menupublico.do")
    token = page.body.match(/var token = "([0-9a-f]{32,32})";/)[1]
    page = a.get("http://www.daconline.unicamp.br/altmatr/conspub_situacaovagaspordisciplina.do?org.apache.struts.taglib.html.TOKEN=#{token}&txtDisciplina=#{course.code}&txtTurma=V&cboSubG=#{semester}&cboSubP=#{'0'}&cboAno=#{year}&btnAcao=Continuar")
    regex_course_offers = /<td height="18" bgcolor="white" width="100" align="center" class="corpo">([A-Z1-9#])  <\/td>/
    page.body.scan(regex_course_offers).each do |course_offer|
      o = CourseOffer.find_or_initialize_by_title("#{course.code}#{course_offer[0]}-#{semester}s#{year} (#{course.university.short_name})")
      o.course = course
      o.code = course_offer[0]
      o.semester = semester
      o.year = year
      add_registered_students_offer a, o, token
      o.save!
      print '-'
    end
  end

  # Retrieves all courses offered in the current semester
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
    puts "Import Unicamp students' classes"
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
    AcademicProgram.delete_all
    CourseSuggestion.delete_all
    AcademicProgramClass.delete_all
    Student.delete_all
    CourseOffer.delete_all
  end


  task :import_all => [:import_unicamp_academic_programs, :import_unicamp_courses,
   :import_unicamp_academic_programs_catalog, :import_unicamp_students_classes  ] do
  end
end
