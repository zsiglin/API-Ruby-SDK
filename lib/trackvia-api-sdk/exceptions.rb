module Trackvia
  class ApiError < StandardError
    attr_reader :cause, :errors, :message, :name, :code, :backtrace, :error, :description

    def initialize(cause, errors, message, name, code, backtrace, error, description)
      @cause = cause
      @errors = errors
      @message = message
      @name = name
      @code = code
      @backtrace = backtrace
      @error = error
      @description = description
    end
  end

  class ClientError < StandardError
    attr_reader :message

    def initialize(message)
      @message = message
    end
  end

  class InvalidRefreshToken < ClientError
  end
end
