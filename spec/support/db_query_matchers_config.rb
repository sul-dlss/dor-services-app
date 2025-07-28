# frozen_string_literal: true

DBQueryMatchers.configure do |config|
  config.ignores = [/SHOW TABLES LIKE/]
  config.ignore_cached = true
  config.schemaless = true

  # the payload argument is described here:
  # http://edgeguides.rubyonrails.org/active_support_instrumentation.html#sql-active-record
  config.on_query_counted do |payload|
    # do something arbitrary with the query
  end

  config.log_backtrace = true
  config.backtrace_filter = proc do |backtrace|
    backtrace.select { |line| line.start_with?(Rails.root.to_s) }.take(100)
  end
end
