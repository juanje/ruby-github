require 'rubygems'
require 'json'
require 'open-uri'
require 'mash'

module GitHub
  class API
    BASE_URL = "http://github.com/api/v2/json"
  
    # Fetches information about the specified user name.
    def self.user(user)
      url = BASE_URL + "/user/show/#{user}"
      GitHub::User.new(JSON.parse(open(url).read)["user"])
    end

    # Fetches the repositories for a given user.
    def self.repositories(user)
      url = BASE_URL + "/repos/show/#{user}"
      JSON.parse(open(url).read)["repositories"].collect{ |r|
        GitHub::Repository.new(r.merge(:user => user))
      }
    end
  
    # Fetches the commits for a given repository.
    def self.commits(user,repository,branch="master")
      url = BASE_URL + "/commits/list/#{user}/#{repository}/#{branch}"
      JSON.parse(open(url).read)["commits"].collect{ |c| 
        GitHub::Commit.new(c.merge(:user => user, :repository => repository))
      }
    end
    
    def self.repository(user,repository)
      GitHub::API.user(user).repositories.select{|r| r.name == repository}.first
    end
  
    # Fetches a single commit for a repository.
    def self.commit(user,repository,commit)
      url = BASE_URL + "/commits/show/#{user}/#{repository}/#{commit}"
      commit = JSON.parse(open(url).read)["commit"]
      GitHub::Commit.new(commit.merge(:user => user, :repository => repository))
    end
  end
  
  class Repository < Mash
    def commits
      ::GitHub::API.commits(user,name)
    end
  end
  
  class User < Mash
    def initialize(hash = nil)
      @user = hash["login"] if hash
      super
    end
    
    def repositories=(repo_array)
      self["repositories"] = repo_array.collect{|r| ::GitHub::Repository.new(r.merge(:user => login || @user))}
    end
  end
  
  class Commit < Mash
    # if a method only available to a detailed commit is called,
    # automatically fetch it from the API
    def detailed
      ::GitHub::API.commit(user,repository,id)
    end
  end
end