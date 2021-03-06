module Shipr
  class Job
    include Mongoid::Document
    include Grape::Entity::DSL
    store_in collection: 'jobs'

    field :repo, type: String
    field :branch, type: String, default: 'master'
    field :config, type: Hash, default: { 'ENVIRONMENT' => 'production' }
    field :output, type: String, default: ''
    field :exit_status, type: Integer
    field :script, type: String
    field :notify, type: Array, default: []

    def id
      _id.to_s
    end

    # ===========
    # = Methods =
    # ===========
    
    # Public: Mark the job is complete, with the exit status of the process.
    #
    # exit_status - Integer exit status of the deploy command.
    #
    # Examples
    #
    #   job.complete!(0)
    #   # => true
    def complete!(exit_status)
      JobCompleter.complete(self, exit_status)
    end

    # Public: Append lines of output from the process.
    #
    # output - String of text to append. Can 
    #
    # Examples
    #
    #   job.append_output!("hello world")!
    #   # => true
    def append_output!(output)
      JobOutputAppender.append(self, output)
    end

    # Public: Wether the job has completed or not.
    #
    # Examples
    #
    #   job.done?
    #   # => true
    def done?
      exit_status.present?
    end

    # Public: Wether the job is successful or not. In other words, whether or not
    # the exit status is 0.
    #
    # Examples
    #
    #   job.success?
    #   # => false
    def success?
      exit_status == 0
    end

    def script
      super || Shipr.default_script
    end

    # Public: Restart this job.
    #
    # Returns new Job.
    def restart!
      JobRestarter.restart(self)
    end

    # Public: Channel where pusher messages should be sent.
    # 
    # Returns String.
    def channel
      "private-job-#{id}"
    end

    entity :id, :repo, :branch, :user, :config, :exit_status do
      expose :done?, as: :done
      expose :success?, as: :success
      expose :output, if: :include_output
    end
  end
end
