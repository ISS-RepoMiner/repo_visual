require 'sidekiq'
require 'redis'
require 'mongo'
require 'httparty'
require 'repocrawler'

class RepoWorker
  include Sidekiq::Worker
  sidekiq_options :retry => 5 # no retry and then to the Dead Job Queue

  @@client = Mongo::Client.new(ENV['mongodb_uri'], :max_pool_size => 10)

  def perform(step, repo_username, repo_name, gem_name, channel, config)
    @gems = @@client[:gems]
    @github = Repos::GithubData.new(repo_username, repo_name, config['github_token'], config['github_password'], config['github_account'], config['user_agent'])
    @rubygems = Repos::RubyGemsData.new(gem_name)
    @ruby_toolbox = Repos::RubyToolBoxData.new(gem_name, config['user_agent'])
    @stackoverflow = Repos::StackOverflow.new(gem_name, config['stackoverflow_token'])
    send("fetch_and_save_#{step}", repo_username, repo_name, gem_name)

    # publish(channel, step, config['current_authority'])
  end

  def publish(channel, data, current_authority)
    HTTParty.post(current_authority + '/faye', {
        :headers  => { 'Content-Type' => 'application/json' },
        :body    => {
            'channel'   => "/#{channel}",
            'data'      => data
        }.to_json
    })
  end

  def fetch_and_save_basic_information(repo_username, repo_name, gem_name)
    @gems.insert_one({
      'name'          => gem_name,
      'repo_name'     => repo_name,
      'repo_username' => repo_username,
      'created_at'    => DateTime.now
    })
    # @gems
    #   .find('name' => gem_name)
    #   .find_one_and_update("$set" => {
    #     'name'          => gem_name,
    #     'repo_name'     => repo_name,
    #     'repo_username' => repo_username,
    #     'created_at'    => DateTime.now
    #     })
  end

  def fetch_and_save_last_year_commit_activity(repo_username, repo_name, gem_name)
    # begin
    commit_activity_last_year = @github.get_last_year_commit_activity
    if !commit_activity_last_year.nil?
      document = @gems
                  .find('name' => gem_name)
                  .find_one_and_update("$set" => {"commit_activity_last_year" => commit_activity_last_year})
    end
    # rescue => error
    #   puts "commit_activity_last_year error: #{gem_name} #{error}"
    # end
  end

  def fetch_and_save_contributors(repo_username, repo_name, gem_name)
    # begin
    contributors = @github.get_contributors
    if !contributors.nil?
      document = @gems
                  .find('name' => gem_name)
                  .find_one_and_update("$set" => {"contributors" => contributors})
    end
    # rescue => error
    #   puts "contributors error: #{gem_name} #{error}"
    # end
  end

  def fetch_and_save_test(repo_username, repo_name, gem_name)
    # begin
    test = @github.get_test
    if !test.nil?
      document = @gems
                  .find('name' => gem_name)
                  .find_one_and_update("$set" => {"has_test" => test})
    end
    # rescue => error
    #   puts "test error: #{gem_name} #{error}"
    # end
  end

  def fetch_and_save_commit_history(repo_username, repo_name, gem_name)
    # begin
    commit_history = @github.get_commits_history
    if !commit_history.empty?
      document = @gems
                  .find('name' => gem_name)
                  .find_one_and_update("$set" => {"commit_history" => commit_history})
    end
    # rescue => error
    #   puts "commit_history error: #{gem_name} #{error}"
    # end
  end

  def fetch_and_save_commits(repo_username, repo_name, gem_name)
    # begin
    commits = @github.get_total_commits
    if !commits.nil?
      document = @gems
                  .find('name' => gem_name)
                  .find_one_and_update("$set" => {"commits" => commits})
    end
    # rescue => error
    #   puts "commits error: #{gem_name} #{error}"
    # end
  end

  def fetch_and_save_forks(repo_username, repo_name, gem_name)
    # begin
    forks = @github.get_forks
    if !forks.nil?
      document = @gems
                  .find('name' => gem_name)
                  .find_one_and_update("$set" => {"forks" => forks})
    end
    # rescue => error
    #   puts "forks error: #{gem_name} #{error}"
    # end
  end

  def fetch_and_save_stars(repo_username, repo_name, gem_name)
    # begin
    stars = @github.get_stars
    if !stars.nil?
      document = @gems
                  .find('name' => gem_name)
                  .find_one_and_update("$set" => {"stars" => stars})
    end
    # rescue => error
    #   puts "stars error: #{gem_name} #{error}"
    # end
  end

  def fetch_and_save_total_issues(repo_username, repo_name, gem_name)
    # begin
    issues = @github.get_total_issues
    if !issues.nil?
      document = @gems
                  .find('name' => gem_name)
                  .find_one_and_update("$set" => {"total_issues" => issues})
    end
    # rescue => error
    #   puts "total_issues error: #{gem_name} #{error}"
    # end
  end

  def fetch_and_save_issues(repo_username, repo_name, gem_name)
    # begin
    issues = @github.get_issues
    if !issues.nil?
      document = @gems
                  .find('name' => gem_name)
                  .find_one_and_update("$set" => {"issues" => issues})
    end
    # rescue => error
    #   puts "issues error: #{gem_name} #{error}"
    # end
  end

  def fetch_and_save_issues_info(repo_username, repo_name, gem_name)
    # begin
    issues_info = @github.get_issues_info
    if !issues_info.empty?
      document = @gems
                  .find('name' => gem_name)
                  .find_one_and_update("$set" => {"issues_info" => issues_info})
    end
    # rescue => error
    #   puts "issues_info error: #{gem_name} #{error}"
    # end
  end

  def fetch_and_save_last_commit(repo_username, repo_name, gem_name)
    # begin
    last_commit = @github.get_last_commits_days
    if !last_commit.nil?
      document = @gems
                  .find('name' => gem_name)
                  .find_one_and_update("$set" => {"last_commit" => last_commit})
    end
    # rescue => error
    #   puts "last_commit error: #{gem_name} #{error}"
    # end
  end

  def fetch_and_save_readme_word_count(repo_username, repo_name, gem_name)
    begin
      readme_word_count = @github.get_readme_word_count
      if !readme_word_count.nil?
        document = @gems
                    .find('name' => gem_name)
                    .find_one_and_update("$set" => {"readme_word_count" => readme_word_count})
      end
    rescue => error
      puts "readme_word_count error: #{gem_name} #{error}"
    end
  end

  def fetch_and_save_readme_raw_text(repo_username, repo_name, gem_name)
    # begin
    readme_raw_text = @github.get_readme_raw_text
    if !readme_raw_text.nil?
      document = @gems
                  .find('name' => gem_name)
                  .find_one_and_update("$set" => {"readme_raw_text" => readme_raw_text})
    end
    # rescue => error
    #   puts "readme_raw_text error: #{gem_name} #{error}"
    # end
  end

  def fetch_and_save_version_downloads(repo_username, repo_name, gem_name)
    begin
      version_downloads = @rubygems.get_version_downloads
      document = @gems
                  .find('name' => gem_name)
                  .find_one_and_update("$set" => {"version_downloads" => version_downloads})
    rescue => error
      puts "version_downloads error: #{gem_name} #{error}"
    end
  end

  def fetch_and_save_version_downloads_days(repo_username, repo_name, gem_name)
    begin
      version_downloads_days = @rubygems.get_version_downloads_trend
      document = @gems
                  .find('name' => gem_name)
                  .find_one_and_update("$set" => {"version_downloads_days" => version_downloads_days})
    rescue => error
      puts "version_downloads_days error: #{gem_name} #{error}"
    end
  end

  def fetch_and_save_dependencies(repo_username, repo_name, gem_name)
    begin
      dependencies = @rubygems.get_dependencies
      document = @gems
                  .find('name' => gem_name)
                  .find_one_and_update("$set" => {"dependencies" => dependencies})
    rescue => error
      puts "dependencies error: #{gem_name} #{error}"
    end
  end

  def fetch_and_save_total_downloads(repo_username, repo_name, gem_name)
    begin
      total_downloads = @rubygems.get_total_downloads
      document = @gems
                  .find('name' => gem_name)
                  .find_one_and_update("$set" => {"total_downloads" => total_downloads})
    rescue => error
      puts "total_downloads error: #{gem_name} #{error}"
    end
  end

  def fetch_and_save_ranking(repo_username, repo_name, gem_name)
    begin
      ranking = @ruby_toolbox.get_ranking
      document = @gems
                  .find('name' => gem_name)
                  .find_one_and_update("$set" => {"ranking" => ranking})
    rescue => error
      puts "ranking error: #{gem_name} #{error}"
    end
  end

  def fetch_and_save_questions(repo_username, repo_name, gem_name)
    begin
      questions, questions_word_count = @stackoverflow.get_questions
      document = @gems
                  .find('name' => gem_name)
                  .find_one_and_update("$set" => {
                      "questions" => questions,
                      "questions_word_count"  => questions_word_count
                    })
    rescue => error
      puts "questions error: #{gem_name} #{error}"
    end
  end
end