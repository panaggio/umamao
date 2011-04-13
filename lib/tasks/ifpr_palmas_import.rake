# -*- coding: utf-8 -*-

namespace :ifpr_palmas do
    desc "Create IFPR palmas courses from csv"
    task :create_courses_from_csv => :environment do

    # Working specifically with university IFPR.
    UNI_NAME = "IFPR"
    U_CAMPUS = "IFPR Palmas"
    UNIVERSITY = University.find_by_short_name(UNI_NAME)
    if UNIVERSITY.nil?
      print "Could not process courses: university '#{U_CAMPUS}' not found."
      return
    end

    course_count = ok_course_count = 0
    filename = "data/ifpr_ementario_si_matriz_2009.csv"
    if File.exists?(filename)
      File.open(filename, "r") do |file|
        header = file.gets.split("|").map(&:strip).map(&:downcase)
        file.each do |line|
          content = line.split("|").map(&:strip)

          # hash will contain, among other keys, "disciplina" and "ementa"
          hash = Hash[*header.zip(content).flatten]

          name = hash['disciplina']
          summary = hash['ementa']

          t = Topic.find_by_title("#{name} (#{U_CAMPUS})")
          next if t && t.type == Course && t.name

          print "Processing course '#{name}'...\n"

          if t.nil?
            t = Course.new
            t.title = "#{name} (#{U_CAMPUS})"
          elsif t.type == Topic
            Topic.set(t.id, :_type => "Course")
            t = Course.find_by_id(t.id)
          end

          t.name = name
          t.university = UNIVERSITY
          t.summary = summary
          t.description = "#{summary}\n\n" +
            " - **Carga horária teórica**: #{hash['ch teo.']}\n" +
            " - **Carga horária prática**: #{hash['ch prat.']}\n" +
            " - **Carga horária total**: #{hash['ch total']}\n" +
            " - **Créditos**: #{hash['créd.']}\n"
          status = t.save!

          ok_course_count += 1 if status
          course_count += 1
        end
      end

      if course_count > 0
        print "Successfully processed #{ok_course_count}/"
        print "#{course_count} of #{UNI_NAME} courses.\n"
      else
        print "No course needed to be created for #{UNI_NAME}.\n"
      end
    else
      print "Could not process #{UNI_NAME} courses: "
      print "file '#{filename}' not found.\n"
    end

    print "\n"
  end
end
