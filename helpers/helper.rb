require 'httparty'

module VizHelper

  def question_word_count(data)
    question_title_word_count = []
    question_title_word_count_scaled = []

    data.each do |row|
      if row[1].to_i > 1
        question_title_word_count << { "text" => row[0], "size" =>row[1]}
      end
    end

    #scaling for question word cloud
    return [] if question_title_word_count.empty?
    question_title_word_count = question_title_word_count.reverse
    
    newMax = 10.0
    newMin = 1.0
    firstword = question_title_word_count.first
    lastword = question_title_word_count.last

    oldRange = question_title_word_count.last['size'].to_i - question_title_word_count.first['size'].to_i
    newRange = newMax - newMin

    question_title_word_count_scaled <<  {"text"=>firstword['text'], "size"=>1}
    question_title_word_count.slice(1..-2).each do |word|
      newValue = (((word['size'].to_i - question_title_word_count.first['size'].to_i) * newRange)/oldRange) + newMin
      question_title_word_count_scaled << {"text"=>word['text'],"size"=> newValue}
    end
    question_title_word_count_scaled << {"text"=>lastword['text'], "size"=>10}
    
    question_title_word_count_scaled
  end

  def readme_word_count(data)
    readme_word_count = []
    readme_word_count_scaled = []
    data.each do |row|
      if row[1].to_i > 1
        readme_word_count << {"text" => row[0], "size" => row[1]}
      end
    end

    #scaling for word cloud
    return [] if readme_word_count.empty?
    readme_word_count = readme_word_count.reverse
    
    newMax = 10.0
    newMin = 1.0
    firstword = readme_word_count.first
    lastword = readme_word_count.last

    oldRange = readme_word_count.last['size'].to_i - readme_word_count.first['size'].to_i
    newRange = newMax - newMin

    readme_word_count_scaled <<  {"text"=>firstword['text'], "size"=>1}
    readme_word_count.slice(1..-2).each do |word|
      newValue = (((word['size'].to_i - readme_word_count.first['size'].to_i) * newRange)/oldRange) + newMin
      readme_word_count_scaled << {"text"=>word['text'],"size"=> newValue}
    end
    readme_word_count_scaled << {"text"=>lastword['text'], "size"=>10}

    readme_word_count_scaled
  end

  def question_views(data)
    questions_hash = {}
    data.reverse.each do |row|
      questions_hash[Time.at(row['creation_date'].to_i).strftime("%m-%d-%Y")] = row['views']
    end

    questions_hash
  end

  def version_downloads(data)
    version_downloads_hash = {}
    data.each do |row|
      version_downloads_hash[row['number']] = row['downloads']
    end

    version_downloads_hash
  end

  def version_downloads_stack(data)
    general_data = []
    data.each do |row|
      if general_data[row['number'].split('.').first.to_i].nil?
        general_data[row['number'].split('.').first.to_i] = 0
      end
      general_data[row['number'].split('.').first.to_i] += row['downloads']
    end

    final_general = general_data.each_with_index.map do |row, index|
      {
        'name'    => "Version #{index}.*",
        'y'       => row,
        'drilldown' => "Version #{index}.*"
      }
    end

    specific_data = []
    data.each do |row|
      if specific_data[row['number'].split('.').first.to_i].nil?
        specific_data[row['number'].split('.').first.to_i] = []
      end
      specific_data[row['number'].split('.').first.to_i] << [row['number'], row['downloads']]
    end

    final_specific = specific_data.each_with_index.map do |row, index|
      {
        'name'  => "Version #{index}.*",
        'id'    => "Version #{index}.*",
        'data'  => row
      }
    end

    [final_general, final_specific]
  end

  def version_downloads_nest(data)
    major_data = []
    data.each do |row|
      if major_data[row['number'].split('.').first.to_i].nil?
        major_data[row['number'].split('.').first.to_i] = 0
      end
      major_data[row['number'].split('.').first.to_i] += row['downloads']
    end

    major = major_data.each_with_index.map do |row, index|
      {
        'name'    => "Version #{index}.*",
        'y'       => row,
        'drilldown' => "Version #{index}.*"
      }
    end

    minor_data = []
    data.each do |row|
      if minor_data[row['number'].split('.').first.to_i].nil?
        minor_data[row['number'].split('.').first.to_i] = []
      end
      minor_data[row['number'].split('.').first.to_i] << [row['number'], row['downloads']]
    end

    minor_hash = Hash.new(0)
    minor_data.each do |row|
      row.each do |version|
        maj, min, pat = version[0].split('.')
        if minor_hash["Version #{maj}.#{min}.*"].nil?
          minor_hash["Version #{maj}.#{min}.*"] = 0
        end
        minor_hash["Version #{maj}.#{min}.*"] += version[1]
      end
    end

    m_data = {}
    minor_hash.each do |index, value|
      major_ver = index.match(/[0-9]/)
      minor_ver = index.match(/[0-9].[0-9]/)
      
      if m_data[major_ver.to_s].nil?
        m_data[major_ver.to_s] = []
      end

      m_data[major_ver.to_s] << {
        'name'    => index,
        'y'       => value,
        'drilldown' => "Version #{minor_ver}.*"
      }
    end

    minor = m_data.map do |index, value|
      major_ver = value[0]['name'].match(/[0-9]/)

      {
        'id'      => "Version #{major_ver}.*",
        'name'    => "Version #{major_ver}.*",
        'data'    => value
      }
    end

    path_hash = {}
    data.each do |row|
      maj, min, pat = row['number'].split('.')
      if path_hash["Version #{maj}.#{min}.*"].nil?
        path_hash["Version #{maj}.#{min}.*"] = []
      end
      path_hash["Version #{maj}.#{min}.*"] << [row['number'], row['downloads']]
    end

    path = path_hash.map do |row|
      {
        'id'    => row[0],
        'data'  => row[1]
      }
    end

    nest_drilldown = [minor, path].flatten

    [major, nest_drilldown]
  end

  def commit_week_day(data)
    return {} if data.empty?

    commit_week_day = {
      'Monday'    => 0,
      'Tuesday'   => 0,
      'Wednesday' => 0,
      'Thursday'  => 0,
      'Friday'    => 0,
      'Saturday'  => 0,
      'Sunday'    => 0
    }
    data.each do |row|
      wday = DateTime.parse(row['created_at']).to_date.wday

      case wday
        when 0
          commit_week_day['Sunday'] += 1
        when 1
          commit_week_day['Monday'] += 1
        when 2
          commit_week_day['Tuesday'] += 1
        when 3
          commit_week_day['Wednesday'] += 1
        when 4
          commit_week_day['Thursday'] += 1
        when 5
          commit_week_day['Friday'] += 1
        when 6
          commit_week_day['Saturday'] += 1
      end
    end

    commit_week_day
  end

  def version_downloads_days(data)
    version_downloads_days = []
    data.each do |row|
      process = row['downloads_date'].map do |data|
        date = data[0].split('-')
        [Date.new(date[0].to_i, date[1].to_i, date[2].to_i).to_time.to_i * 1000, data[1]]
      end
      version_downloads_days << {'name' => row['number'], 'data' => process}
    end

    version_downloads_days
  end

  def version_downloads_days_aggregate(data)
    version_downloads_days_aggregate = {}
    data.each do |row|
      major, minor, patch = row['number'].split('.')
      version_downloads_days_aggregate["#{major}.#{minor}"] = Hash.new(0)
    end

    data.each do |row|
      major, minor, patch = row['number'].split('.')
      row['downloads_date'].each_pair do |date, downloads|
        date = date.split('-')
        version_downloads_days_aggregate["#{major}.#{minor}"][Date.new(date[0].to_i, date[1].to_i, date[2].to_i).to_time.to_i * 1000] += downloads
      end
    end

    result = []
    version_downloads_days_aggregate.each_pair do |key, value|
      result << {
        'name'    => key,
        'data'   => value.to_a
      }
    end

    result
  end

  def commit_heatmap(data)
    # p data
    # cwday
    # month

    return {} if data.empty?

    min_date = Date.strptime(data.first['week'].to_s, '%s').to_s
    max_date = Date.strptime((data.last['week'] + 86400 * 6).to_s, '%s').to_s


    commits_transform = {
      'data'  => [],
      'max'   => 0,
      'min_date' => min_date,
      'max_date' => max_date
    }

    date_index = 0
    data.each do |row|
      stamp = row['week']
      counter = 0
      row['days'].each_with_index do |value, index|
        commits_transform['max'] = value if value > commits_transform['max']

        date = Date.strptime((row['week'] + 86400 * counter).to_s,'%s')
        
        commits_transform['data'] << [date.month - 1, date.cwday % 7, value]
        counter += 1
        date_index += 1
      end
    end

    commits_aggregate = Hash.new(0)
    commits_transform['data'].each do |row|
      commits_aggregate["#{row[0]}-#{row[1]}"] += row[2]
    end

    commits_transform['data'] = commits_aggregate.map do |row|
      month, day = row[0].split('-')
      [month.to_i, day.to_i, row[1]]
    end

    commits_transform
  end

  def commits_trend(data)
    return {} if data.empty?
    commits_days = Hash.new(0)

    data.each do |row|
      timestamp = DateTime.parse(row['created_at']).to_date.to_time.to_i
      commits_days[timestamp * 1000] += 1
    end

    commits_days.to_a
  end

  def issues_info(data)
    data.map! do |row|
      [row['number'], row['duration']]
    end

    data
  end

  def issues_aggregate(data)
    issues_month_duration = Hash.new()
    data.each do |row|
      datetime = DateTime.iso8601(row['created_at'])
      year = datetime.year
      month = datetime.month
      if issues_month_duration["#{year}-#{month}"].nil?
        issues_month_duration["#{year}-#{month}"] = []
      end
      issues_month_duration["#{year}-#{month}"] << row['duration']
    end

    issues_month_duration

    result = {
      'data' => [],
      'months' => []
    }
    issues_month_duration.each_pair do |month, values|
      if values.empty?
        lowest, q1, q2, q3, highest = 0, 0, 0, 0, 0
      else
        sorted_values = values.sort
        lowest = sorted_values.first
        q1_position = (values.size + 1) / 4.to_f
        q1_decimal, q1_remainder = q1_position.to_i, q1_position % 1 
        q1 = q1_remainder * sorted_values[q1_decimal] + (1 - q1_remainder) * sorted_values[q1_decimal - 1]
        
        q2_position = (values.size + 1) / 2.to_f
        if q2_position % 1 === 0
          q2 = sorted_values[q2_position - 1]
        else
          q2_decimal, q2_remainder = q2_position.to_i, q2_position % 1
          q2 = q2_remainder * sorted_values[q2_decimal] + (1 - q2_remainder) * sorted_values[q2_decimal - 1]
        end

        q3_position = 3 * q1_position
        q3_decimal, q3_remainder = q3_position.to_i, q3_position % 1
        if q3_decimal === values.size
          q3 = sorted_values.last
        else
          q3 = q3_remainder * sorted_values[q3_decimal] + (1 - q3_remainder) * sorted_values[q3_decimal - 1]
        end
        highest = sorted_values.last
      end

      result['months'] << month
      result['data'] << [lowest, q1, q2, q3, highest]
    end

    result
  end

  def get_github_repo_info(gem_info)
    repo_user = ''
    repo_name = ''
    seperate_success = false
    if (!gem_info['homepage_uri'].nil? && !seperate_success)
      if (gem_info['homepage_uri'].include?('https://github.com') || gem_info['homepage_uri'].include?('http://github.com'))
        text_ary = gem_info['homepage_uri'].split('/')
        github_index = text_ary.index('github.com')
        repo_user = text_ary[github_index + 1].nil? ? '' : text_ary[github_index + 1]
        repo_name = text_ary[github_index + 2].nil? ? '' : text_ary[github_index + 2]
        seperate_success = true if (!repo_user.empty? && !repo_user.nil? && !repo_name.empty? && !repo_name.nil?)
      end
    end
    if (!gem_info['source_code_uri'].nil? && !seperate_success)
      if (gem_info['source_code_uri'].include?('https://github.com') || gem_info['source_code_uri'].include?('http://github.com'))
        text_ary = gem_info['source_code_uri'].split('/')
        github_index = text_ary.index('github.com')
        repo_user = text_ary[github_index + 1].nil? ? '' : text_ary[github_index + 1]
        repo_name = text_ary[github_index + 2].nil? ? '' : text_ary[github_index + 2]
        seperate_success = true if (!repo_user.empty? && !repo_user.nil? && !repo_name.empty? && !repo_name.nil?) 
      end
    end
    if (!gem_info['project_uri'].nil? && !seperate_success)
      if (gem_info['project_uri'].include?('https://github.com') || gem_info['project_uri'].include?('http://github.com'))
        text_ary = gem_info['project_uri'].split('/')
        github_index = text_ary.index('github.com')
        repo_user = text_ary[github_index + 1].nil? ? '' : text_ary[github_index + 1]
        repo_name = text_ary[github_index + 2].nil? ? '' : text_ary[github_index + 2]
        seperate_success = true if (!repo_user.empty? && !repo_user.nil? && !repo_name.empty? && !repo_name.nil?)
      end
    end
    if (!gem_info['gem_uri'].nil? && !seperate_success)
      if (gem_info['gem_uri'].include?('https://github.com') || gem_info['gem_uri'].include?('http://github.com'))
        text_ary = gem_info['gem_uri'].split('/')
        github_index = text_ary.index('github.com')
        repo_user = text_ary[github_index + 1].nil? ? '' : text_ary[github_index + 1]
        repo_name = text_ary[github_index + 2].nil? ? '' : text_ary[github_index + 2]
        seperate_success = true if (!repo_user.empty? && !repo_user.nil? && !repo_name.empty? && !repo_name.nil?)
      end
    end

    [repo_user, repo_name]
  end

  def rate_limit_res(access_token)
    rate_limit = HTTParty.get("https://api.github.com/rate_limit?access_token=#{access_token}")
    rate_limit
  end

  def sk_perform(rate_limit_res, task, repo_username, repo_name, gem_info, channel, config)
    if rate_limit_res['rate']['remaining'] <= 200
      RepoWorker.perform_at(rate_limit_res['rate']['reset'], task, repo_username, repo_name, gem_info, channel, config)
    else
      RepoWorker.perform_async(task, repo_username, repo_name, gem_info, channel, config)
    end
  end
end