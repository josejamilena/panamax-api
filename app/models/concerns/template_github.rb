module TemplateGithub
  extend ActiveSupport::Concern

  module ClassMethods

    def load_templates_from_template_repo(repo)
      repo.files.each do |file|
        next unless file.name.end_with?('.pmx')
        TemplateBuilder.create(file.content)
      end
    end

    def load_templates_from_template_repos
      TemplateRepo.all.each do |repo|
        load_templates_from_template_repo(repo)
      end
    end

  end

  def save_to_repo(params)
    repo            = params[:repo]
    file_name       = params[:file_name] || "#{name}"
    file_path       = params[:file_path] || ''
    commit_message  = params[:commit_message] || "Saved a Panamax template #{file_name}.pmx"
    branch          = params[:branch]
    file_obj        = params[:file]
    opts = {}
    opts[:branch]   = branch if branch
    opts[:file]     = file_obj if file_obj

    file_full_path  = "#{file_path}#{file_name}.pmx"
    # use template contents saved in the database
    contents = TemplateFileSerializer.new(self).to_json

    begin
      github_client.create_contents(repo, file_full_path, commit_message, contents, opts)
    rescue Octokit::UnprocessableEntity
      resp = github_client.contents(repo, path: file_full_path)
      github_client.update_contents(repo, file_full_path, commit_message, resp.sha, contents, opts)
    rescue Octokit::NotFound, Octokit::Unauthorized => ex
      raise "Saving the template file failed: #{ex.message}."
    end

  end

  private

  def github_client
    @github_client ||= Octokit::Client.new(access_token: User.instance.github_access_token)
  end
end