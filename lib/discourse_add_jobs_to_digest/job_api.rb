# frozen_string_literal: true

module ::DiscourseAddJobsToDigest
  # https://api.gethoteljobs.com/site/v1/search?page_size=5&page_token&query=manager&URL_ENCODED_LOCATION_FROM_USER_PROFILE&radius=100mi
  # https://api.gethoteljobs.com/site/v1/search/search?page_size=5&query=manager&location=Nashville%2C+TN&radius=100mi

  class JobApi
    include ApplicationHelper # Includes helpers like `short_date`

    attr_accessor :title, :description, :created_at, :location, :url

    def initialize(title:, description:, created_at:, location:, url:)
      @title = title
      @description = description
      @created_at = created_at
      @location = location
      @url = url
    end

    def self.get_jobs(user = @user)
      jobs = []
      location = user.user_profile.location
      # get city and state from the location expecting "city, state"
      city, state = location.nil? ? [nil, nil] : location.split(",")
      return nil if city.nil? || state.nil?
      city = city.strip
      state = state.strip
      url =
        "#{SiteSetting.job_api_url}?#{SiteSetting.job_utm_parameters}&#{SiteSetting.job_search_term}&city=#{CGI.escape(city)}&state=#{CGI.escape(state)}"
      Rails.logger.warn("Job query for user #{user.username}: #{url}") if SiteSetting.job_api_debug
      headers = { "accept-language" => "en-US,en;q=0.9" }
      result = Excon.get(url, headers: headers)
      # puts "doing the response: #{result.inspect}"
      parsed = JSON.parse(result.body)
      if parsed["jobs"].nil?
        Rails.logger.warn("No jobs found for user #{user.username} with location #{location}")
        return nil
      else
        parsed["jobs"].each do |job_record|
          job = job_record["listing"]
          loc = job_record["jobLocation"][0]["postalAddress"]
          jobs << JobApi.new(
            title: job["title"],
            description: job["description"],
            created_at: Time.parse(job["createdAt"]),
            location: "#{loc["addressLocality"]}, #{loc["addressRegion"]}",
            url: job["url"],
          )
        end
      end
      # puts "got the jobs: #{jobs.inspect}"
      jobs.length > 0 ? jobs : nil
    end

    def rtl?
      false
    end

    def self.get_jobs_html(user = @user)
      # puts "doing the get_jobs_html --- with @user"
      @jobs = get_jobs(user)
      # puts "got the jobs to render #{ @jobs.inspect }"
      template_file =
        "plugins/discourse-add-jobs-to-digest/lib/discourse_add_jobs_to_digest/templates/jobs2.html.erb"

      begin
        template_path = Rails.root.join(template_file)
        # puts "got template"
        template = File.read(template_path)
        # puts "got template file"
        erb = ERB.new(template)
        # puts "did the ERB"
        erb.result_with_hash(
          jobs: @jobs,
          rtl: false,
          job_site_url: SiteSetting.job_site_url,
          job_site_name: SiteSetting.job_site_name,
        )
      rescue => e
        puts "Error occurred while generating HTML: #{e.message}"
        Rails.logger.error("Error occurred while generating HTML: #{e.message}")
      end
    end
  end
end
