namespace :stats do

  UMAMAO = ["4d2e491079de4f37ab0004cb", "4c8906d179de4f1a20000005",
            "4cd88e1679de4f67cf00006b", "4c8906d379de4f1a200000c1",
            "4c8906d279de4f1a20000055", "4c8906d179de4f1a20000009",
            "4c8906d279de4f1a2000007d", "4c8911ef79de4f1c8d0000c6",
            "4cf3b57579de4f2183002806"]

  FREELANCERS = ["4c8906d279de4f1a2000009d", "4d42108c79de4f2451000179",
                 "4c8906d479de4f1a200001cd", "4ca3d06379de4f09de00004e",
                 "4ced019179de4f41170002f1", "4cf65ce079de4f47f500029a",
                 "4d41cfed79de4f1289000178", "4d420e1a79de4f24510000b9",
                 "4d42a89279de4f2376000f16", "4d42af2a79de4f262d0007be",
                 "4d42b54779de4f23760012fe", "4d445e9679de4f2376003b5b",
                 "4ce5608879de4f0e06000864", "4ce6c0d679de4f0e0600149c",
                 "4cead40679de4f297000088d", "4cebbfea79de4f1d44000036",
                 "4d5b144688a89517bb0005df", "4d1cb30679de4f0cdf000037",
                 "4d4183ec79de4f7d1b00001f", "4d430fa579de4f245100106a",
                 "4d45c15e4a882563e3000d89", "4d5088b20f06bd6dd300002c"]

  TOP_USERS = ["4c8906d179de4f1a20000021"]

  IGNORE = UMAMAO + FREELANCERS + TOP_USERS

  task :all => :environment do

    stats = {}
    block = Proc.new do |entry|
      next if !(t = entry.created_at)
      k = [t.year, t.month]
      stats[k] ||= {
        :users => User.count(:created_at.lt => Time.utc(t.year, t.month),
                             :id.nin => IGNORE),
        :activity => Hash.new(0)
      }
      stats[k][:activity][entry.user_id] += 1
    end

    Question.find_each(:user_id.nin => IGNORE, &block)
    Comment.find_each(:user_id.nin => IGNORE, &block)

    stats.sort.each do |t, stat|
      total_entries = stat[:activity].inject(0){ |acc, s| acc + s[1] }
      active_users = stat[:activity].size
      average = total_entries.to_f / active_users
      standard_deviation =
        Math.sqrt(stat[:activity].inject(0){ |acc, s| acc + (s[1] - average) ** 2 } / active_users)

      puts "#{t[1]}/#{t[0]}"
      puts "  Total entries: #{total_entries}"
      puts "  Active users: #{active_users} in #{stat[:users]} (#{active_users.to_f / stat[:users]})"
      puts "  Average activity: #{average} entries / active user"
      puts "    Standard deviation: #{standard_deviation}"
    end

  end

end
